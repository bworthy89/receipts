# Design Brief — receipts `Choreography` (v1)

> **SUPERSEDED 2026-05-03** by [`2026-05-03-choreography-shape.md`](./2026-05-03-choreography-shape.md).
> The 2026-05-03 re-shape intentionally reverses two decisions in this brief: the timing token enum (replaced by per-motion natural durations + per-call duration override) and the screen-level Reduce Motion toggle (replaced by a per-cell sticker-pin that overrides `accessibilityReduceMotion` in the catalog cell's environment only — the motion views themselves still always read `MotionMode` with no escape hatch). Additive decisions from this brief (anchor-preference geometry, dedicated views + thin modifier layer, internal `ReceiptsHaptic` helper, MARK doc style, sound deferred to v1.5) carry forward.
> The text below is preserved as historical record. **Do not implement against this file.**

---

> **Output of `$impeccable shape Choreography` on 2026-05-02. Confirmed by user.**
> Hand off to `$impeccable craft Choreography` for implementation. See [`/AGENTS.md`](../../../AGENTS.md), [`/PRODUCT.md`](../../../PRODUCT.md), [`/DESIGN.md`](../../../DESIGN.md), and the sibling [`2026-05-02-designsystem-shape.md`](./2026-05-02-designsystem-shape.md) for the canonical context this brief sits on top of.

## 1. Feature Summary

The `Choreography` SPM package owns the **trust-mechanic motion vocabulary** for receipts. It ships four dedicated effect views — `PinDrop`, `RedString`, `PolaroidDevelop`, `StampSlam` — each with first-class Reduce Motion variants encoded in the view itself (no escape hatch), default haptic feedback baked in, configurable timing via tokens with per-call override, and a SwiftUI-idiomatic anchor-preference architecture for view-to-view geometry. Ships with a playable `ChoreographyCatalog` screen for tactile review during impeccable critique passes. Sound is **deferred to v1.5** — a TODO hook is exposed but no audio assets ship.

## 2. Primary Developer Action

A feature-package author building Deep Check should be able to: (1) mark two pinned source views with `.choreographyAnchor("source-id")`, (2) animate a pin landing on the cork board with `PinDrop(target: paperSurface) { … }`, and (3) draw a red string between the two anchors with `RedString(from: "id-1", to: "id-2")` — without writing a single explicit animation curve, haptic call, or Reduce Motion conditional. If they reach for `withAnimation { … }` or `UIImpactFeedbackGenerator()` directly, the system has failed.

## 3. Design Direction

- **Motion strategy:** spring-physics + ease-out exponential curves only (per DESIGN.md). No bounce, no elastic. Choreography is the only place in the app that defines motion timing tokens — feature packages reach through Choreography for `.snap` / `.deliberate` / `.languid`.
- **Theme inherits from DesignSystem.** Choreography doesn't paint colors; it animates DesignSystem-painted views (paper drops, evidence-red strings, ink stamps). Inherits Cork-Tan substrate awareness for shadow rendering during pin lift.
- **Anchor references** (specific objects/actions, not adjectives):
  - **Polaroid OneStep** instant-film develop curve — slow asymmetric ink-fade-in, midpoint-warm-shift through Polaroid Sepia.
  - **Notary stamp slamming on a desk** — the rotational arrival, ink-bleed at the edge, brief screen settle.
  - **A pushpin landing in cork** — small dampened ricochet, weight-of-thumb impact haptic.
  - **Drawing red yarn between two pinned receipts by hand** — visible stroke, slight sag at midpoint, lays-on-cork shadow underneath.

## 4. Scope

- **Fidelity:** production-ready. The trust mechanic is the product per PRODUCT.md; this package is core, not polish.
- **Breadth:** one SPM package + one playable catalog screen. Four effect views, one timing tokens enum, one anchor-preference system, one haptic helper.
- **Interactivity:** stateful effect views with their own SwiftUI lifecycles. Catalog is fully playable.
- **Time intent:** built to be the package the rest of the app composes against for years.

## 5. Layout Strategy (package surface)

```
ios/Packages/Choreography/
├── Sources/Choreography/
│   ├── Tokens/
│   │   └── MotionTiming.swift          enum .snap (200ms) .deliberate (450ms) .languid (1200ms)
│   ├── Effects/
│   │   ├── PinDrop.swift               Animated drop with ricochet + medium impact haptic
│   │   ├── RedString.swift             Stroke-by-stroke draw between two anchors
│   │   ├── PolaroidDevelop.swift       Ink-fade-in image reveal through Sepia midpoint
│   │   └── StampSlam.swift             Rotational arrival + screen shake + heavy impact haptic
│   ├── Geometry/
│   │   ├── ChoreographyAnchor.swift    .choreographyAnchor("id") view modifier
│   │   └── AnchorRegistry.swift        PreferenceKey + env-exposed coordinate map
│   ├── Haptic/
│   │   └── ReceiptsHaptic.swift        Internal helper; effect views call into it
│   └── Catalog/
│       └── ChoreographyCatalog.swift   Playable showcase: tap to replay each effect
└── Tests/ChoreographyTests/
    ├── MotionTimingTests.swift         Token values + Reduce Motion override resolves to .snap
    ├── ReducedVariantTests.swift       Each effect has a Reduce Motion variant that conveys the same info
    └── AnchorRegistryTests.swift       PreferenceKey collects + exposes anchors correctly
```

API style: **dedicated effect views + thin modifier convenience layer**. Primary call site is the explicit view (`RedString(from: "a", to: "b")`); a small set of modifiers (e.g. `.pinDrop()` for the simple "drop me onto the board" case) sit on top.

**Depends on DesignSystem** for: Color tokens (Evidence Red for the string, Ink Black for the stamp), shadow modifiers (lifted-during-drag), `MotionMode` env value (the Reduce Motion source of truth).

## 6. Key States the package handles

- **Per-effect lifecycle:** `idle` (pre-launch) → `playing` (animating) → `done` (settled). Catalog can re-trigger; consumers can observe completion via callback.
- **Reduce Motion variants** (encoded in each effect view, no opt-out):
  - `PinDrop` → instant placement with subtle paper-white-to-cork-tan flash, no ricochet, haptic still fires.
  - `RedString` → solid line that fades in over `.snap` (200ms), no stroke animation.
  - `PolaroidDevelop` → immediate image reveal, no sepia midpoint, no fade.
  - `StampSlam` → labeled stamp graphic appears in place, no rotation, no shake, haptic still fires.
- **Haptic states:** `PinDrop` = `.medium`, `StampSlam` = `.heavy`, `RedString` = none, `PolaroidDevelop` = `.soft` at completion. OS-level user haptic prefs respected automatically.
- **Per-call timing override:** `PinDrop(timing: .snap)` overrides default `.deliberate`. Sequencer code (Deep Check) uses overrides to vary pace within a sequence.
- **Sound:** disabled in v1; effect views accept a `soundEnabled: Bool = false` parameter that does nothing yet — keeps call sites stable when sound lands in v1.5.

## 7. Interaction Model (developer composition)

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

                if let verdict {
                    StampSlam(verdict: verdict)
                }
            }
        }
    }
}
```

The Deep Check sequencer (lives in `DeepCheckFeature`, not here) triggers state changes; Choreography's effect views observe state and animate themselves.

## 8. Content Requirements

- **Catalog content:** receipts-voice copy. PinDrop sample = paper card titled `"REUTERS · Senate vote"`. RedString sample connects two cards titled `"REUTERS"` and `"AP"`. PolaroidDevelop sample uses a placeholder photo with caption `"PERSON OF INTEREST"`. StampSlam sample cycles through `CONFIRMED` / `BUSTED` / `COLD CASE`.
- **Catalog interaction:** each effect has a "Play" button + a "Toggle Reduce Motion" toggle so reviewers can compare full + reduced variants side-by-side without leaving the screen.
- **Documentation:** each effect view file leads with a `// MARK: ` header citing the relevant PRODUCT.md / DESIGN.md passage verbatim (e.g. `// MARK: - PinDrop · "Pins have weight and ricochet" — PRODUCT.md Brand Personality · "pin-drops with weight" — DESIGN.md §1`).

## 9. Recommended References (for `$impeccable craft Choreography`)

- `product.md` — register-specific guidance.
- `animate.md` — purposeful animation, motion-conveys-state.
- `harden.md` — production-readiness pass before ship (perf budget, edge cases, multiple-simultaneous-effects behavior).

## 10. Open Questions (for craft phase to resolve)

- **Specific durations.** `.snap` / `.deliberate` / `.languid` get concrete millisecond values during craft based on what feels right in the catalog.
- **Spring physics tuning.** SwiftUI offers `.spring(response: …, dampingFraction: …)`; the right values for "weighty pin-drop" come from playing with the catalog.
- **PolaroidDevelop visual approach.** Three candidates: SwiftUI `Canvas` over the image, `ShaderLibrary` color filter, or pre-rendered intermediate frames. Pick when crafting.
- **`StampSlam` screen shake implementation.** Apply `.offset(x: shakeX, y: shakeY)` to a parent container, or use a custom `GeometryEffect`? Latter is cleaner; former is simpler.
- **Anchor registry coordinate space.** `.choreographyAnchor` should publish in CorkBoard's coordinate space — confirm during craft whether SwiftUI's `CoordinateSpace.named("choreography-board")` is the right approach.
- **Catalog target shape.** Same question as DesignSystem: separate target or `#if DEBUG` view inside the library?

---

## Discovery interview transcript (8 Q&A, 3 rounds — 2026-05-02)

**Round 1 — purpose, surface, scope-in-scope.**
- **Q1** API surface direction → **(b)** Dedicated effect views (with thin modifier convenience layer for simple cases).
- **Q2** Bundle scope for v1 → **(a)** Core 4: pin-drop, red-string-draw, polaroid-develop, stamp-slam. Daily Briefing reveal + dossier-folder + lifted-while-dragging defer to feature packages.
- **Q3** Sound + haptic → **(c)** Visual + haptic in this package; sound deferred to v1.5 with a stable `soundEnabled` API hook.

**Round 2 — geometry, timing, catalog.**
- **Q4** RedString geometry → **(a)** Anchor preferences (SwiftUI-idiomatic, `.choreographyAnchor("id")` modifier on each pinnable view, env-exposed coordinate map).
- **Q5** Animation timing → **(c)** Tokens (`.snap` / `.deliberate` / `.languid`) + per-call override. Reduce Motion variants pick `.snap` for everything.
- **Q6** Catalog → **(a)** Ship `ChoreographyCatalog`, playable, with Reduce Motion toggle.

**Round 3 — accessibility, haptic.**
- **Q7** Reduce Motion enforcement → **(a)** Each effect view ALWAYS reads `MotionMode` from environment and switches internally. No escape hatch — package is incapable of violating PRODUCT.md's accessibility contract.
- **Q8** Haptic API → **(a)** Always-on with sensible defaults baked in. OS-level haptic prefs handle accessibility automatically.
