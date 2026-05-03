// MARK: - PinDrop · "Pins have weight and ricochet" — PRODUCT.md Brand
// Personality · "pin-drops with weight" — DESIGN.md §1.
//
// Per the 2026-05-03 brief §3 anchor reference: "real corkboard pin-and-
// thumbtack physics — small ricochet, dampened settle, no overshoot."
//
// 628ms total · three phases stitched with ease-out-quart curves:
//   1. Descent (520ms, ease-out-quart) — content drops from yOffset = -300
//      to 0. Bulk of the motion; weight comes from the slow late deceleration.
//   2. Ricochet (60ms, linear) — bounces up to yOffset = -12.
//   3. Settle (48ms, ease-out-quart) — returns to yOffset = 0.
//
// Medium impact haptic fires at the end of phase 1 (the second-contact moment).
//
// Reduce Motion variant: instant placement (no descent, no ricochet). Brief
// paper-white-to-cork-tan tint flash communicates "just landed" without
// spatial movement. Haptic still fires — tactile signal preserved.
//
// API shape per the brief: dedicated view + thin `.pinDrop()` modifier.

import SwiftUI
import DesignSystem

public struct PinDrop<Content: View>: View {

    private let content: Content
    private let delay: Duration
    private let duration: Duration

    /// Wrap content in a PinDrop animation.
    ///
    /// - Parameters:
    ///   - delay: Delay before the motion starts on mount. Used by sequencer
    ///     code (catalog stagger, Daily Briefing wake-up) to vary entrance pace.
    ///   - duration: Override the natural duration. `nil` (default) uses
    ///     `ChoreographyTiming.pinDrop` (628ms).
    ///   - content: The view to drop onto the board (typically a `PaperSurface`).
    public init(
        delay: Duration = .zero,
        duration: Duration? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.delay = delay
        self.duration = duration ?? ChoreographyTiming.pinDrop
    }

    @State private var yOffset: CGFloat = -300        // armed: off-screen above
    @State private var flashOpacity: Double = 0       // reduced-variant flash
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.choreographyReducedMotion) private var motionOverride

    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }

    public var body: some View {
        content
            .offset(y: yOffset)
            .overlay {
                if reduceMotion {
                    Color.cork.opacity(flashOpacity)
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
            }
            .task {
                // `try?` here swallows the CancellationError when the view
                // disappears mid-motion. `play()` itself uses `try await` on
                // every sleep so cancellation propagates immediately and the
                // haptic does NOT fire on a removed view.
                try? await play()
            }
    }

    private func play() async throws {
        try await Task.sleep(for: delay)

        if reduceMotion {
            // Land instantly, then flash on/off to signal "just landed".
            yOffset = 0
            withAnimation(.linear(duration: 0.05)) { flashOpacity = 0.55 }
            ReceiptsHaptic.pinDropLanding()
            try await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeOut(duration: 0.150)) { flashOpacity = 0 }
            return
        }

        // Phase split is proportional to total duration so per-call duration
        // overrides scale all three phases coherently.
        let totalSecs = duration.seconds
        let descentSecs = totalSecs * 0.828   // 520/628
        let ricochetSecs = totalSecs * 0.096  // 60/628
        let settleSecs = totalSecs * 0.076    // 48/628

        // Phase 1: descent — most of the motion, late deceleration.
        withAnimation(ChoreographyTiming.easeOutQuart(duration: .seconds(descentSecs))) {
            yOffset = 0
        }
        try await Task.sleep(for: .seconds(descentSecs))
        ReceiptsHaptic.pinDropLanding()

        // Phase 2: ricochet up.
        withAnimation(.linear(duration: ricochetSecs)) { yOffset = -12 }
        try await Task.sleep(for: .seconds(ricochetSecs))

        // Phase 3: settle.
        withAnimation(ChoreographyTiming.easeOutQuart(duration: .seconds(settleSecs))) {
            yOffset = 0
        }
    }
}

// MARK: - .pinDrop() convenience modifier

extension View {

    /// Convenience for the simple "drop me onto the board" case.
    /// Equivalent to `PinDrop { self }` with default delay/duration.
    public func pinDrop(
        delay: Duration = .zero,
        duration: Duration? = nil
    ) -> some View {
        PinDrop(delay: delay, duration: duration) { self }
    }
}
