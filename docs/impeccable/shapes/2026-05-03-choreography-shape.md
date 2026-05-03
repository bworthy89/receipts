# Design Brief — receipts `Choreography` (v1)

> **Output of `$impeccable shape Choreography` on 2026-05-03. Confirmed by user.**
> **Supersedes** [`2026-05-02-choreography-shape.md`](./2026-05-02-choreography-shape.md).
> Hand off to `$impeccable craft Choreography` for implementation. See [`/AGENTS.md`](../../../AGENTS.md), [`/PRODUCT.md`](../../../PRODUCT.md), [`/DESIGN.md`](../../../DESIGN.md).

## What changed from the 2026-05-02 brief

The 2026-05-02 brief landed in PR #3 with two decisions that this brief intentionally reverses:

- **Timing.** 2026-05-02 used a global token enum (`.snap` 200ms / `.deliberate` 450ms / `.languid` 1200ms). 2026-05-03 uses per-motion natural durations (628ms / 920ms / 1380ms / 460ms+120ms kick) because the practical-effect anchor triad demanded different beat lengths for different motions. Per-call duration overrides are still supported.
- **Catalog Reduce Motion.** 2026-05-02 had one screen-level RM toggle. 2026-05-03 has a **per-cell RM sticker-pin** that overrides `accessibilityReduceMotion` in the *catalog cell's* environment. The motion views themselves still always read `MotionMode` from environment with no escape hatch — the override lives in the catalog, not in the API.

Everything else (anchor-preference geometry, dedicated views + thin modifier layer, internal `ReceiptsHaptic` helper, MARK doc style, sound deferred to v1.5, four-motion scope) carries forward from 2026-05-02.

## 1. Feature Summary

THE CRIME BOARD's signature motion system — `PinDrop`, `RedString`, `PolaroidDevelop`, `StampSlam` — built as a standalone `Choreography` SPM package and showcased on a cork-board test-bench `ChoreographyCatalog` screen. Each motion ships with its Reduce Motion variant from day one. The bar is PRODUCT.md's: a screen-reader user, a Reduce Motion user, and a sighted user with motion all describe the same case state in the same detective vocabulary.

## 2. Primary User Action

On the catalog: replay any of the four signature motions on demand and feel — through eye and finger — that they belong to one cohesive physical world. Tap the replay-pin in a cell's corner; the motion retriggers in place, haptics co-timed to the visual landings.

For the package's developer-facing primary action: a feature-package author building Deep Check should be able to mark two pinned source views with `.choreographyAnchor("source-id")`, animate a pin landing on the cork board with `PinDrop`, and draw a red string between the two anchors with `RedString(from: "id-1", to: "id-2")` — without writing a single explicit animation curve, haptic call, or Reduce Motion conditional.

## 3. Design Direction

- **Color strategy** — Restrained (project default). Cork Tan substrate, Paper White artifacts, Ink Black type, Pencil Gray for replay-pin shadow. **Evidence Red appears only inside the red-string motion and the stamp inscription** — never on chrome, never on the toggle-pin, never on the replay control.
- **Theme scene sentence** — *"A senior detective sits at a working cork-board at 11pm and tugs four pinned cards toward themselves to inspect how each one moves; the desk lamp is on, the room is dim, the cork is warm and slightly worn."*
- **Anchor references (motion character)** — the **Practical-Effect triad**: (1) real corkboard pin-and-thumbtack physics, small ricochet then dampened settle, no overshoot; (2) Polaroid SX-70 image develop, slow chemical bloom, scale-compressed; (3) library rubber-stamp slam, hard impact, ink bleed, small screen kick.
- **Inherits from DesignSystem** for color tokens, shadow modifiers, and `MotionVariant`.

## 4. Scope

- **Fidelity** — production-ready.
- **Breadth** — one new SPM package (`Choreography`) plus one new catalog screen (`ChoreographyCatalog`). Four motions × two variants. Plus realistic case-fragment demo composition, replay controls, per-cell RM toggle.
- **Interactivity** — fully interactive. Replay on tap, Reduce Motion override per cell, system setting respected by default.
- **Time intent** — built to be the package the rest of the app composes against for years.

## 5. Layout Strategy (package surface)

```
ios/Packages/Choreography/
├── Sources/Choreography/
│   ├── Tokens/
│   │   └── ChoreographyTiming.swift     Per-motion natural durations + named easing curves
│   ├── Geometry/
│   │   ├── ChoreographyAnchor.swift     .choreographyAnchor("id") modifier
│   │   └── AnchorRegistry.swift         PreferenceKey + env-exposed coordinate map
│   ├── Haptic/
│   │   └── ReceiptsHaptic.swift         Internal Core Haptics helper; effects call into it
│   ├── Effects/
│   │   ├── PinDrop.swift                Drop-with-ricochet + medium impact haptic on landing
│   │   ├── RedString.swift              Stroke-by-stroke draw between two anchors
│   │   ├── PolaroidDevelop.swift        KeyframeAnimator-driven opacity/saturation/blur develop
│   │   └── StampSlam.swift              Rotational arrival + cell-scoped screen kick + heavy impact
│   └── Catalog/
│       └── ChoreographyCatalog.swift    Cork-board test bench (#if DEBUG, sheet-presented)
└── Tests/ChoreographyTests/
    ├── ChoreographyTimingTests.swift    Named durations match brief budgets
    ├── AnchorRegistryTests.swift        PreferenceKey collects + exposes anchors
    └── ReducedVariantTests.swift        Each effect has a reduced variant that compiles + settles
```

API style: **dedicated effect views + thin modifier convenience layer**. Primary call site is the explicit view (`RedString(from: "a", to: "b")`); a small set of modifiers (e.g. `.pinDrop()`) sit on top.

**Depends on DesignSystem** for color tokens, shadow modifiers, and `MotionVariant`.

## 6. Key States

**Per-effect lifecycle**: `armed` (pre-launch / paper-white floating) → `playing` (animating + haptics fire on landings) → `settled` (resting state) → `cancelled` (view disappeared mid-motion; engine cleans up haptics).

**Per-effect Reduce Motion variants** (always read from environment, no opt-out):
- `PinDrop` reduced — instant placement with brief paper-white-to-cork-tan flash, no ricochet, haptic still fires.
- `RedString` reduced — solid line that fades in over 200ms, no stroke animation.
- `PolaroidDevelop` reduced — immediate image reveal, no sepia midpoint, no fade.
- `StampSlam` reduced — labeled stamp appears in place, no rotation, no shake, haptic still fires.

**Haptic states**: PinDrop = `.medium` impact. StampSlam = `.heavy` impact + `.soft` echo. PolaroidDevelop = `.soft` at chemistry-bloom midpoint. RedString = continuous-pattern `twang` at stroke completion.

**Per-call timing override**: each effect accepts an optional `duration:` parameter that overrides its default natural duration. Sequencer code (Deep Check, Daily Briefing wake-up) uses overrides to vary pace.

**Sound**: deferred to v1.5. Each effect accepts `soundEnabled: Bool = false` that does nothing yet — keeps call sites stable.

**Catalog screen (its own state)**:
- *Default (post-mount)* — every motion has run once on appear, then sits resting.
- *On-mount stagger* — ~80ms between cells, top-to-bottom; each runs once for free.
- *Replaying (per cell)* — replay-pin tapped → that cell only resets to armed state, runs the motion. Other cells stay at rest.
- *Reduce Motion (per cell)* — sticker-pin shows ink-black "RM" (overridden) or faded "rm" (system). The cell wraps its motion in a child environment with `accessibilityReduceMotion` set to the user's per-cell choice.
- *Scrolled off-screen* — motions do not animate or schedule haptics.

## 7. Interaction Model

**Catalog**:
- Mount: cells auto-run motions once, staggered ~80ms.
- Replay-pin tap: cell resets to armed, replays ≤1.4s. Pin briefly depresses (40ms scale 0.92) then snaps back. Haptic fires on motion landings, not the tap.
- RM toggle (per cell): pin rotates 8° on tap (the one control allowed to defy Reduce Motion — its job is to BE the toggle). Cell's variant flips for next replay.
- System Reduce Motion: flips every cell's default with it; per-cell overrides are honoured so designers can preview full motion on a Reduce Motion device.
- Scroll: natural vertical, no parallax, no scroll-driven motion.

**Developer composition** (sketch, lives in feature packages, not Choreography):

```swift
import SwiftUI
import DesignSystem
import Choreography

struct DeepCheckCanvas: View {
    @State private var pinned: Set<String> = []
    @State private var connected: [(String, String)] = []
    @State private var verdict: Verdict?

    var body: some View {
        CorkBoard {
            ZStack {
                ForEach(sources, id: \.id) { source in
                    PaperSurface { SourceCardContent(source) }
                        .choreographyAnchor(source.id)
                        .modifier(PinDrop(when: pinned.contains(source.id)))
                }
                ForEach(connected, id: \.0) { (from, to) in
                    RedString(from: from, to: to)
                }
                if let verdict { StampSlam(verdict: verdict) }
            }
        }
    }
}
```

## 8. Content Requirements

**Catalog header** — Display serif: *"The Choreography."* Mono kicker above: `INDEX · 01–04`.

**Cell labels (mono)**:
- `PIN-DROP / 01 · 628ms · ease-out-quart`
- `RED-STRING / 02 · 920ms · ease-out-expo`
- `POLAROID / 03 · 1380ms · custom develop curve`
- `STAMP-SLAM / 04 · 460ms + 120ms kick`

**Demo content (Realistic case fragments)**:
- *Pin-drop*: paper card, headline *"Reuters · Senate vote cleared 51-49 after late objections from FL delegation."* Mono case ID `CASE-2026-0428`. Pin lands top-center.
- *Red-string*: two source-cards. Left `SOURCE / Reuters · 2026-04-29 11:14 ET`, right `SOURCE / Associated Press · 2026-04-29 11:31 ET`. String draws between their pins.
- *Polaroid*: blank polaroid frame develops to a wire-photo placeholder. Mono caption inside the white border: `WIRE / 2026-04-29`.
- *Stamp slam*: paper case-card receives a `CONFIRMED` stamp at +6°, slightly off-center, ink bleed on edges.

**VoiceOver labels** (detective vocabulary, not raw element data):
- Replay-pin: *"Replay pin-drop motion."* / *"Replay red-string draw."* / *"Replay polaroid develop."* / *"Replay stamp slam."*
- Toggle-pin: *"Reduce motion: full. Tap to switch this card to the Reduce Motion variant."* / *"Reduce motion: on. Tap to switch back to full motion."*

**Voice rules**: every label is detective-procedural file voice. **No explanatory marketing copy** on this screen — the screen explains itself by being the thing.

**Anti-goals** — must not feel like:
- iOS-default `.spring()` overshoot.
- Material Design ripples / FAB lifts.
- Game-engine particle bursts (dust on pin-land, sparks on stamp, confetti on verdicts).

**Documentation**: each effect view file leads with a `// MARK: ` header citing the relevant PRODUCT.md / DESIGN.md passage verbatim — same convention as the locked DesignSystem package.

## 9. Recommended References (for craft)

- `motion-design.md` (required — motion-first feature)
- `interaction-design.md` (per-cell controls, focus, VoiceOver)
- `spatial-design.md` (uneven pinned-by-hand layout)
- `typography.md` (mono caption strip + serif header)
- `harden.md` (production-readiness pass — perf budget, multi-effect overlap, Reduce Motion equivalence)

## 10. Open Questions (for craft to resolve)

1. **Haptic engine ownership** — `Choreography` package owns one `ReceiptsHaptic` actor with a single lazy-started `CHHapticEngine`, vs each motion view managing its own. *Recommendation: one engine, lazy-started, owned by the package's internal singleton.*
2. **Develop-curve authoring** — `KeyframeAnimator` for polaroid's opacity/saturation/blur triplet; `Animatable` for the red-string draw progress. *Recommendation: confirmed during craft.*
3. **Stamp screen-shake scope** — shake the cell only, not the whole board. *Recommendation: cell-only — whole-board shake reads like a notification, not a stamp.*
4. **Pin-drop trajectory** — straight-above orthographic entry vs slight off-axis ~15°. *Recommendation: straight-above for v1; revisit if it reads too mechanical.*
5. **Anchor coordinate space** — `.choreographyAnchor` should publish in the catalog cell / CorkBoard's coordinate space via `CoordinateSpace.named("choreography-board")`. Confirm during craft.
6. **First-mount stagger duration** — 80ms between cells is a starting guess; tuned during preview iteration.

---

## Discovery interview transcript (3 rounds, 9 Q&A — 2026-05-03)

**Round 1 — scope, integration, sensory layers.**
- **Q1** Scope of v1 → All four motions (pin-drop, red-string draw, polaroid develop, stamp slam).
- **Q2** First integration target → Standalone cork-board catalog (sibling of `DesignSystemCatalog`).
- **Q3** Sensory layers → Visuals + Haptics. Sound deferred to v1.5.

**Round 2 — catalog framing, motion anchors, timing posture.**
- **Q4** Catalog frame → Cork-board test bench (in-character, never breaks character).
- **Q5** Motion anchor triad → Practical-effect triad (real corkboard pin physics, Polaroid SX-70 develop, library rubber-stamp slam).
- **Q6** Timing posture → Full theatrical (≤ 1.4s per motion). Each motion gets its natural duration; specific values set during craft.

**Round 3 — demo content, RM presentation, anti-goals.**
- **Q7** Demo content per cell → Realistic case fragments.
- **Q8** RM catalog UX → Toggle pin per cell.
- **Q9** Anti-goals (multi-select) → iOS-default `.spring()` overshoot · Material Design ripples / FAB lifts · Game-engine particle bursts.
