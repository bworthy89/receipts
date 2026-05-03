# Design Brief — receipts `DesignSystem` (v1)

> **Output of `$impeccable shape DesignSystem` on 2026-05-02. Confirmed by user.**
> Hand off to `$impeccable craft DesignSystem` for implementation. See [`/AGENTS.md`](../../../AGENTS.md), [`/PRODUCT.md`](../../../PRODUCT.md), [`/DESIGN.md`](../../../DESIGN.md) for the canonical context this brief sits on top of.

## 1. Feature Summary

The `DesignSystem` SPM package establishes the visual contract every UI surface in receipts inherits: the four-role palette (Cork / Paper / Ink / Evidence + Sepia + Pencil) as palette-only `Color` extensions, two typographic voices (story / file) using Apple's system serif and monospace, an "On-The-Board" elevation modifier set, and five substrate primitives (`CorkBoard`, `PaperSurface`, `MonoLabel`, `StoryText`, `MarkerNote`) that feature packages compose into PinnedCard / Polaroid / Stamp themselves. Ships with a SwiftUI catalog screen for visual review, plus a `MotionMode` helper that becomes the Reduce-Motion convention across the app.

## 2. Primary Developer Action

A feature-package author should be able to render *paper-pinned-to-cork with story text and a mono case number* in <10 lines of SwiftUI using only DesignSystem APIs — no manual color, font, or shadow values. If they reach for `Color(red: …)` or `.font(.system(size: 14))` instead, the system has failed.

## 3. Design Direction

- **Color strategy:** **Restrained** (per PRODUCT.md + DESIGN.md). Cork + Paper + Ink carry every screen; Evidence Red is rationed to ≤10% via the Red-String Rule. Sepia + Pencil are even rarer (archive / disabled only).
- **Theme scene sentence:** *A working detective's desk at 11pm — the cork board lit by a single warm desk lamp, paper evidence pinned in clusters, ink and stamps within arm's reach.* This sentence forces **"Dim Room" dark mode**: the metaphor *is* lighting-aware, so the package ships both light and dark variants of the same warm palette — paper under desk lamp by day, dimmed lamp by night. Standard iOS dark mode (cork → black) is rejected because it collapses the metaphor.
- **Anchor references** (specific objects/products):
  - A literal cork board pinned with handwritten case notes — the source.
  - *Things 3* on iOS — confident system-typography use without losing identity.
  - *Paste* on iOS — paper-on-tinted-substrate tactility done in pure SwiftUI.

## 4. Scope

- **Fidelity:** production-ready. Ships into main, consumed by feature plans.
- **Breadth:** one SPM package + one catalog screen.
- **Interactivity:** tokens are static values; primitives are composable views with no internal state.
- **Time intent:** built to outlast feature plans.

## 5. Layout Strategy (package surface)

```
ios/Packages/DesignSystem/
├── Sources/DesignSystem/
│   ├── Tokens/
│   │   ├── Color+Receipts.swift        Color.cork .paper .ink .evidence .sepia .pencil
│   │   ├── Font+Receipts.swift         StoryText/MonoLabel font helpers (system serif/mono)
│   │   ├── Elevation.swift             pinnedCardShadow / polaroidShadow / liftedShadow modifiers
│   │   └── MotionMode.swift            enum + .motionVariant(full:reduced:) modifier
│   ├── Primitives/
│   │   ├── CorkBoard.swift             Background substrate (Cork Tan; texture lands later)
│   │   ├── PaperSurface.swift          Paper-white card surface with pinnedCardShadow
│   │   ├── MonoLabel.swift             Mono "file voice" label
│   │   ├── StoryText.swift             Serif "story voice" text (display/headline/title/body)
│   │   └── MarkerNote.swift            Marker overlay text (post-its, sticker overlays)
│   └── Catalog/
│       └── DesignSystemCatalog.swift   One scrollable screen showing every token + primitive
└── Tests/DesignSystemTests/
    ├── ColorTokenTests.swift           Light + dark variants resolve to expected OKLCH values
    └── MotionModeTests.swift           motionVariant correctly switches on env value
```

API style: **palette-only, no semantic layer**. `Color.cork`, not `Color.Surface.board`.

## 6. Key States the package handles

- **Light mode (default).** DESIGN.md neighborhoods, lit-by-desk-lamp warmth.
- **Dim Room dark mode.** Same palette, lighting-shifted: cork → darker warm-brown (~OKLCH 35% L), paper → soft warm cream (~OKLCH 80% L), ink → warm near-black, Evidence Red gains a subtle inner glow. Mapped via `Color(light:dark:)`.
- **High Contrast.** Discrete contrast variants; bias indicators always include shape + label cues alongside color.
- **Reduce Motion.** Package itself has no animations, but `MotionMode` helper is the convention all downstream packages use.
- **Dynamic Type.** Every `MonoLabel` + `StoryText` honors Dynamic Type from XS through AX5 (encodes DESIGN.md's "Dynamic Type Honors The File Rule").

## 7. Interaction Model (developer composition)

```swift
import SwiftUI
import DesignSystem

CorkBoard {
    PaperSurface {
        VStack(alignment: .leading, spacing: 8) {
            MonoLabel("CASE #4271 · 21:14")
            StoryText.headline("Senate passes infrastructure bill")
            StoryText.body("23 outlets · 8 left, 11 center, 4 right")
        }
        .padding(16)
    }
    .frame(maxWidth: 320)
}
```

Composition primitives, not turnkey components. Feature packages build their own PinnedCard / Polaroid / Stamp on top.

## 8. Content Requirements

- **Token file naming:** Swift type extensions (`Color+Receipts.swift`) over standalone enums. Concise call sites.
- **Catalog content:** receipts-voice copy throughout — no Lorem Ipsum. Sample headlines: *"Senate passes infrastructure bill after weeks of negotiation"*. MarkerNote samples: `"PERSON OF INTEREST"`, `"COLD CASE"`, `"FOLLOW THE MONEY"`.
- **Documentation:** each token file gets a `// MARK: ` header pulling the relevant rule from DESIGN.md verbatim (e.g. `// MARK: - Cork Tan — substrate of the entire app · Cork-Texture-Never-Decorative Rule`). Code anchors to source of truth.

## 9. Recommended References (for `$impeccable craft DesignSystem`)

- `product.md` — register-specific guidance.
- `colorize.md` — committing concrete OKLCH values from the neighborhoods.
- `typeset.md` — finalizing the system-font Dynamic Type ramp.
- `harden.md` — production-readiness pass (a11y, edge cases) before ship.

## 10. Open Questions (for craft phase to resolve)

- **Concrete OKLCH values.** DESIGN.md gives neighborhoods; craft picks the specific values. Catalog makes iteration cheap.
- **Spacing scale.** Not addressed in DESIGN.md. Suggested default: 4pt-based scale (4, 8, 12, 16, 24, 32, 48). Confirm during craft.
- **Cork texture rendering.** Deferred to when `CorkBoard` is built — `ShaderLibrary` noise composited on Cork Tan.
- **`MotionMode`: `@Environment` value vs. static read in the helper?** Pick whichever keeps consumer call sites cleaner.
- **Catalog: separate target or `#if DEBUG` view inside the library?** Cleaner as a separate target, more overhead. Decide during craft.

---

## Discovery interview transcript (8 Q&A, 3 rounds — 2026-05-02)

For traceability — these answers ground every decision in this brief.

**Round 1 — purpose, scope, success.**
- **Q1** API surface direction → **(b)** Tokens + low-level primitives.
- **Q2** Font commitment → **(b)** Apple system fonts (system serif + monospaced). Revisit at App Store launch.
- **Q3** Cork texture for v1 → **(b)** Subtle SwiftUI-native texture (when crafting CorkBoard); not a system-level token decision.

**Round 2 — primitives, tokens, catalog.**
- **Q4** Primitive set scope → **(a)** Substrate-minimal: 5 primitives + `pinnedCardShadow` modifier.
- **Q5** Token layering → **(a)** Palette only (no semantic layer in v1).
- **Q6** SwiftUI preview catalog → **(a)** Yes, ship a catalog screen.

**Round 3 — direction, constraints.**
- **Q7** Dark mode → **(b)** "Dim Room" dark mode (lighting-shifted same metaphor).
- **Q8** Reduce Motion encoding → **(b)** Typed `MotionMode` enum + `.motionVariant(full:reduced:)` helper.
