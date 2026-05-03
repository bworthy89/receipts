// MARK: - ReceiptsHaptic
//
// "Pins have weight and ricochet; polaroids develop; stamps slam with screen
// shake. Every interaction has friction, sound, and satisfaction."
// — PRODUCT.md Brand Personality.
//
// Internal helper. Effects call into it on landings; consumers never see this
// type. Per the 2026-05-03 brief §6: "Haptic states: PinDrop = `.medium`
// impact. StampSlam = `.heavy` impact + `.soft` echo. PolaroidDevelop = `.soft`
// at chemistry-bloom midpoint. RedString = continuous-pattern twang at stroke
// completion."
//
// V1 implementation strategy: `UIImpactFeedbackGenerator` for the discrete
// landings (medium/heavy/soft). The "twang" for RedString is approximated as a
// light→medium pair separated by ~50ms — honest stand-in for a Core-Haptics
// continuous pattern, which lands as a v1.1 follow-up.
//
// Per shape brief §10 open question "Haptic engine ownership" — confirmed:
// generators are constructed per-event (no app-wide engine state to manage in
// v1). UIImpactFeedbackGenerator is cheap to allocate; the `.prepare()` call
// warms the Taptic engine right before play. OS-level haptic prefs govern
// whether anything actually plays.

import SwiftUI

@MainActor
struct ReceiptsHaptic {

    /// Internal style — abstracted from `UIImpactFeedbackGenerator.FeedbackStyle`
    /// so the package compiles on macOS host (test runner) without #if guards
    /// at every call site.
    enum Style: Sendable {
        case light, medium, heavy, soft
    }

    /// `PinDrop` landing — medium impact at the second ricochet contact (~520ms
    /// into the motion).
    static func pinDropLanding() {
        play(.medium)
    }

    /// `RedString` connect — light→medium pair simulating a "twang" at stroke
    /// completion (~860ms into the motion). Replace with CHHapticEngine
    /// continuous pattern in v1.1.
    ///
    /// Throws `CancellationError` if the parent task is cancelled during the
    /// 50ms sleep between `.light` and `.medium`, so a view disappearing
    /// mid-twang doesn't fire the second haptic on a removed view. Callers
    /// inside a structured `.task { try? await ... }` swallow the error at
    /// their boundary.
    static func redStringConnect() async throws {
        play(.light)
        try await Task.sleep(for: .milliseconds(50))
        play(.medium)
    }

    /// `PolaroidDevelop` chemistry-bloom midpoint — soft impact ~700ms in.
    static func polaroidBloom() {
        play(.soft)
    }

    /// `StampSlam` impact — heavy at landing (~300ms in).
    static func stampImpact() {
        play(.heavy)
    }

    /// `StampSlam` echo — soft at kick-end (~420ms in).
    static func stampEcho() {
        play(.soft)
    }

    // MARK: Private — platform dispatch

    private static func play(_ style: Style) {
        #if os(iOS)
        let gen = UIImpactFeedbackGenerator(style: style.uiKit)
        gen.prepare()
        gen.impactOccurred()
        #endif
        // macOS host: no-op. Haptics have no analog on Mac.
    }
}

#if os(iOS)
private extension ReceiptsHaptic.Style {
    var uiKit: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light:  .light
        case .medium: .medium
        case .heavy:  .heavy
        case .soft:   .soft
        }
    }
}
#endif
