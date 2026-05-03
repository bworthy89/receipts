// MARK: - FolderFoldRender
//
// View modifier that maps a 0…1 fold progress to the visual state of the
// closing folder. The driving gesture lives in `SourceDossierSheet` on the
// tab strip — keeping it off the body so the user can scroll the excerpt
// without accidentally folding.
//
// Per the 2026-05-03 source-dossier brief §6 + §7 (revised after first
// craft pass — original "fold around bottom edge with anchor: .bottom +
// positive 90° rotation" tipped the folder backward into the screen, which
// reads as "tipping over" not "closing"):
//
//   • Anchor: .bottom (hinge at the spine of the folder).
//   • Rotation: 0 → -45°. Negative, so the top of the folder tips TOWARD
//     the camera as the user pulls down — reads as "the folder cover
//     swinging closed onto the desk in front of you" rather than "the
//     folder leaning over backward."
//   • Capped at 45° instead of 90° so the folder never goes fully
//     perpendicular (which collapses to a 1px line and looks like a glitch).
//   • Perspective: 0.4 (eased from 0.6) — less aggressive foreshortening.
//   • Opacity fades 1 → 0.2 so the folder visibly recedes as it closes.
//
// Reduce Motion: skip the rotation entirely; only fade opacity. AGENTS.md's
// "meaningful Reduce Motion fallback" requirement.

import SwiftUI

struct FolderFoldRender: ViewModifier {
    let progress: CGFloat
    let reduceMotion: Bool

    /// Maximum rotation magnitude (degrees) at full progress. Capped under
    /// 90° so the folder never goes edge-on to the camera.
    private static let maxRotationDegrees: Double = 45

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(1.0 - Double(progress))
        } else {
            content
                .rotation3DEffect(
                    .degrees(Double(progress) * -Self.maxRotationDegrees),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.4
                )
                .opacity(1.0 - Double(progress) * 0.8)
        }
    }
}

// MARK: - FolderFoldGesture
//
// Pure logic for the drag-to-fold gesture. Owns no state — the host view
// holds `progress` + `isClosing` + the dismiss callback and routes the
// drag updates through these helpers. This keeps the math testable and the
// gesture wiring scoped to where it belongs (the host's tab strip).

enum FolderFold {
    /// Drag distance that maps to a full fold (progress = 1.0). Past this
    /// the user feels the fold "clearly happened."
    static let foldHeight: CGFloat = 280

    /// Hard threshold: past this fraction of the fold on release commits
    /// to dismiss; below it, snap back to fully open.
    static let dismissThreshold: CGFloat = 0.4

    /// Compute progress from a downward drag distance. Negative drags
    /// (upward) are clamped to zero so pulling up doesn't open further.
    static func progress(for translationY: CGFloat) -> CGFloat {
        min(max(translationY / foldHeight, 0), 1)
    }

    /// Convenience for the on-release decision: true if the current
    /// progress is past the dismiss threshold.
    static func shouldDismiss(at progress: CGFloat) -> Bool {
        progress >= dismissThreshold
    }
}
