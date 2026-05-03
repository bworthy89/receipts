# Deep Check — Design Brief

**Date:** 2026-05-03
**Command:** `$impeccable craft deep-check`
**Status:** Confirmed by user 2026-05-03
**Skill applicability:** The `impeccable` skill **applies** to the implementation plan (UI work, design system surface).

---

## 1. Feature Summary

Deep Check is the immersive investigation surface for a single case: 5 source pins arranged hub-and-spoke around a central headline, red strings drawn from each source back to the center, polaroids developing on each source, and a verdict stamp slamming the conclusion. Below the fold sits an evidence dossier of pulled quotes from the sources. Entered via fullScreenCover from a Daily Briefing pin tap.

## 2. Primary User Action

**Watch the work happen, then read the receipts.** The 4-motion sequence is the trust mechanic — it's not decoration. After it lands, the user can scroll down to read the source quotes that backed the verdict.

## 3. Design Direction

- **Color strategy:** still **Restrained** project-wide, but this is the screen where **Evidence Red gets its rare moment** — 5 red strings on a single canvas, plus a verdict stamp inscribed in red. That's still inside the Red-String Rule (≤10%); the rarity stays the point.
- **Scene sentence:** *"Same news-skeptical reader from the briefing, now leaning into one specific case for 30 seconds — coffee getting cold, attention focused, watching the app interrogate sources in front of them."* Light primary, Dim Room dark honored.
- **Named anchors:** *Spotlight* (2015) newsroom whiteboard scenes, real investigative-journalism wall maps (Pulitzer-nominated boards), and a manila-folder file desk in late-evening light.

## 4. Scope

Production-ready single screen. New SPM package `DeepCheck` consuming `DesignSystem` + `Choreography` + `Models`. Includes:

- `DeepCheckScreen` with the full 4-motion choreographed sequence + evidence dossier below the fold
- `DeepCheckProvider` protocol + `MockProvider` with canned 5-source investigation data per case
- `InvestigationLog` (per-case version of `StagingGate`) — first tap plays the sequence, subsequent taps skip to settled
- **Architecture move:** promote `Case` from `DailyBriefing` to `Models` so both packages share the type without a cycle
- **Wire-up:** `DailyBriefingScreen.pin` switches from `NavigationLink → DeepCheckPlaceholder` to `fullScreenCover → DeepCheckScreen`; the placeholder is deleted

## 5. Layout Strategy

Vertical-scrolling cork board, two zones:

- **Above the fold (the investigation board):** central case pin (torn-paper, slightly larger than the briefing pins) at ~upper-third of the viewport. 5 source pins (manila-folder-tab cards: small manila tab at top with the outlet name in mono, paper-white body with a ~25-word excerpt) fanning around the central pin in an organic radial arrangement (not strict-circle — varies in distance and angle for cork-board feel). 5 red strings drawn from each source back to the central pin. Verdict stamp slammed across or beside the central pin at the end.
- **Below the fold (the dossier):** "PULLED QUOTES" mono section heading, then 5 evidence rows — each a serif quote with mono attribution ("— Reuters, May 3 2026"). Optional: case-summary paragraph at the very bottom.

Cork is the substrate for both halves; the dossier is paper cards laid against cork, not a separate sheet.

## 6. Key States

- **Investigation playing (first tap, 5–7s sequence).** Cork lights up → headline `PinDrop` (center) → 5 source `PinDrop`s staggered ~80ms → all 5 `PolaroidDevelop`s in parallel (1.4s) → 5 `RedString`s drawn with 80ms stagger (~1.3s total) → verdict `StampSlam`. Total budget ~5.5s. User can scroll during, but motion is the focal event.
- **Settled (revisit, skip).** All pins, polaroids, strings, and verdict already in place. No animation. User can tap a source pin to inspect (deferred to a future PR — for v1, source pins are not interactive).
- **Loading.** Mono caption: *"Pulling the file…"* — short-lived (mock provider returns instantly; matters when the real backend lands).
- **Error.** Single torn note on cork: *"Couldn't pull this file. Wire's down."* with retry tap.

## 7. Interaction Model

- **Entry:** tapping a pin in `DailyBriefingScreen` triggers `fullScreenCover` presenting `DeepCheckScreen(case:)`.
- **Dismiss:** swipe-down OR a small ink-style "close" affordance in the top-left (a paper-clip glyph or mono "× CLOSE" — the brief is ambiguous on iOS-default vs custom; lean custom).
- **Replay decision:** `InvestigationLog` keyed by `caseID` + `UserDefaults`. First tap plays; subsequent skip. Cleared at fresh-install only.
- **Reduce Motion:** Choreography's existing per-effect reduced variants handle this. The total sequence is shorter (snap variants ~200ms each, all in parallel = ~250ms total).
- **Tapping a source pin:** no-op in v1 (deferred). Source dossier is the next surface and the next PR.

## 8. Content Requirements

- **Per-case mock data:** 5 sources (Reuters, AP, BBC, NPR + 1 case-relevant local) with ~25-word wire-service excerpts each. 5 evidence quotes pulled from those sources (not necessarily 1:1 mapping — could be "two sources echo the same framing").
- **Verdict distribution across the 10 briefing cases:** ~4 CONFIRMED, ~3 BUSTED, ~3 COLD CASE so all three verdict variants are exercised by tapping different cases.
- **Close affordance copy:** mono "× CLOSE" or graphic.
- **Loading copy:** "Pulling the file…"
- **Error copy:** "Couldn't pull this file. Wire's down." (mirrors the briefing's wire-service voice)
- **VoiceOver:** sequence-aware. Each phase announces ("Five sources collected. Cross-references drawn. Verdict: CONFIRMED.") rather than narrating per-pin.

## 9. Recommended References

- `reference/spatial-design.md` — radial hub-and-spoke composition on phone-aspect.
- `reference/motion-design.md` — sequencer choreography across 4 motion types.
- `reference/interaction-design.md` — fullScreenCover entry + custom dismiss affordance.
- `reference/ux-writing.md` — wire-service register for source excerpts and verdicts.

## 10. Open Questions (resolve during craft)

- **Hub-and-spoke geometry on phone-portrait.** True radial circle vs vertical-arc-fan vs scattered-around-headline. Lean: scattered-with-implied-radial — not strict.
- **Central headline pin shape.** Same torn-note as briefing (continuity) vs upgraded form (e.g., bigger, polaroid-with-no-image). Lean: same torn-note, slightly larger.
- **Reduce-Motion source-pin layout.** Probably static positions with cross-fade in.
- **Polaroid placeholder content.** Real wire photos are out of scope; placeholder is a cork-tan rectangle with the outlet logo in mono. Tune at craft.
- **`Case` migration into `Models`.** Touches DailyBriefing's import statements. Done as part of this PR.
