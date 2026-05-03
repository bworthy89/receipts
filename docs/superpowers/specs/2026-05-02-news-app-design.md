# THE CRIME BOARD — Technical Implementation Spec

**Status:** Draft, pending approval
**Date:** 2026-05-02
**Owner:** bworthy89@gmail.com

This is the **technical / architecture** spec for THE CRIME BOARD — a news-as-investigation iOS (SwiftUI) app for news-skeptical adults.

---

## Canonical context (read first)

This spec is technical. It defers to the project-root files for everything *product* and *visual*:

- **`/AGENTS.md`** — TL;DR launchpad for AI agents. Pointers to PRODUCT.md and DESIGN.md.
- **`/PRODUCT.md`** — strategic spec: register, target users, product purpose, brand personality, anti-references, design principles, accessibility posture. *Authoritative for who / what / why.*
- **`/DESIGN.md`** — visual design system (currently in seed mode): palette, typography, elevation, components, do's and don'ts. *Authoritative for how it looks.*
- **`/design idea.md.rtf`** — the original creative seed; preserved for context.

If anything in this spec contradicts those files, those files win. The job of *this* document is to describe how the engineering work is shaped — modules, services, data, flows — within the constraints those files define.

---

## What this spec covers

- Platform & tech stack (iOS, Cloudflare, on-device AI)
- Architecture (hybrid: device for personal/private work, server for shared work)
- Data model (Cloudflare D1 schema)
- iOS app architecture (modules, MV pattern, key abstractions)
- Screen inventory mapped to CRIME BOARD vocabulary
- Three flagship user flows
- Cross-cutting concerns (testing, errors, accessibility, App Store review, observability, privacy)
- Out-of-scope and open items

It does **not** cover: the cork-board / paper / ink / red-string / polaroid / stamp visual language (see DESIGN.md), the wry-procedural voice (see PRODUCT.md), or the strategic anti-references (see PRODUCT.md).

---

## Mission (one line)

Help news-skeptical adults verify what they're reading without becoming full-time fact-checkers — by *showing the work* of source-checking and connection-mapping in front of them, on a cork board. (Full strategic context: PRODUCT.md.)

---

## Three core surfaces

Final user-facing names will be set via the impeccable workflow as DESIGN.md exits seed mode. Working names below; the engineering shapes are stable.

1. **The Board (today's pinned cases)** — a feed where each item is a *case*: a real-world event covered by multiple outlets, pinned to the cork board with a BiasMeter dossier and source pins. (Replaces what generic news-app vocabulary would call "the feed".)

2. **The Open Case File (a story)** — opens one case into its evidence: source pins arranged on the board, red-string connections between corroborating / contradicting reporting, polaroid-style photo evidence where available, and a verdict stamp slot for fact-checks. (Replaces "story detail".)

3. **Deep Check (the hero feature)** — the user submits a claim or article and watches the app *interrogate sources* in real time: pin-drops, red-string draws, polaroid develops, stamp slams. The animation IS the trust mechanic; the user sees the work happen. (Replaces "fact-check tool".)

## Two operating modes (set in onboarding, switchable any time)

- **Strict mode** — the user picks beats (topics) + persons of interest (outlets); the board shows what they asked for, with bias dossiers layered on top.
- **Balanced mode** — the user picks beats; the app intentionally pins cases from across the spectrum and shows a weekly *case-clearance* view. (No XP, no badges — see PRODUCT.md hard prohibitions.)

## Monetization

Free + **Senior Detective** subscription ($4.99/mo or $39.99/yr). No ads anywhere.

Senior Detective unlocks: unlimited Deep Check, custom beat alerts, cross-case linking, archive search older than 30 days, raw-source export, and the Apple Watch app.

(Pro tier label per PRODUCT.md: "SENIOR DETECTIVE" with a stamp glyph; never a gold crown / premium-badge cliché.)

---

## Platform & tech stack

- **Platform:** iOS-native, iPhone + iPad (NavigationSplitView), Apple Watch (Senior Detective). **iOS 26.0 minimum** to enable Apple Foundation Models framework.
- **Language/UI:** Swift 6.2 (strict concurrency on), SwiftUI, MV pattern with `@Observable`.
- **Visual system:** see DESIGN.md. Core mechanics this spec assumes: cork-board substrate, paper-on-cork elevation, choreographed pin/string/polaroid/stamp motion (the trust mechanic, not polish), first-class Reduce Motion path.
- **On-device AI:** Apple Foundation Models framework (free, private, fast, no network).
- **Backend:** Cloudflare-only — Workers, D1, KV, R2, Queues, Workers AI.
- **Sync:** CloudKit private DB for personal data (pinned cases, closed cases / archive, prefs, days-on-the-beat history).
- **Auth:** Sign in with Apple primary; email signup fallback; anonymous mode supported (no sync).
- **External APIs:** ~200 RSS feeds (free), Google Fact Check Tools API (free), public bias datasets (AllSides + Ad Fontes), APNs (free), Brave Search ($5/mo, optional fallback for Deep Check).

**Estimated server cost:** $0/mo at launch · ~$5/mo at 10k MAU · ~$25–75/mo at 100k MAU · ~$100–300/mo at 1M MAU.

---

## Architecture

### Hybrid execution model

Work is split between device and server based on what is *shared* vs what is *personal*:

**On the server (shared work, runs once for all users):**
- RSS ingestion every 5 minutes
- Article clustering via Workers AI embeddings (creates *cases*)
- Bias-rating enrichment (joining articles to outlet bias scores → BiasMeter dossier source data)
- Push notification triggers for breaking cases ("new pin on the wire")
- Deep Check (web search + LLM with citations — too heavy for on-device)
- Auth, sync state, subscription status

**On the device (personal work, never leaves the phone):**
- Per-article AI summary (the "what this source is saying" line on each pin)
- *Is this true?* first-pass analysis (pre-Deep-Check verdict)
- Case-clearance / days-on-the-beat analytics
- Personalized "would this expand your beat?" scoring in Balanced mode
- Smart notification filtering ("don't wake me unless this is huge")

**Why iOS 26+ minimum:** the on-device AI story is core (privacy + cost + speed). Foundation Models is iOS 26+ only. Rather than maintain a parallel server-AI path for older devices, the app requires iOS 26 — accepting a smaller addressable market for a focused, simpler codebase. The only AI work that runs on the server is Deep Check (which is server-side regardless of iOS version, because it needs web search).

### Server architecture (Cloudflare)

| Component | Role | Free tier |
|---|---|---|
| **Workers** | Compute, cron, request handling, JWT verification | 100k req/day |
| **D1** | SQL database (articles, cases, outlets, bias data, users) | 5 GB, 5M reads/day |
| **KV** | Edge cache for hot board / case payloads | 100k reads/day |
| **R2** | Object storage (closed-case archive — Senior Detective feature) | 10 GB, no egress fees |
| **Queues** | Background jobs (RSS fan-out, embedding batches, push fan-out) | 1M ops/mo |
| **Workers AI** | Embeddings (`bge-small-en-v1.5`) + Llama 3.1 8B for Deep Check fallback | ~10k neurons/day |

**Six Workers, each with one job:**

1. **`ingest-worker`** (cron, every 5 min) — reads RSS feed list from D1, fans out to Queue, queue consumer fetches XML, parses, dedupes by URL, inserts new articles into D1.

2. **`case-builder-worker`** (cron, every 5 min, after ingest) — pulls unclustered articles from last 48h, gets embeddings via Workers AI, compares against existing case `centroid_embedding`s (cosine similarity threshold 0.78). On match: assign article to case, update centroid, recompute `bias_distribution`, set `is_breaking` on rapid growth. On no match: create a new case with this article as seed centroid. Article-level embeddings are nulled out post-assignment to save space; case centroid persists. (Internally these are "clusters" in the data model; user-facing they are *cases on the board*.)

3. **`api-worker`** (request-driven) — the single REST API the iOS app talks to. ~12 endpoints. Aggressive KV caching on read-heavy endpoints (~60s TTL).

4. **`deep-check-worker`** (Queue consumer, async) — runs Deep Check end-to-end: extract claims, search corroborating sources, synthesize verdict, store result, push notification when done. Streams progress states (`searching` / `N sources reviewed` / `synthesizing`) back to the iOS app via Live Activity for the pin-drop / string-draw choreography.

5. **`push-worker`** (cron, every 1 min) — scans cases with `is_breaking=true` from last 60s, matches against subscribed users, sends APNs push (rate-limited: max 3 breaking pushes per user per day).

6. **`factcheck-sync-worker`** (cron, hourly) — pulls recent fact-checks from Google Fact Check Tools API, inserts with embeddings.

**Auth:** Sign in with Apple flow — iOS calls `ASAuthorizationAppleIDProvider`, sends identity JWT to `POST /auth/apple`, Worker verifies signature against Apple's JWKS, mints HMAC-signed session token (30-day expiry), iOS stores in Keychain.

**Bias data refresh:** ops script (not a Worker), run monthly, pulls AllSides community CSV + Ad Fontes public chart data, diffs against `outlets` table, applies updates, logs changes for review.

### iOS app architecture

**Module structure** (Swift Package Manager local packages — keeps build times sane and forces clean boundaries):

```
CrimeBoard/                # App target (entry, intents, share extension)
Packages/
  ├── DesignSystem/        # Implementation of DESIGN.md tokens + components
  │                        # (Pin, Polaroid, Stamp, RedString, EvidenceCard, Dossier, etc.)
  ├── Models/              # Codable structs (Article, Case, Outlet, FactCheck, User)
  ├── APIClient/           # Cloudflare API client (async/await, typed endpoints)
  ├── OnDeviceAI/          # Foundation Models wrapper. No network access, type-enforced.
  ├── PersistenceKit/      # CloudKit sync + local cache
  ├── Choreography/        # Pin-drop / string-draw / polaroid-develop / stamp-slam motion primitives
  │                        # plus the Reduce Motion equivalents (see DESIGN.md).
  ├── BoardFeature/        # The Board (today's pinned cases)
  ├── CaseFileFeature/     # Open Case File (story detail), source dossiers
  ├── DeepCheckFeature/    # Deep Check tool, Live Activity, verdict choreography
  ├── OnboardingFeature/   # Day-one-on-the-beat first-run flow
  ├── SettingsFeature/     # Account, prefs, subscription, accessibility
  ├── SeniorDetectiveFeature/  # Paywall, StoreKit 2, entitlement
  └── WidgetKit/           # Widgets, Live Activities, control widgets
```

**Pattern:** MV (modern SwiftUI) — `@Observable` stores per feature, SwiftUI views read state directly via `@Bindable`/`@Environment`, dependencies injected via protocols. No ViewModels-per-View.

**Concurrency:** Swift 6.2 strict concurrency enabled. All API/AI calls async. Stores own `Task` lifecycle. Background work uses `App Intents` + `BGAppRefreshTask`.

**Key abstractions:**

- **`OnDeviceAI`** — async API hiding Foundation Models. Methods: `summarizeSource(article:)`, `firstPassVerdict(claim:)`, `analyzeBeatBalance(history:)`, `explainPlainEnglish(article:)`. Type system enforces no network access — these calls cannot leak data off-device.
- **`BiasDossier`** — pure function library: outlet bias scores + per-case article distribution → the *evidence list* shown in the dossier (not a single bar — see PRODUCT.md anti-reference). Lives in `DesignSystem` because it's view-supporting, no I/O.
- **`Choreography`** — the centerpiece of the app's "trust mechanic." Reusable motion primitives:
  - `PinDrop(from:to:weight:)` — animated drop with ricochet
  - `RedStringDraw(from:to:strokeDuration:)` — stroke-by-stroke connection
  - `PolaroidDevelop(image:duration:)` — ink-fade-in like instant film
  - `StampSlam(verdict:rotation:)` — slam into place with screen shake
  - Each has a `reduceMotion: true` variant that preserves *information* without vestibular cost (per DESIGN.md and PRODUCT.md accessibility section).
- **`DeepCheckOrchestrator`** — coordinates the three layers (on-device first-pass → Google Fact Check API lookup → server Deep Check). Drives Live Activity progress AND the in-app pin-and-string animation: each "source reviewed" message from `deep-check-worker` triggers a `PinDrop`; each "connection found" triggers a `RedStringDraw`; the final verdict triggers a `StampSlam`.
- **`BoardComposer`** — pure function: raw case list + user mode + days-on-the-beat history → composed board. In Balanced mode, scores each case for "would this expand your beat?" and reorders.

**Navigation:** `NavigationStack` per tab, value-based routing. Three tabs (working names — final per impeccable workflow): **The Board** · **Deep Check** · **The Beat (You)**. `NavigationSplitView` on iPad.

**State persistence:**
- Pinned cases, closed cases / archive, prefs, days-on-the-beat stats → CloudKit private DB
- Auth token → Keychain
- API response cache → on-disk URLCache + SwiftData for offline reads
- App settings → `@AppStorage` (UserDefaults)

---

## Data model

Six tables in D1. Internal table names use generic vocabulary; user-facing language is set in the UI layer per CRIME BOARD framing (see PRODUCT.md / DESIGN.md).

### `outlets` (~200 rows, rarely change) — *"persons of interest"* in UI
- `id` (e.g. `"nytimes"`)
- `name`, `homepage_url`, `rss_urls[]`, `logo_url`
- `bias_score` (normalized to -10 to +10 internally; source data is AllSides buckets and/or Ad Fontes' -42 to +42 scale, mapped at ingest time)
- `reliability_score` (normalized 0–64; higher = more original fact reporting, lower = more misleading content; mirrors Ad Fontes scale)
- `bias_source` (`allsides` / `adfontes` / `manual`)
- `ownership` (e.g. "News Corp"), `funding_model`, `wikipedia_url`

### `articles` (high churn, 30-day retention in D1, archive to R2) — *"sources / pins"* in UI
- `id`, `outlet_id`, `url`, `title`, `description` (RSS snippet), `published_at`, `fetched_at`
- `embedding` (BLOB — JSON-encoded float array of `bge-small-en-v1.5` output, 384 dims; used for clustering then nulled out)
- `cluster_id` (nullable until clustered)
- `topic_tags[]`

### `clusters` — *"cases"* in UI
- `id`, `created_at`, `updated_at`
- `representative_title` (most "neutral" framing, picked algorithmically — used as the case headline)
- `centroid_embedding` (BLOB — JSON-encoded float array, 384 dims; running average of joined article embeddings, used for similarity comparison)
- `topic_tags[]`
- `bias_distribution` (computed: `{left: 8, center: 11, right: 4}` — feeds the BiasMeter dossier)
- `is_breaking` (boolean — drives push)
- `article_count`

**Note on embeddings in D1:** D1 has no native vector type. Embeddings are stored as JSON-encoded float arrays in BLOB columns. Cosine similarity is computed in the Worker (small enough vectors at our volume — ~500–2000 articles/day vs ~5000 active clusters in 48h window — that brute-force comparison is fine without a vector DB). Revisit if comparison time exceeds ~100ms per article.

### `fact_checks`
- `id`, `claim_text`, `verdict` (`true` / `mostly-true` / `mixed` / `mostly-false` / `false` / `unverifiable`)
- `source` (`politifact` / `snopes` / `reuters` / `our-deep-check`)
- `evidence_url`, `checked_at`
- `claim_embedding` (for fuzzy matching)

(UI verdict copy uses the wry voice from PRODUCT.md — e.g. "Closed: B.S. confirmed." for `false` — not the raw enum value.)

### `users`
- `id` (Apple `sub` or generated), `created_at`, `pro_until` (nullable; Senior Detective subscription expiry)
- `feed_mode` (`strict` / `balanced`)
- `selected_topics[]`, `selected_outlets[]`, `excluded_outlets[]`
- `notification_prefs` (json)

### `push_subscriptions`
- `user_id`, `device_token`, `topic_subscriptions[]`, `last_seen_at`

**Notable absences (deliberate):**
- No pinned-cases / closed-cases table on server — those live in CloudKit.
- No article body content table — never store full text (legal + cost). Only metadata + snippet + link out.
- No comments / votes / follows — out of scope for v1.
- **No XP / badges / achievements tables** — per PRODUCT.md, achievement lives in the archive as case files, not as point counts. Days-on-the-beat is a derived stat from CloudKit history, not a stored score.

---

## Screen inventory

Final names per impeccable workflow. Working names below; engineering shapes stable.

### Tab 1 — The Board (today's pinned cases)
- **The Board (Home)** — cork-board feed of cases. Each pinned card shows: representative headline, BiasMeter dossier preview (count of L/C/R sources, NOT a bar chart), reliability indicator, time. Daily Briefing animation on first open of the day (per DESIGN.md component direction). Pull-to-refresh, beat (topic) filter chips.
- **The Open Case File** — single case opened. Source pins arranged on the board, red-string connections between corroborating reports, polaroid-style photo evidence where available, BiasMeter dossier as the case's evidence list, verdict stamp area (if any fact-check exists). "Persons of interest" panel for outlet transparency.
- **Source Dossier** (sheet, manila-folder treatment per DESIGN.md) — single article from a single outlet: outlet logo, headline, AI summary line, bias context, reliability, ownership, "Read at source" → SafariView.
- **Person of Interest profile** — outlet detail: bias on a chart, reliability, ownership, funding, founding, Wikipedia link, recent stories from this outlet.

### Tab 2 — Deep Check (hero fact-check tool)
- **Deep Check (Home)** — "what do you want investigated?" input (paste URL or claim) + recent investigations + suggestions.
- **First-Pass Verdict** — <2 sec on-device analysis + Google Fact Check API matches if any. Verdict, confidence, evidence summary. Big "Open formal investigation" (= Deep Check) CTA.
- **Deep Check In Progress** — the centerpiece moment. In-app: animated cork board where pins drop in real time as `deep-check-worker` reports each source reviewed; red strings draw stroke-by-stroke as connections are found. Live Activity on lock screen + Dynamic Island shows abbreviated state. Premium feel comes from the choreography, not chrome.
- **Verdict / Closed Case** — verdict stamp (CONFIRMED / BUSTED / COLD CASE / etc.) + citations. Side-by-side: claims supported / contradicted / missing context. Saved to archive as a case file.

### Tab 3 — The Beat (account, stats, settings)
- **The Beat (Home)** — days-on-the-beat tally, case-clearance rate this week/month, Senior Detective status, quick links. (Framed as detective-procedural, never as XP / streak panic — see PRODUCT.md.)
- **Case Clearance** — the "Reading Diet" surface, framed as case stats: outlet exposure (persons of interest you've read), beat balance over time, "perspective gaps" suggestions.
- **Pinned** — cases the user has pinned to follow.
- **Closed Cases** — archive with search.
- **Beat & Persons of Interest** — manage subscriptions, switch strict/balanced.
- **The Wire** (notifications) — granular controls.
- **Senior Detective** — paywall (StoreKit 2), subscription management.
- **Persons of Interest directory** — global outlet directory, search, filter.
- **Settings** — accessibility, accounts, privacy, support, about, "Trust & Methodology" page.

### Cross-cutting surfaces
- **Day One on the Beat (onboarding)** — 4 screens: welcome → pick beats → pick mode (strict/balanced) → notifications opt-in → Sign in with Apple (skippable).
- **Share Extension** — "Share to The Crime Board → Investigate" accepts URL/text from any app → lands in Deep Check.
- **Widgets** (3 sizes) — Today's Top Pin · Beat Balance · Quick Investigation launcher. Visual treatment per DESIGN.md (paper on cork; never lifted Material chrome).
- **Live Activity** — Deep Check in progress (with abbreviated pin/string state) + breaking case banner (Senior Detective).
- **App Intents / Siri** — "Hey Siri, investigate [claim]" · "Show today's board" · "What's my beat balance?"

---

## Three flagship user flows

### Flow A — The morning beat (free user, ~3 min/day)
Open app → Daily Briefing animation wakes the board → see pinned cases with BiasMeter dossier counts visible at a glance → tap one with intriguing distribution → land on Open Case File → explore source pins / red-string connections / verdict stamp if any → tap a source pin to read at outlet → return → pin to follow → close.

**App job:** the workflow itself does the trust-building. Bias context comprehensible without explanation. The user feels they're *working a board*, not scrolling a feed.

### Flow B — "Is this true?" (the hero flow)
Open app → Deep Check tab → paste URL or text → 2-sec first-pass verdict → tap "Open formal investigation" → in-app cork board comes alive: pins drop as sources are reviewed, red strings draw between corroborating reports → Live Activity / Dynamic Island shows abbreviated progress on lock screen → push notification when verdict slams into place → tap to see the closed case file with citations.

**App job:** the *process* is the product, not the verdict. Show every source pinned, every connection drawn. Deep Check feels like an upgrade because the user *watches the work happen*, not because of upsell copy.

### Flow C — Beat balance awareness (the retention hook, never the point)
Sunday morning push: *"Quiet week on the right beat. 4 unread cases."* → tap → land in Case Clearance → balance visualization (procedural, never a bar chart per DESIGN.md anti-references) → tap "Walk the other beat" → curated balanced board for that day.

**App job:** make filter-bubble breaking feel like *noticing what you missed in your own investigation*, not like a teacher grading you. Wry, not preachy.

---

## Visual design

**See `/DESIGN.md`.** Highlights this spec relies on:

- Cork Tan / Paper White / Ink Black / Evidence Red palette (no `#000`, no `#fff`).
- Display serif for *story*; monospace for *file* (case numbers, timestamps, source IDs, stamp inscriptions).
- The **Red-String Rule**: Evidence Red is reserved for connection / verdict / flag — never general accents.
- Choreographed motion (pin-drop, red-string draw, polaroid develop, stamp slam) is the **trust mechanic** — investment from day one, not a polish pass. Every theatrical animation has a Reduce Motion equivalent.
- The **No-Cork-Texture-As-Chrome** rule: cork only on surfaces that *are* the board.
- The **On-The-Board** elevation: surfaces are pinned, not floating. No generic blue-gray Material drop shadows.

**Detailed UI iteration** happens via the impeccable skill workflow (`$impeccable shape <feature>` → `$impeccable craft <feature>` → `$impeccable polish <target>`). DESIGN.md is in seed mode and will be regenerated (`$impeccable document`) once SwiftUI components exist.

---

## Cross-cutting concerns

### Testing strategy

- **Swift Testing framework** (`@Test` macros).
- **Unit tests** on pure logic: `BiasDossier`, `BoardComposer`, `Choreography` motion timing, RSS parser, JWT verifier. ~80% coverage target on Models + pure functions.
- **Integration tests** on `APIClient` against real Cloudflare staging env hitting real D1 — no mocked HTTP.
- **Snapshot tests** on key SwiftUI views (pinned card, polaroid, stamp, BiasMeter dossier, widget) for visual regression.
- **OnDeviceAI tests:** prompt assembly, output parsing, error handling (model itself isn't testable directly).
- **Choreography tests:** verify Reduce Motion variants preserve all information conveyed by the full-motion version (per PRODUCT.md accessibility bar — "a screen-reader user, a Reduce Motion user, and a sighted user with motion enabled all describe the same case state in the same detective language at the end of the same Deep Check").
- **End-to-end** XCUITest for the three flagship flows on CI before each release.
- **Worker tests:** Vitest + `@cloudflare/vitest-pool-workers`, hits real D1 in `--local` mode.

### Error handling

- **Network failures** are expected, not exceptional: cached fallback → "tap to retry" → graceful "we're having trouble" state. No crashes, no blank screens. Copy uses the wry voice from PRODUCT.md (e.g. *"Lost the wire. Trying to reconnect."*).
- **Foundation Models failures** (model unavailable, content filtered, timeout): show a clear error state with "open formal investigation" affordance — Deep Check uses server-side AI and runs the analysis a different way.
- **Clustering misfires:** Open Case File has a "this doesn't belong on this case" link — feeds the moderation queue.
- **Push delivery failure:** retry once, then drop and alert ops.
- Every error surfaces to UI with an action.

### Accessibility (production-grade requirements; baseline = WCAG 2.2 AA)

Per PRODUCT.md and DESIGN.md:

- Full **VoiceOver** support; labels written in detective vocabulary, not raw element data ("New source pinned: Reuters, high reliability, connects to two existing pins"). BiasMeter dossier exposes its evidence list through a custom rotor.
- **Dynamic Type** scales to AX5 throughout, including inside polaroid captions and stamp text. `ViewThatFits` switches dense pin layouts to vertical stacks at large sizes. Touch targets meet 44pt minimum even when pins / photo corners *appear* smaller.
- **Reduce Motion** is a first-class path: pin-drops become instant placement with a subtle highlight; red-string draws become solid lines that fade in; polaroid develops become immediate image reveals; stamp slams become a labeled stamp graphic without screen shake. Reduce Motion users still get the detective experience — without vestibular cost.
- **Reduce Transparency** — paper surfaces become opaque (no chroma loss).
- **Color & contrast** — all critical reliability/verdict signals carry shape, label, and position cues in addition to color. Cork-board palette constructed with chroma-aware contrast so red string, push pins, and stamp inks remain distinguishable across common color-vision differences.
- **Sound** — every audio cue (pin-drop thunk, stamp slam, string twang) is *secondary*. No information is sound-only. A muted device loses flavor, never function.

### Privacy & data handling

- Server never sees what you read. Cases are fetched in batches.
- **CloudKit private DB** for all personal data (pinned, closed cases, prefs, days-on-the-beat) — Apple sees none of it.
- **Foundation Models** runs on-device → first-pass verdicts are private by default. Surface "investigated on this device" copy where it matters (per CRIME BOARD voice).
- **Deep Check** sends claim text to server (necessary), but doesn't link to user identity beyond rate-limiting.
- **No third-party SDKs** for analytics, crash reporting (use MetricKit), or ads.
- Privacy nutrition label minimal: D1 user record + email.

### App Store review

- **News app guidelines** require editorial standard / corrections policy → publish "Trust & Methodology" page in Settings + on website.
- **Sign in with Apple** present (required given other auth methods).
- **Subscription** uses StoreKit 2; Senior Detective paywall clearly states pricing + auto-renew.
- **Generative AI** requires user-reportable harmful output → "Report this verdict" on every Deep Check result.
- **Foundation Models** is a new framework — may attract early review scrutiny, but Apple wants apps to use it.
- **Content moderation:** linking to outlets ≠ hosting content, but App Store may still want a clear moderation policy. Document it.
- **Theatrical motion** — App Store reviewers may ask about Reduce Motion conformance. The first-class Reduce Motion path is a v1 requirement, not a v1.1 polish, *partly* for this reason.

### Observability (lean)

- Cloudflare Workers Analytics (free) for backend.
- MetricKit for client-side perf + crash data (free, on-device aggregation).
- No Datadog / New Relic / Sentry for v1 — add only if a real problem demands it.

---

## Out of scope for v1

- Comments / discussions (moderation cost; conflicts with sovereign-detective register)
- Web app (iOS-first per PRODUCT.md; defer to v2)
- Android app (defer)
- User-submitted fact-checks / crowdsourced ratings (defer; complex moderation)
- Social sharing beyond iOS share sheet (no follower graph, no in-app community — per CRIME BOARD anti-reference to LinkedIn-style status games)
- Multilingual support (English-only at launch; design doesn't preclude it)
- iPad-specific designs beyond `NavigationSplitView` defaults

**Apple Watch app** is in v1 as a Senior Detective feature. Carries cut risk: if v1 timeline pressure mounts, it slips to v1.1 — call this out explicitly during planning.

---

## Open items to resolve before / during implementation

- **Bias data licensing for commercial use** — current plan uses public AllSides + Ad Fontes datasets; reach out to AllSides and Ad Fontes for proper commercial licensing before App Store launch.
- **RSS source curation** — definitive list of ~200 outlets across the spectrum, vetted for reliability and feed quality.
- **Deep Check quality bar** — Workers AI Llama 3.1 8B is the v1 default; if quality is insufficient, fall back to Claude Haiku 4.5 (~$0.01/check). Decision deferred until we can measure.
- **Trust & Methodology page** content — needs writing before App Store submission.
- **Final user-facing screen / surface names** — set via the impeccable workflow as DESIGN.md exits seed mode (e.g. is the feed tab "The Board," "Today's Board," "The Wire"? final names live in PRODUCT.md / DESIGN.md, not here).
- **Display serif and monospace font choices** — direction set in DESIGN.md (e.g. Tiempos Headline / Berkeley Mono territory); final selection during implementation.
- **Sound design** — pin-drop thunk, stamp slam, string twang, etc. Need recorded or synthesized assets; specify in implementation plan.
