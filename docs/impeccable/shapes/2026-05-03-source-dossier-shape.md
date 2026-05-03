# Source Dossier — Design Brief

**Date:** 2026-05-03
**Command:** `$impeccable craft source-dossier`
**Status:** Confirmed by user 2026-05-03
**Skill applicability:** The `impeccable` skill **applies** to the implementation plan.

---

## 1. Feature Summary

A full-viewport manila folder presented over Deep Check when the user taps a source pin. Frames a single source as an *outlet* ("person of interest"), with the source's full excerpt as the dominant block, the outlet name as masthead, and a small mono caption noting how often that outlet appears in the active briefing. Closes by folding shut around its bottom edge as the user drags down.

## 2. Primary User Action

**Read what this outlet actually said.** Everything else (outlet name, appearance count, metadata footer) frames the excerpt — the user came here to see the receipts.

## 3. Design Direction

- **Color strategy:** **Restrained.** Sepia/manila tan as the folder substrate, Paper White interior body, Ink Black serif headline + body, mono Pencil Gray metadata. No Evidence Red on this surface — red is for connection / verdict, neither of which is happening here.
- **Scene sentence:** *"Same reader from the Deep Check, two minutes deeper — they paused on a quoted source, tapped to read the full thing, and the folder opened on the desk in front of them."* Same lighting scene as the briefing/check; light primary, Dim Room dark honored.
- **Named anchors:** real manila case-folder photography, late-edition newspaper masthead typography, *All The President's Men* desk shots.

## 4. Scope

Production-ready single sheet, **lives inside the existing `DeepCheck` package** (no new SPM package — the surface is small enough that a separate package would be overhead, and the feature only opens from Deep Check). Includes:

- `SourceDossierSheet` — full-viewport manila folder presented as a SwiftUI `.sheet` from `DeepCheckScreen` when a source pin is tapped.
- `FolderFoldDismiss` — custom drag-to-close gesture that folds the folder around its bottom edge (3D rotation) instead of slide-down. Reduce Motion fallback: opacity fade.
- Per-outlet appearance count computed at mock-build time from `DeepCheck.MockProvider` (no new provider, no Models promotion, no new mock data).
- `DeepCheckScreen.SourcePin` made tappable; tap raises the sheet with the tapped source bound in.

## 5. Layout Strategy

- **Manila tab strip at the top** — mono outlet label (e.g. "REUTERS · MAY 03 2026") in a sepia-tan tab, slightly off-axis. The tab is also the visible drag handle (touch target extends down ~30pt into the body).
- **Folder body fills the rest of the viewport** — paper-white interior, generous margins.
  - Outlet name as masthead heading (large serif, ~32pt).
  - Mono caption directly under the masthead: *"APPEARS IN 9 OF 10 ACTIVE CASES."*
  - Hairline divider.
  - **Full excerpt as the dominant block** — body serif, ~17pt, generous line-height, capped at 65–75ch. This is the visual centerpiece.
  - Hairline divider.
  - Footer metadata strip — mono case-number, source-ID, published-on date.

## 6. Key States

- **Open (default).** Folder open, content visible. Drag-to-close gesture armed on the tab strip.
- **Mid-fold (during drag).** Folder rotates around its bottom edge as drag proceeds. Past a threshold (~40% of folder height), the sheet auto-completes the fold and dismisses.
- **Released-below-threshold.** Folder springs back to fully open; no dismiss.
- **Reduce Motion fallback.** No 3D fold; standard sheet drag-dismiss + opacity fade.

## 7. Interaction Model

- **Entry:** tap a source pin in `DeepCheckScreen` → `.sheet(item:)` presents `SourceDossierSheet(source:)`. Sheet uses `presentationDetents([.large])` so it covers the screen.
- **Dismiss (custom):** drag down on the manila tab strip. The folder rotates closed around its bottom edge. Past threshold, auto-fold completes and the sheet dismisses; below threshold, snaps back.
- **Dismiss (fallback):** standard sheet drag from anywhere — iOS-default behavior remains as a backstop.
- **Tap outside the tab:** no-op (preserves the body for reading without accidental dismiss).

## 8. Content Requirements

- **Outlet name** — full uppercase mono on the tab, title-case serif as masthead.
- **Appearance caption** — *"APPEARS IN N OF 10 ACTIVE CASES."* (uppercase mono). Computed: number of cases in the current briefing where this outlet appears as a source.
- **Full excerpt** — `Source.excerpt` rendered at body type with no line clamp.
- **Metadata footer** — `caseNumber`, `Source.id`, formatted publication date.
- **VoiceOver:** *"Source dossier: [Outlet]. [Excerpt]. From case [headline]. Drag down to close."*

## 9. Recommended References

- `reference/spatial-design.md` — full-viewport sheet composition with manila tab affordance.
- `reference/motion-design.md` — 3D fold animation + drag-driven progress + Reduce Motion fallback.
- `reference/interaction-design.md` — drag threshold for dismiss.

## 10. Open Questions (resolve during craft)

- **Fold pivot.** Bottom-edge rotation around X axis (folder-tab leans backward as it folds) vs hinge at the top (folder closes "up"). Lean: bottom-edge rotation — matches "closing a real folder on a desk."
- **Tab-pull visual feedback.** During drag the tab might curl up slightly to suggest grip (small 3D rotation on the tab strip itself). Tune at craft.
- **Reduce Motion sheet detent.** Standard `.large` detent + opacity fade; no custom dismiss. Confirmed by C answer (custom only for full-motion).
- **Full-excerpt content length.** Current `Source.excerpt` is ~25 words. The dossier reads as authentic with that length but may feel sparse — consider adding a `fullExcerpt` field to `Source` later; for v1 the existing field is enough.
