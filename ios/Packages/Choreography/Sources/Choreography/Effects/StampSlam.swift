// MARK: - StampSlam · "stamps slam with screen shake" — PRODUCT.md Brand
// Personality · "Stamps are *placed*, not pressed — they appear with a slam
// animation and stay slightly off-axis." — DESIGN.md §5.
//
// Per the 2026-05-03 brief §3 anchor reference: "library rubber-stamp slam —
// hard impact, ink bleed, small screen kick."
//
// 460ms slam + 120ms cell kick. Five overlapping moments:
//   1. Stamp scales from 1.6 → 1.0 (460ms ease-out-expo) — the arrival.
//   2. Stamp fades opacity 0 → 1 (first 100ms) so the late stamp arrival is
//      not invisible-then-pop, but rather present-and-arriving.
//   3. Heavy impact haptic at 280ms — when stamp first contacts paper.
//   4. Cell kick: container offsets in a damped 4-point shake (120ms),
//      starting at 460ms (after the stamp settles).
//   5. Soft echo haptic at 580ms — at kick-end.
//
// Per shape brief §10 open question — confirmed: the kick is **cell-scoped**,
// not whole-board. A whole-board shake reads like a notification; a cell-scoped
// shake reads like a stamp. The shake offset applies to the StampSlam wrapper,
// not to its parent.
//
// Reduce Motion variant: stamp appears in place at full size and opacity, no
// rotation overshoot, no scale, no kick. Heavy haptic still fires — the
// procedural moment (stamp landed) is preserved tactilely.

import SwiftUI
import DesignSystem

public struct StampSlam<Target: View>: View {

    private let inscription: String
    private let angle: Angle
    private let target: Target
    private let delay: Duration
    private let duration: Duration

    /// Slam a verdict stamp onto target content.
    ///
    /// - Parameters:
    ///   - inscription: Stamp text (e.g. `"CONFIRMED"`, `"BUSTED"`,
    ///     `"COLD CASE"`). Set in mono per DESIGN.md §3 (file voice for
    ///     procedural metadata + stamp inscriptions).
    ///   - angle: Final rest rotation of the stamp. Default `.degrees(6)`
    ///     keeps the stamp slightly off-axis per DESIGN.md §5.
    ///   - delay: Delay before the motion starts on mount.
    ///   - duration: Override the natural slam duration. `nil` uses
    ///     `ChoreographyTiming.stampSlam` (460ms). The kick duration
    ///     (`stampSlamKick`, 120ms) is not currently overridable.
    ///   - target: The content the stamp lands on (typically a `PaperSurface`).
    public init(
        inscription: String,
        angle: Angle = .degrees(6),
        delay: Duration = .zero,
        duration: Duration? = nil,
        @ViewBuilder target: () -> Target
    ) {
        self.inscription = inscription
        self.angle = angle
        self.delay = delay
        self.duration = duration ?? ChoreographyTiming.stampSlam
        self.target = target()
    }

    @State private var stampScale: CGFloat = 1.6
    @State private var stampOpacity: Double = 0
    @State private var cellOffset: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.choreographyReducedMotion) private var motionOverride

    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }

    public var body: some View {
        target
            .overlay {
                StampGraphic(inscription: inscription, angle: angle)
                    .scaleEffect(stampScale)
                    .opacity(stampOpacity)
            }
            .offset(cellOffset)
            .task {
                // See PinDrop.swift for the rationale: `try?` swallows
                // CancellationError when the view disappears mid-slam, while
                // `play()` uses `try await` internally so the kick sequence
                // and echo haptic can't fire on a removed view.
                try? await play()
            }
    }

    private func play() async throws {
        try await Task.sleep(for: delay)

        if reduceMotion {
            stampScale = 1.0
            stampOpacity = 1.0
            ReceiptsHaptic.stampImpact()
            return
        }

        let slamSecs = duration.seconds
        let kickSecs = ChoreographyTiming.stampSlamKick.seconds

        // Slam: scale 1.6 → 1.0, opacity 0 → 1, ease-out-expo for the late
        // deceleration that gives "library stamp on a desk" weight.
        withAnimation(ChoreographyTiming.easeOutExpo(duration: .seconds(slamSecs))) {
            stampScale = 1.0
        }
        withAnimation(.linear(duration: slamSecs * 0.22)) {
            stampOpacity = 1.0
        }

        // Heavy haptic at the moment of contact — when the stamp's perceived
        // size matches "now in contact with paper". Tuned to ~60% of the slam
        // duration (~280ms at default), where ease-out-expo has already
        // crossed most of its scale travel.
        try await Task.sleep(for: .seconds(slamSecs * 0.61))
        ReceiptsHaptic.stampImpact()

        // Wait for the slam to fully settle.
        try await Task.sleep(for: .seconds(slamSecs * 0.39))

        // Cell kick — damped 4-point shake. 30ms each, total = 120ms.
        // Travel decreases each step: 6 → 4 → 3 → 0pt.
        let step = kickSecs / 4
        withAnimation(.linear(duration: step)) { cellOffset = CGSize(width: 6, height: -2) }
        try await Task.sleep(for: .seconds(step))
        withAnimation(.linear(duration: step)) { cellOffset = CGSize(width: -4, height: 1) }
        try await Task.sleep(for: .seconds(step))
        withAnimation(.linear(duration: step)) { cellOffset = CGSize(width: 3, height: -1) }
        try await Task.sleep(for: .seconds(step))
        withAnimation(.linear(duration: step)) { cellOffset = .zero }
        try await Task.sleep(for: .seconds(step))

        ReceiptsHaptic.stampEcho()
    }
}

// MARK: - StampGraphic
//
// The visual stamp itself — Evidence-Red mono inscription with a thin border,
// rotated to its rest angle. Rendered at scale 1.0 in its natural footprint;
// StampSlam scales it during the slam.
//
// Per DESIGN.md Stamp direction notes: "verdict graphic with mono inscription,
// slight rotation, ink-bleed edges. Stamps are *placed*, not pressed."

private struct StampGraphic: View {
    let inscription: String
    let angle: Angle

    var body: some View {
        Text(inscription)
            .font(.fileTitle)
            .tracking(2.0)
            .foregroundStyle(Color.evidence)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.evidence, lineWidth: 1.5)
            )
            // Background tint suggesting ink absorbed into paper.
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.evidence.opacity(0.04))
            )
            .rotationEffect(angle)
            .accessibilityElement()
            .accessibilityLabel(Text("Verdict stamp: \(inscription)"))
    }
}
