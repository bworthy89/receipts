// MARK: - FolderFold (gesture math)
//
// Pure-Swift gesture math for the close drag. The host view (SourceDossierSheet)
// owns the @State and routes drag updates through these helpers. Keeps the
// math testable and the gesture wiring scoped to where it belongs.
//
// Per the 2026-05-03 source-dossier brief §6 + §7 (revised twice during
// craft):
//   v1 — 3D rotation around bottom hinge. Read as "tipping over backward."
//   v2 — Inverted rotation, capped at 45°, eased perspective. Still felt
//        cheap; single-property rotation didn't sell the metaphor.
//   v3 (this) — Sliding manila cover replaces the rotation entirely. The
//        manila tab is the bottom edge of an off-screen cover; pulling
//        down brings the cover down over the body. The visual contrast
//        between sepia (cover) and paper-white (body) carries the
//        "closing" metaphor far better than a single rotation could.
//
// The render itself lives in `SourceDossierSheet.cover`; this file only
// owns the math.

import Foundation
import CoreGraphics

enum FolderFold {
    /// Drag distance that maps to a full close (progress = 1.0).
    static let foldHeight: CGFloat = 280

    /// Hard threshold: past this fraction on release commits to dismiss;
    /// below it, snap back to fully open.
    static let dismissThreshold: CGFloat = 0.4

    /// Compute progress from a downward drag distance. Negative drags
    /// (upward) are clamped to zero so pulling up doesn't open further.
    static func progress(for translationY: CGFloat) -> CGFloat {
        min(max(translationY / foldHeight, 0), 1)
    }

    /// True if the current progress is past the dismiss threshold —
    /// commit on release.
    static func shouldDismiss(at progress: CGFloat) -> Bool {
        progress >= dismissThreshold
    }
}
