# Prompt for Claude (UI design)

Copy-paste the section below into Claude design tooling. **Strongly recommended:** also attach `/PRODUCT.md` and `/DESIGN.md` from the project root — those are the canonical product and visual specs and contain rules that this prompt only summarizes.

---

I'm designing a native iOS app called **THE CRIME BOARD** — a news-as-investigation reader for news-skeptical adults. Architecture and product strategy are already locked. I want you to design the iOS UI screens. Defer to the attached PRODUCT.md (strategy / voice / anti-references) and DESIGN.md (visual system) wherever this prompt is less specific.

## North star

*"The Open Case File"* — a working detective's desk at 11pm. Materials look like materials, not UI textures dressed up as objects. The reader is addressed as a peer doing real work; the app's job is to pin the receipts in front of them and get out of the way.

## What the app does

Three core surfaces:

1. **The Board** — cork-board feed of *cases*, where one case = one real-world event covered by multiple outlets. Each case shows a BiasMeter dossier (a list of source evidence, never a bar chart) and a count of L/C/R sources.
2. **The Open Case File** — opens one case into source pins arranged on the board, red-string connections between corroborating reports, polaroid photo evidence where available, and verdict stamps when fact-checks exist. Outlet ("person of interest") transparency one tap away.
3. **Deep Check** — the hero feature. User submits a claim or article URL; the app *interrogates sources* in real time on a cork-board canvas: pins drop as sources are reviewed, red strings draw stroke-by-stroke as connections are found, a verdict stamp slams into place at the end. The animation IS the trust mechanic; the user watches the work happen.

## Two operating modes (set in onboarding, switchable any time)

- **Strict mode** — user picks beats (topics) + persons of interest (outlets); the board shows what they asked for, with bias dossiers layered on top.
- **Balanced mode** — user picks beats; the app intentionally pins cases from across the spectrum and shows a weekly *case-clearance* view.

## Monetization

Free + **Senior Detective** subscription ($4.99/mo or $39.99/yr). **No ads anywhere.** Senior Detective unlocks: unlimited Deep Check, custom beat alerts, cross-case linking, archive search older than 30 days, raw-source export, Apple Watch app. Pro tier label is mono **SENIOR DETECTIVE** with a stamp glyph — never a gold crown / premium-badge cliché.

## Platform & technical constraints

- **iOS 26+ only** (iPhone + iPad), Apple Watch companion (Senior Detective)
- **SwiftUI** native — the tactile motion is the trust mechanic, must run with native performance
- **Apple Foundation Models** runs on-device for the first-pass verdict on Deep Check (privacy + speed differentiator — surface "investigated on this device" copy where it matters)
- **Dynamic Island + Live Activities** for in-progress Deep Check and breaking case banners
- **Home / lock screen widgets** in 3 sizes
- **Share extension** so users can investigate things from any other app

## Visual system (per DESIGN.md — read it; this is the briefest summary)

- **Palette (four named roles):** Cork Tan (board), Paper White (evidence), Ink Black (type), Evidence Red (connection / verdict / flag — ≤10% of any screen via the **Red-String Rule**). Plus Polaroid Sepia (archive), Pencil Gray (secondary). **No `#000`, no `#fff`** — every neutral has warm trace chroma.
- **Typography:** display serif for *story*; monospace for *file* (case numbers, timestamps, source IDs, stamp inscriptions, BiasMeter labels). Marker / handwritten face is overlay seasoning only — never body, headlines, or controls. Two voices, clearly assigned.
- **Elevation — On-The-Board Rule:** surfaces are pinned, not floating. Default elevation is low and warm-tinted. No generic blue-gray Material drop shadows. Lifted-while-dragging shadow appears only during direct manipulation.
- **Motion is the trust mechanic, not polish.** Pin-drops with weight + ricochet. Red-string draws stroke-by-stroke. Polaroid develops with ink-fade-in. Stamp slams with screen shake. Each must have a **first-class Reduce Motion** equivalent that preserves the *information* without vestibular cost.
- **Cork-Texture-Never-Decorative Rule:** cork only on surfaces that *are* the board. Never wraps cards, modals, sheets, tab bars.

## Voice (per PRODUCT.md)

**Tactile, wry, sovereign.** Stand-up comedian energy in copy, not press release. Empty state: *"Quiet day on the beat. Allegedly."* Verdict copy: *"Closed: B.S. confirmed."* Outlet labels: *"Persons of interest."* Streaks: *"Days on the beat."* Cold cases = stories you never finished. Humor never punches at the user — it keeps them company through their skepticism.

## Hard prohibitions (per PRODUCT.md anti-references)

If a screen could be lifted from any of these and dropped in without a designer noticing, the design has failed:

- **Apple News / Google News** — anonymous algorithmic feeds, generic story cards with publisher logo as authority. The opposite of investigation.
- **NYT / WaPo apps** — broadsheet reverence, deference to publisher voice, serif solemnity. We are wry, not respectable.
- **Ground News / AllSides** — balance-as-bar-chart, library-of-sources visual language. We share their goal of cross-source visibility but render it as physical evidence on a board, **not** as a horizontal stacked-bar widget. (BiasMeter is a *dossier*, not a bar.)
- **Duolingo** — XP bars, level-up celebrations, streak panic, mascot guilt. Achievement here lives as case files in the archive, not abstract scores.
- **LinkedIn** — badges menu, achievement-as-trophy, public-facing status games.

Plus: **no costume-piece kitsch** — no fake film grain over screenshots, no whole-screen sepia filters, no gratuitous typewriter-paper backgrounds behind every button. The metaphor is a working stage, not a Halloween set.

## Signature visual elements (design these with extra care)

These appear repeatedly and define the app's identity:

1. **BiasMeter dossier** — appears on every case on the board and at the top of every Open Case File. Per PRODUCT.md: *an evidence list, not a single number*. Show what *informed* the assessment — discrete pieces of evidence, source attributions in mono. Comprehensible in <1 second at a glance, expandable on tap. Beautiful at small (board row) and large (case header) sizes. Show 2-3 directions for how to render the dossier as a quickly-scannable summary while still being a *list of evidence* (not a stacked bar).
2. **Pinned card / source pin** — paper-white evidence card pinned to cork with a real push-pin (top-left or top-center). Pin is a real interactive object. Pinned-card shadow is the on-the-board treatment from DESIGN.md.
3. **Polaroid** — image with thick paper border, slight rotation (±2–4°) at rest, polaroid shadow with hint of corner curl. Captions inside the white border can use the marker face for the handwritten-on-bottom-edge feel; system metadata uses mono.
4. **Stamp** — verdict graphic (CONFIRMED / BUSTED / COLD CASE / CLOSED / etc.) with mono inscription, slight rotation, ink-bleed edges. Stamps are *placed*, not pressed — they appear with a slam animation and stay slightly off-axis.
5. **Red-string connection** — animated stroke between two pinned objects. Drawn stroke-by-stroke during Deep Check; static after. Subtle shadow underneath suggesting it lies on the cork.
6. **Source dossier** (full-screen sheet) — manila-folder treatment per DESIGN.md: tab at the top with mono case-number label, paper-white interior, body content with serif body type and mono metadata blocks. Pull-to-close mimics closing the folder.
7. **Daily Briefing animation** — top-of-Board header that wakes the cork board on first open of the day: lights flicker on, new pins appear in sequence, mono date stamp slams into the corner.
8. **Deep Check choreography** — the centerpiece. Show how the cork-board canvas comes alive in real time: pin-drops as sources are reviewed, red-string draws as connections are found, the verdict-stamp slam at the end. Live Activity / Dynamic Island shows abbreviated state on lock screen. This is one of the most distinctive moments in the app — design it to feel premium because of the *choreography*, not chrome.

## Screens to design (full inventory)

### Tab 1 — The Board (today's pinned cases)
- The Board (home) — cork-board feed of cases with daily briefing animation
- The Open Case File — single case with source pins, red-string connections, BiasMeter dossier, verdict area
- Source Dossier (manila-folder sheet) — single article from a single outlet
- Person of Interest profile — outlet detail (bias chart, reliability, ownership, funding, recent stories)

### Tab 2 — Deep Check (hero fact-check tool)
- Deep Check (home) — paste input, recent investigations, suggestions
- First-Pass Verdict — fast on-device result with "Open formal investigation" CTA
- Deep Check In Progress — the cork-board choreography moment + Live Activity / Dynamic Island
- Closed Case (verdict + citations) — verdict stamp + supported / contradicted / missing-context split

### Tab 3 — The Beat (account, stats, settings)
- The Beat (home) — days on the beat, case clearance, Senior Detective status (procedural framing, never gamified)
- Case Clearance — beat balance over time, perspective gaps (NOT a bar chart — see Ground News anti-reference)
- Pinned cases
- Closed Cases (archive with search)
- Beat & Persons of Interest — manage subscriptions, mode toggle
- The Wire (notifications) — granular controls
- Senior Detective — paywall, subscription management
- Persons of Interest directory — global outlet listing
- Settings — accessibility, accounts, privacy, support, "Trust & Methodology" page

### Cross-cutting
- Day One on the Beat (onboarding) — 4 screens: welcome → pick beats → pick mode → notifications → Sign in with Apple
- Share Extension presentation
- Widgets (3 sizes × Top Pin / Beat Balance / Quick Investigation)
- Live Activities (Deep Check progress + breaking case)
- Apple Watch — daily briefing, breaking-case glance, beat balance

## Three flagship flows to design as cohesive sequences

**A) The morning beat (free user, 3 min/day):** Open → Daily Briefing wakes the board → see pinned cases → tap intriguing one → explore source pins / connections → tap a source → return → pin to follow → close. The workflow is the trust-building.

**B) "Is this true?" (the hero flow):** Open → Deep Check → paste → 2-sec first-pass verdict → "Open formal investigation" → cork board comes alive with pin-drops + red-string draws → Live Activity progress on lock screen → verdict stamp slams → tap to see closed case file with citations. The *process* is the product.

**C) Beat balance awareness (the retention hook, never the point):** Sunday morning push (*"Quiet week on the right beat. 4 unread cases."*) → Case Clearance view → "Walk the other beat" → curated balanced board for that day. Filter-bubble breaking should feel like *noticing what you missed in your own investigation* — wry, never preachy.

## Constraints to honor (from PRODUCT.md / DESIGN.md)

- **Accessibility is non-negotiable:** WCAG 2.2 AA + first-class Reduce Motion path (every theatrical animation has a meaningful static / low-motion equivalent that preserves the information). VoiceOver labels in detective vocabulary, not raw element data. Dynamic Type to AX5. Color-blind safe (always shape, label, position cues with color). 44pt touch targets even when pin / photo elements appear smaller.
- **No ads anywhere.**
- **No comments / discussions** in v1.
- **No XP, badges, level-up popups, trophy rooms.** Achievement lives in the archive as case files.
- **Privacy is the brand:** show "investigated on this device" / "never leaves your phone" on first-pass verdict and Beat Balance views.
- **Trust is the brand:** "Why am I seeing this?" affordance on every case; outlet transparency one tap away.

## What I want from you

1. Start with the **signature visual elements** (BiasMeter dossier, Pinned Card / Source Pin, Polaroid, Stamp, Red-String connection, Source Dossier sheet, Daily Briefing animation, Deep Check choreography) — show 2-3 directions per element where ambiguity exists, explain tradeoffs, recommend one.
2. Then design the **three flagship flows** as connected sequences, with the choreography moments storyboarded frame-by-frame.
3. Then fill in the rest of the screen inventory.
4. Use real-feeling content (real outlet names, plausible headlines, wry copy in the PRODUCT.md voice) — placeholder content hides design problems.
5. Show **iPad layouts** and **Apple Watch screens** for relevant surfaces.
6. Provide both **default and Reduce Motion** variants for any screen with theatrical animation — Reduce Motion is a first-class path, not a fallback.
7. Provide light + dark mode (the cork-board palette is warm-mid-tone by default; a dark variant means dimmed-room lighting, NOT inverted colors).

I'm not looking for pixel-perfect production assets yet — I want a strong visual interpretation of THE CRIME BOARD direction that gives the engineering team enough to build from. Iterate with me.
