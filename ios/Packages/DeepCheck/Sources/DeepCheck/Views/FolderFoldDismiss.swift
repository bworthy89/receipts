// MARK: - FolderFoldDismiss
//
// Drag-to-fold dismiss for the SourceDossierSheet. Per the 2026-05-03 brief
// §6 Key States and §7 Interaction Model:
//   • Drag down on the manila tab strip → folder rotates closed around its
//     bottom edge (3D rotation, X-axis, .bottom anchor).
//   • Past ~40% of folder height: auto-complete the fold + dismiss.
//   • Below threshold on release: spring back to fully open.
//   • Reduce Motion: opacity fade only; no 3D rotation, no fold.
//
// The standard sheet drag-dismiss (iOS-default) is a free fallback — we
// don't disable it. The custom fold path runs in addition, on top of the
// content's own rendering. When the user drags down on the tab area, our
// gesture wins and folds; if they drag from elsewhere, iOS dismisses.
//
// Math: drag.translation.height ∈ [0, foldHeight]. Progress = clamp(t/h, 0, 1).
// Rotation angle = progress * 90° (so progress 1.0 → fully closed flat).
// Past 0.4 progress on release: animate to 1.0 + dismiss. Below: animate
// to 0.

import SwiftUI

struct FolderFoldDismiss<Content: View>: View {
    let onDismiss: @MainActor () -> Void
    let content: Content

    init(onDismiss: @escaping @MainActor () -> Void, @ViewBuilder content: () -> Content) {
        self.onDismiss = onDismiss
        self.content = content()
    }

    @State private var dragOffset: CGFloat = 0
    @State private var isClosing: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Progress 0…1 along the fold. 0 = fully open, 1 = fully closed flat.
    /// Used for both the 3D rotation angle and the fade out.
    private var progress: CGFloat {
        if isClosing { return 1.0 }
        return min(max(dragOffset / Self.foldHeight, 0), 1)
    }

    /// Hard threshold: past 40% of fold height on release commits to dismiss.
    private static var dismissThreshold: CGFloat { 0.4 }

    /// Drag distance that maps to a full fold (progress = 1.0). Tuned so
    /// past ~half the screen height the user feels the fold "clearly happen."
    private static var foldHeight: CGFloat { 320 }

    var body: some View {
        content
            .modifier(FoldEffect(progress: progress, reduceMotion: reduceMotion))
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !reduceMotion else { return }
                guard value.translation.height > 0 else { return }
                dragOffset = value.translation.height
            }
            .onEnded { _ in
                guard !reduceMotion else { return }
                if progress >= Self.dismissThreshold {
                    withAnimation(.easeIn(duration: 0.25)) {
                        isClosing = true
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(260))
                        onDismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - FoldEffect
//
// View modifier that applies the visual fold: 3D rotation around the bottom
// edge + opacity fade. Reduce-Motion path skips the rotation and only fades.

private struct FoldEffect: ViewModifier {
    let progress: CGFloat
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(1.0 - Double(progress))
        } else {
            content
                .rotation3DEffect(
                    .degrees(Double(progress) * 90),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.6
                )
                .opacity(1.0 - Double(progress) * 0.4)
        }
    }
}
