# For Real?? — App Design

**Status:** approved (brainstorming) — pending implementation plans
**Date:** 2026-05-04
**Supersedes:** [`2026-05-02-news-app-design.md`](2026-05-02-news-app-design.md) — the cork-board / investigation framing is retired.

---

## 1. Premise

**For Real??** is a single-purpose iOS utility: paste a video link or article URL, get back a sassy "fax" that fact-checks it. Built to be the answer to *"is this even real?"* in your group chat.

The previous app (THE CRIME BOARD / `receipts`) shipped 9 PRs of an investigation-themed UI — sepia polaroids, manila dossiers, torn-note feeds, hub-and-spoke "Deep Check" surfaces. That whole genre is wrong for the new product.

**Renames and what stays:**
- **App brand: `receipts` → For Real??.** App Store name, icon wordmark, marketing — all switch to "For Real??". The previous lowercase `receipts` brand is retired.
- **In-app artifact term: "fax".** The thing the app produces is called a *fax* — wordplay on "fact / facts / fax." DB tables, API endpoints, and the analyzer worker keep the legacy `receipts` schema name; users never see it.
- **Codename: THE CRIME BOARD is retired** with the genre.
- **Engineering namespace: `crimeboard` stays.** Cloudflare resources (`crimeboard-dev/-staging/-prod`), npm packages (`@crimeboard/*`), and the worker name `crimeboard-api` are not renamed — re-provisioning Cloudflare infra and refactoring imports earns no user-visible value, and the namespace is invisible outside the repo.
- **Backend infrastructure stays.** The article-scraping work, migrations, deploy plumbing — all kept and extended.
- **iOS surface area is rebuilt fresh** (see §4 Project layout).

### What "For Real??" feels like

- **Shazam for truth.** Open the app, paste a link, watch a fax fill in over ~30s, screenshot it, send to your group chat, close the app. In and out.
- **One feature done well.** No feed, no daily briefing, no cork board. Just paste-and-fax.
- **Bestie tone.** *"Bestie, the 'Harvard study' he keeps citing? Doesn't exist. Made it up. Truly bold."* Sassy fact-checker, not deadpan referee.
- **Screenshot-bait.** The fax is the artifact. It must look great as a 1080×1920 image dropped into iMessage.

---

## 2. The Fax

The fax is the product. Every other surface exists to produce or recall a fax.

A fax is composed of:

- **Source metadata** — URL, type (video / article), provider (TikTok / YouTube / article), title.
- **Final verdict** — one of `nope` ❌, `mixed` 🤷, `yep` ✅, `skip` 🤔.
- **Final commentary** — one or two playful sentences summarizing the verdict in the bestie voice.
- **2–3 claim cards**, each with:
  - The extracted claim (short, quotable text)
  - Per-claim verdict (same taxonomy as final)
  - Per-claim commentary (one-line bestie roast)
  - Sources (array of `{url, title}` used to ground the verdict)

Visual treatment is owned by the impeccable skill at implementation time. This spec defines structure and content; not look-and-feel.

### Verdict taxonomy

| Code | Glyph | Meaning |
|---|---|---|
| `nope` | ❌ | Clearly false; sources contradict |
| `mixed` | 🤷 | Partially true / context missing / overstated |
| `yep` | ✅ | Supported by credible sources |
| `skip` | 🤔 | Not checkable (opinion, joke, all vibes) |

The fax-level final verdict is synthesized from claim verdicts (worst-of, with `skip` neutral).

---

## 3. User Flows

### Primary: paste a link, get a fax

1. User has a URL — TikTok, YouTube/Shorts, or article — that they want checked.
2. **From inside the app:** open For Real??, paste into the box (or tap "Paste from Clipboard" when a URL is detected), tap analyze.
3. **From outside the app (preferred):** in TikTok, Safari, iMessage, or any app that exposes a URL via the iOS Share sheet, tap Share → "For Real??" appears in the sheet → tap → app opens with analysis already starting.
4. The Fax screen appears. Final verdict and commentary are placeholders. Claim cards stream in one at a time as the backend resolves them, ~20–60s total. The user watches it fill in.
5. Once final, the user can screenshot or tap Share to export the fax as an image.

### Re-paste of a known URL

If the URL has been analyzed before (globally — not just by this user), the cached fax is returned immediately. The user sees a fully-formed fax with no waiting and no token spend.

### Re-open a past fax

Tap the small **Recent** icon top-corner on Home → list of past faxes (anonymous local; optionally synced if signed in) → tap a row → the original Fax screen, fully populated.

### Sign in with Apple

A "Sign In" button lives on the Recent screen and the Settings page. Tap → Apple's 1-tap flow → backend exchanges the Apple identity token for a session token and links the calling device's anonymous faxes to the new account (the `migrated_count` in the response is shown to the user as a small confirmation). iOS then calls `GET /v1/receipts` to fetch any faxes already on that account from other devices and merges them into the local SwiftData store. Account screen has Sign Out + Delete Account (App Store requirement when SiwA is present).

---

## 4. iOS App

### Surface map

| Surface | Purpose | Notes |
|---|---|---|
| **Home** | Single-purpose paste box | "Paste from Clipboard" affordance when a URL is on the clipboard. Small "Recent" icon top-corner. |
| **Fax** | Streaming-fill fax; final state with share | Whether this transitions in via push or overlays Home is an impeccable-time choice. |
| **Recent** | Tucked-away history list | Reached only via the icon on Home. Includes "Sign in with Apple" prompt + Settings entry. |
| **Settings** | Account + about + delete account | Reached from Recent. Sign in / Sign out / Delete account / version info. |
| **Share Extension** | iOS share-sheet target | Receives a URL from any app, kicks off analysis directly. Same code path as the in-app paste. |

### Project layout (fresh; no carryover from old packages)

The repo's existing iOS Swift packages (`DesignSystem`, `Choreography`, `DailyBriefing`, `DeepCheck`, `SourceDossier`, `Archive`) are deleted. New layout, designed for the smaller surface area:

```
ios/
  ForReal.xcodeproj
  ForReal/                     # main app target
  ForRealShare/                # share extension target
  Packages/
    ForRealKit/                # core models, API client, SSE stream consumer, SwiftData store
    ForRealUI/                 # views, view-models, navigation
```

UI styling tokens live in `ForRealUI` and are decided/iterated by the impeccable skill — no token surface is locked in this spec.

### State

- **In-flight analysis** — `receipt_id` + active SSE connection. App memory only. Cancelled if the user navigates away or backgrounds for >30s.
- **Local store** (SwiftData) — completed faxes and their claims. Indexed by URL hash so re-pasting a known URL hits cache. Keyed by anonymous `device_id` for ownership.
- **Auth state** — `nil` (anonymous, default) or `{user_id, session_token}` after SiwA. Stored in Keychain.
- **`device_id`** — UUID generated on first launch, persisted in Keychain (survives reinstall), sent as `X-Receipts-Device` on every API call.

---

## 5. Backend

> **Naming note for this section:** the wire format and schema use `receipts` everywhere — DB table, API paths (`/v1/receipts`), worker name (`workers/receipts-analyzer`), event names (`receipt_final`), header (`X-Receipts-Device`). This is the engineering layer; the user-facing artifact term is "fax" and the two never collapse. Don't rename the schema in implementation plans without explicit user direction.

### Architecture

Same Cloudflare Workers monorepo, with one new worker and additions to the existing one:

- **`workers/api`** (existing) — gains receipt CRUD endpoints, SiwA exchange, and the SSE stream endpoint.
- **`workers/receipts-analyzer`** (new) — runs the full analysis pipeline; invoked async from `api`. Streams claim results back via the queue/durable-object the SSE endpoint reads from.

The TikTok-audio extraction step cannot run in a Cloudflare Worker (no native binaries). Two viable paths, picked at plan time:
- **Companion service** — small Node/Go server (Fly.io / Cloudflare Container) running yt-dlp; called by the analyzer worker.
- **Paid extraction API** — TIKAPI, RapidAPI, or similar; callable directly from the worker.

YouTube uses the official Data API + audio download via standard HTTP and is straightforward.

### Pipeline

```
URL → ① classify → ② fetch (audio for video, body for article)
     → ③ transcribe (video only, via Whisper / Workers AI)
     → ④ claim extraction (LLM, structured output: 2–3 most checkable claims)
     → ⑤ for each claim, in parallel: search the web + verify (LLM with tool use)
         → emit `claim_final` SSE event as each one resolves
     → ⑥ synthesize final verdict + commentary
         → emit `receipt_final` SSE event
     → mark receipt `done`
```

Specific LLM choices (extraction model vs verification model) are deferred to the implementation plan.

### Data model (additions)

```sql
users
  id                   uuid pk
  apple_user_id        text unique  -- the stable Apple sub
  display_name         text         -- optional, set by user
  created_at           timestamptz

receipts
  id                   uuid pk
  source_url           text
  url_hash             text         -- for cache lookup; SHA-256 of normalized URL
  source_type          text         -- video | article
  source_provider      text         -- tiktok | youtube | article
  title                text
  status               text         -- pending | streaming | done | failed
  final_verdict        text         -- nope | mixed | yep | skip; null until done
  final_commentary     text         -- null until done
  error_code           text         -- null unless failed
  device_id            text         -- anonymous owner; non-null
  user_id              uuid         -- nullable; set when device's anon history migrates
  created_at           timestamptz
  finished_at          timestamptz  -- null until done
  index on (url_hash)               -- global cache lookup
  index on (device_id, created_at)
  index on (user_id, created_at)

claims
  id                   uuid pk
  receipt_id           uuid fk
  position             int          -- 1, 2, 3
  claim_text           text
  verdict              text         -- nope | mixed | yep | skip
  commentary           text
  sources              jsonb        -- array of {url, title}
  resolved_at          timestamptz
```

### API (snake_case wire, per locked convention)

```
POST   /v1/receipts                        { url }
       → { receipt_id, status, cached: bool }
       Idempotent on (url_hash, device_id_or_user_id):
         - Returns existing receipt if a global cache hit exists (any device).
         - Otherwise creates a new pending receipt and triggers the analyzer.

GET    /v1/receipts/:id/stream             (SSE)
       Events:
         status         { status }
         claim_final    { position, claim_text, verdict, commentary, sources }
         receipt_final  { final_verdict, final_commentary }
         error          { error_code, message }

GET    /v1/receipts/:id                    → full receipt JSON (for re-fetch / sync)
DELETE /v1/receipts/:id                    → user-side delete (removes association; backend keeps for cache)

GET    /v1/receipts                        ?limit=N&before=cursor
       → list of receipts owned by the calling device (or user, if signed in)

POST   /v1/auth/apple                      { identity_token }
       → { user_id, session_token, migrated_count: int }
       Validates Apple token, finds-or-creates user, links the requesting device's
       anonymous receipts to that user, returns count migrated.

DELETE /v1/auth/account                    Auth required; deletes user, unlinks receipts.
```

All endpoints accept `X-Receipts-Device: <uuid>` header. Authenticated endpoints also accept `Authorization: Bearer <session_token>`.

### Quotas / abuse mitigation

- **Daily cap per device_id (anonymous):** 10 receipts / 24h.
- **Daily cap per user_id (signed in):** 50 receipts / 24h. (Acts as a small SiwA carrot.)
- Cache-hits don't count against the cap (re-pasting a known viral video is free for the user).
- Exceeded → friendly error: *"Whoa bestie, that's a lot of faxes today. Try again tomorrow — or sign in for a bigger limit."*
- We don't try to defeat a determined adversary. Forging device IDs is trivial; we accept that and rely on global URL caching to keep the actual cost line flat.

---

## 6. Edge cases

| Situation | Behavior |
|---|---|
| URL won't resolve / private / removed | `failed` with `error_code: source_unreachable`; UI shows: *"Couldn't reach this one — link may be private or pulled."* |
| TikTok extraction fails | One automatic retry; then `failed` with `error_code: provider_blocked`; UI: *"TikTok's playing hard to get. Try again in a sec."* |
| Audio transcription fails | `failed` with `error_code: transcription_failed`; UI: *"Couldn't make out the audio."* |
| Long YouTube video (>10 min) | Cap analysis at first 8 minutes; the fax's final_commentary notes the cap. |
| No checkable claims (opinion, joke, music) | The fax completes with `final_verdict: skip`. Commentary: *"This one's all vibes. Nothing to fact-check, just feelings."* No claim cards. |
| All claims unresolvable (web search empty) | Each claim lands as `mixed` with commentary noting the gap. |
| Article behind paywall | `failed` with `error_code: paywalled`; UI: *"Paywall blocked us — try a public mirror."* |
| Unsupported provider (Insta, FB, Bluesky video) | Detected at URL parse, before quota counting. UI: *"We don't speak that platform yet — coming later."* |
| Re-paste of cached URL | Idempotency hit; cached fax returned in the POST response (no SSE needed). UI: fax appears instantly. |
| Re-paste of own pending receipt | Idempotency hit; returns the in-flight receipt_id; iOS reuses the existing SSE stream. |

---

## 7. Testing

Scaled to the surface area; this is two-track (backend + iOS).

### Backend

- **Unit tests (existing pattern):** URL classifier, prompt golden tests for claim extraction, claim verifier with mocked LLM + mocked search, idempotency lookup, quota enforcement.
- **Pipeline integration test:** end-to-end with a fixture transcript (no live LLM calls) — confirms SSE event sequence.
- **Curated quality set:** ~15 known viral misinfo videos / articles + ~5 known-true + ~5 opinion / `skip` cases. Re-run before release; the pass-rate threshold is set in the pre-release implementation plan once we've calibrated against actual model behavior.

### iOS

- **Unit tests:** API client (with stubbed responses), SSE event parser, SwiftData store CRUD, URL normalizer, idempotency cache hit, anon→signed-in migration flow.
- **Snapshot tests:** Fax screen in each of (loading / streaming with 1, 2, 3 claims / final each verdict / failed). Home with and without clipboard URL. Recent list empty + populated.
- **UI tests:** the primary flow (paste → analyze → final), the share-extension flow, sign in → migration.
- **Manual:** ~5 real-world URLs across both providers per platform release.

---

## 8. Out of scope (post-MVP)

To name the things explicitly so they don't sneak in:

- Public profiles / shareable fax URLs on the web.
- "Send a fax to a friend" in-app (sharing is screenshot only for MVP).
- Instagram Reels, Facebook video, Bluesky video, X video, direct mp4.
- Comment threads / discussion under a fax.
- Notifications (no push for MVP).
- iPad-specific layout (universal layout fine for v1; iPad polish later).
- Web app / Android.
- Multi-language support (English only for MVP).

---

## 9. Open implementation choices (deferred to plan time)

- **TikTok audio extraction strategy** — companion service vs paid API.
- **LLM model selection** — extraction model, verification model (Workers AI / OpenAI / Anthropic).
- **SSE vs WebSocket vs Durable Object** — for the streaming connection. SSE is the assumption; revisit if it doesn't compose well with Workers AI streaming.
- **Whisper provider** — Workers AI Whisper vs OpenAI Whisper API.
- **Fax visual treatment** — entirely owned by the impeccable skill in implementation plans.

---

## Skill applicability

- **`impeccable`:** YES, applies to every iOS UI plan derived from this spec (Home, Fax, Recent, Settings, Share Extension). Backend / data-layer plans do not invoke impeccable.
