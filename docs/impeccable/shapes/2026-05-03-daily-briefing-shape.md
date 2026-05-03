# Daily Briefing — Design Brief

**Date:** 2026-05-03
**Command:** `$impeccable craft daily-briefing`
**Status:** Confirmed by user 2026-05-03
**Skill applicability:** The `impeccable` skill **applies** to the implementation plan (UI work, design system surface).

---

## 1. Feature Summary

Daily Briefing is the home surface of receipts: a persistent cork-board landing screen showing 10 cases per day, each rendered as a torn-paper note pinned to cork. It re-stages once per day (lights up + pin-drops + date stamp slam) and otherwise reads as the standing board. Tapping a pin opens Deep Check.

## 2. Primary User Action

**Scan ten torn-paper headlines and pick the case worth investigating today.** Everything else (staging theatre, already-investigated stamps, post-Deep-Check state) decorates that single decision.

## 3. Design Direction

- **Color strategy:** **Restrained** (project default holds). Cork Tan substrate, Paper White torn notes, Ink Black serif headlines, mono case-IDs in Pencil Gray, no Evidence Red on this surface — red is *connection and verdict* and neither has happened yet at the briefing layer. Stamps land in the post-Deep-Check state, which can introduce ink-black or red verdict stamps then.
- **Scene sentence:** *"A news-skeptical adult, mid-coffee at 7:15am, on their phone in bed, soft window light, opening the app to see the day's case board for the first time today."* Forces **light** as the primary target; honor Dim Room dark theme for evening returns.
- **Named anchors:** real detective cork-boards (True Detective S1 office wall), Magnum Photos contact sheets (mono caption discipline on paper), and a torn-paper note actually pinned on a real desk — gravity, weight, hand-torn edge.

## 4. Scope

Production-ready single screen — Daily Briefing only. Mock data (10 case headlines, mock case-IDs, mock investigated/uninvestigated mix). Deep Check is a stub destination (NavigationLink to a placeholder). New SPM package `DailyBriefing` consuming `DesignSystem` + `Choreography` + `Models`. One PR.

## 5. Layout Strategy

Vertical-scrolling cork board. Pins are arranged in **organic chaos within a loose 2-column rhythm** — staggered y-offsets, ±2–4° per-pin rotation, asymmetric horizontal nudge, occasional corner overlap (decorative, never on body text). Date stamp sits slammed into the top-right corner; serial mono case-IDs visible at the top corner of each torn note. Cork texture is the substrate, never wraps a card.

## 6. Key States

- **First-of-day cold launch (staging plays).** Lights-up reveal of cork (low-amplitude brightness ramp on the substrate), date stamp `StampSlam` into the corner, then 10 `PinDrop`s in sequence with a ~80ms stagger — the same `Choreography` motions that shipped in PR #5.
- **Subsequent visit (same day, static).** Board renders fully assembled, no staging. Investigation progress reflected.
- **Already investigated.** Pin shows post-Deep-Check verdict stamp slammed across the torn note (CONFIRMED / BUSTED / COLD CASE), slightly off-axis, ink-bleed edges. Headline still readable, paper still white. (No graying out — sovereignty rule: the user's work is *more* visible after they've done it, not less.)
- **Empty / quiet day.** Cork board with date stamp and one centered torn note: *"Quiet day on the beat. Allegedly."*
- **Loading first roster.** Cork visible, no pins yet, mono caption: *"Pinning today's cases…"*
- **Error.** Single torn note: *"Wire's down. Try again in a minute."* with a discreet retry tap target on the note itself.

## 7. Interaction Model

- **Tap a pin →** push to Deep Check (stub view in this PR — placeholder showing `case_id` and headline only).
- **No pull-to-refresh in v1.** "First-per-day" staging *is* the refresh. Decided to avoid retraining users that swipe-down = more content; that's the broadsheet-app reflex we're rejecting.
- **First-per-day gating** = local-only via `UserDefaults` (last-staged-date). On a fresh install on May 4 morning the staging plays once. App background/foreground within the same day = no replay.
- **Reduce Motion** — the existing per-effect reduced variants from `Choreography` handle this automatically; staging cross-fades pins in instead of dropping them.

## 8. Content Requirements

- **10 mock headlines** — varied topics (politics, science, local, business, weird), each ~40–80 chars, written in real wire-service register (not jokey; the dry humor lives in the *frame*, never the case itself).
- **Mock case-IDs** — mono uppercase, format `CASE-26-0503-001` through `010`. Tracking +5%, ~10pt.
- **Date stamp** — mono, `MAY 03 · 2026`, slammed into top-right at ~−6°, ink-bleed.
- **Empty / loading / error copy** as listed in §6.
- **VoiceOver** — each pin reads as: *"Case [N] of 10. [Headline]. [Investigated CONFIRMED / Investigated BUSTED / Untouched]. Double-tap to open."*

## 9. Recommended References

- `reference/spatial-design.md` — organic-chaos placement on a phone-aspect viewport.
- `reference/motion-design.md` — staging sequencer reusing `Choreography` (PinDrop, StampSlam) with first-per-day gating.
- `reference/interaction-design.md` — pin → Deep Check transition feel.

## 10. Open Questions (resolve during craft)

- **Roster source.** TBD architecturally — for this PR, ship a `DailyBriefingProvider` protocol with a `MockProvider` returning hardcoded headlines; real data binds in a future PR.
- **Investigated persistence.** Deep Check doesn't exist yet, so for the design we ship 3 of 10 pre-marked as investigated in mock data to exercise the post-stamp visual.
- **Pin layout algorithm.** Random within constraints (with seeded RNG so it's stable per day) vs hand-tuned positions for the mock 10. Lean seeded-random; tune the constraints during build.
- **Cork texture.** Static SVG/PNG asset vs procedural Canvas noise. Probably static asset for v1; revisit if it reads flat.
