// MARK: - PolaroidDevelop · "polaroids develop" — PRODUCT.md Brand Personality
// · "polaroid develops, slow chemical bloom" — DESIGN.md §1.
//
// Per the 2026-05-03 brief §3 anchor reference: "Polaroid SX-70 image develop —
// slow chemical bloom, scale-compressed."
//
// 1380ms · custom develop curve. Three values animate together as a triplet:
// opacity, saturation, blur. The curve is slow-fast-slow — chemistry takes a
// moment to wake up, then blooms quickly through the midpoint, then settles
// slowly. A separate sepia tint blooms in the middle and fades back to zero,
// hitting Polaroid-Sepia at peak — DESIGN.md §2 says Sepia "signals time depth
// (older, stored, resolved)" and the develop's chemistry phase IS the moment
// of crossing from past (warm sepia) to present (full color).
//
// Soft haptic at midpoint (~690ms into the default duration).
//
// Reduce Motion variant: image appears at full opacity, full saturation, no
// blur, no sepia tint. Soft haptic still fires immediately on appear.
//
// API shape: `PolaroidDevelop { content }` wraps any image-like content. The
// caller decides what develops — a wire photo, a portrait, a stylized scene.
// The package provides the chemistry, not the subject.

import SwiftUI
import DesignSystem

public struct PolaroidDevelop<Content: View>: View {

    private let content: Content
    private let delay: Duration
    private let duration: Duration

    /// Develop content as if it were a Polaroid SX-70 image emerging from
    /// chemistry.
    ///
    /// - Parameters:
    ///   - delay: Delay before the develop starts on mount.
    ///   - duration: Override the natural duration. `nil` uses
    ///     `ChoreographyTiming.polaroidDevelop` (1380ms).
    ///   - content: The image-like view to develop. The wrapper handles all
    ///     opacity/saturation/blur/tint; supply a fully-rendered final image.
    public init(
        delay: Duration = .zero,
        duration: Duration? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.delay = delay
        self.duration = duration ?? ChoreographyTiming.polaroidDevelop
    }

    @State private var trigger: Bool = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.choreographyReducedMotion) private var motionOverride

    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }

    public var body: some View {
        content
            .keyframeAnimator(
                initialValue: PolaroidFrame.armed,
                trigger: trigger
            ) { content, frame in
                content
                    .saturation(frame.saturation)
                    .blur(radius: frame.blur)
                    .opacity(frame.opacity)
                    .overlay {
                        Color.sepia
                            .opacity(frame.sepiaTint)
                            .blendMode(.multiply)
                            .allowsHitTesting(false)
                    }
            } keyframes: { _ in
                // Reduce-Motion vs full-motion branches must live INSIDE each
                // KeyframeTrack — `@KeyframesBuilder` doesn't support if/else
                // at the track level, but `@KeyframeTrackContentBuilder` does.
                let total = duration.seconds

                KeyframeTrack(\.opacity) {
                    if reduceMotion {
                        LinearKeyframe(1.0, duration: 0.0)
                    } else {
                        // Slow-fast-slow: 30% slow start, 40% fast mid, 30% slow finish.
                        CubicKeyframe(0.05, duration: total * 0.30)
                        CubicKeyframe(0.85, duration: total * 0.40)
                        CubicKeyframe(1.00, duration: total * 0.30)
                    }
                }
                KeyframeTrack(\.saturation) {
                    if reduceMotion {
                        LinearKeyframe(1.0, duration: 0.0)
                    } else {
                        CubicKeyframe(0.10, duration: total * 0.30)
                        CubicKeyframe(0.85, duration: total * 0.40)
                        CubicKeyframe(1.00, duration: total * 0.30)
                    }
                }
                KeyframeTrack(\.blur) {
                    if reduceMotion {
                        LinearKeyframe(0.0, duration: 0.0)
                    } else {
                        CubicKeyframe(8, duration: total * 0.30)
                        CubicKeyframe(2, duration: total * 0.40)
                        CubicKeyframe(0, duration: total * 0.30)
                    }
                }
                // Sepia tint rises to ~0.35 across the first 40%, then fades
                // back to 0. Peak sits inside the chemistry-bloom window.
                KeyframeTrack(\.sepiaTint) {
                    if reduceMotion {
                        LinearKeyframe(0.0, duration: 0.0)
                    } else {
                        CubicKeyframe(0.15, duration: total * 0.20)
                        CubicKeyframe(0.35, duration: total * 0.20)
                        CubicKeyframe(0.10, duration: total * 0.30)
                        CubicKeyframe(0.00, duration: total * 0.30)
                    }
                }
            }
            .task {
                try? await Task.sleep(for: delay)
                trigger.toggle()

                if reduceMotion {
                    ReceiptsHaptic.polaroidBloom()
                    return
                }

                // Soft haptic at chemistry-bloom midpoint — 50% through.
                try? await Task.sleep(for: .seconds(duration.seconds * 0.50))
                ReceiptsHaptic.polaroidBloom()
            }
    }
}

// MARK: - Internal: keyframe value type

struct PolaroidFrame {
    var opacity: Double
    var saturation: Double
    var blur: CGFloat
    var sepiaTint: Double

    /// Armed pre-state — invisible, desaturated, blurred, no sepia overlay.
    static let armed = PolaroidFrame(
        opacity: 0,
        saturation: 0,
        blur: 12,
        sepiaTint: 0
    )
}
