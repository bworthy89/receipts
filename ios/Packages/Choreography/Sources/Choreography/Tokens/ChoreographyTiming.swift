// MARK: - ChoreographyTiming
//
// Per-motion natural durations + named easing curves.
//
// Per the 2026-05-03 shape brief §6: "each effect accepts an optional
// `duration:` parameter that overrides its default natural duration. Sequencer
// code (Deep Check, Daily Briefing wake-up) uses overrides to vary pace."
//
// Per the 2026-05-03 brief §3 anchor references — Practical-Effect triad:
// real corkboard pin physics, Polaroid SX-70 develop, library rubber-stamp
// slam. Each motion has its own beat length; there is no global timing token
// because the four motions don't share a tempo.
//
// Per impeccable motion-design.md: ease-out exponential curves only —
// no bounce, no elastic. PRODUCT.md anti-reference: "iOS-default `.spring()`
// overshoot." These curves explicitly avoid SwiftUI's `.spring()` defaults.

import SwiftUI

public enum ChoreographyTiming {

    // MARK: Per-motion natural durations
    //
    // Hardcoded per the brief §8 cell labels. Each is the *full theatrical*
    // posture — Reduce Motion variants override to .reducedDuration below.

    /// `PinDrop` — 628ms · ease-out-quart. Pin enters from above, lands on cork
    /// with a small dampened ricochet, settles. Haptic medium-impact at landing.
    public static let pinDrop: Duration = .milliseconds(628)

    /// `RedString` — 920ms · ease-out-expo. String draws stroke-by-stroke
    /// between two anchors. Continuous-pattern haptic twang at completion.
    public static let redString: Duration = .milliseconds(920)

    /// `PolaroidDevelop` — 1380ms · custom develop curve (slow start, fast
    /// chemistry-bloom mid, slow finish). Soft haptic pulse at midpoint.
    public static let polaroidDevelop: Duration = .milliseconds(1380)

    /// `StampSlam` — 460ms slam + 120ms cell-scoped screen kick. Heavy impact
    /// haptic at landing + soft echo at kick-end.
    public static let stampSlam: Duration = .milliseconds(460)

    /// `StampSlam` — kick duration (cell-scoped shake after the slam settles).
    public static let stampSlamKick: Duration = .milliseconds(120)

    /// Reduce Motion default — replaces the natural duration when
    /// `accessibilityReduceMotion` is on. 200ms crossfade, no spatial movement.
    /// Per the 2026-05-02 brief Q5 (carried forward): "Reduce Motion variants
    /// pick `.snap` for everything."
    public static let reducedDuration: Duration = .milliseconds(200)

    // MARK: Curves
    //
    // Cubic-bezier control points lifted from impeccable/motion-design.md.
    // SwiftUI's Animation.timingCurve takes the four control-point coordinates;
    // these are the same "ease-out-quart" / "ease-out-expo" web designers use
    // when they want refined deceleration without bounce.

    /// ease-out-quart — refined, recommended default.
    /// `cubic-bezier(0.25, 1, 0.5, 1)` — smooth deceleration, no overshoot.
    /// Used by `PinDrop` for the primary descent + ricochet damping.
    public static func easeOutQuart(duration: Duration) -> Animation {
        .timingCurve(0.25, 1.0, 0.5, 1.0, duration: duration.seconds)
    }

    /// ease-out-expo — snappy, confident.
    /// `cubic-bezier(0.16, 1, 0.3, 1)` — fast initial movement, late settle.
    /// Used by `RedString` so the stroke catches the eye quickly then settles.
    public static func easeOutExpo(duration: Duration) -> Animation {
        .timingCurve(0.16, 1.0, 0.3, 1.0, duration: duration.seconds)
    }

    /// ease-in-out — for symmetric there-and-back motions.
    /// `cubic-bezier(0.65, 0, 0.35, 1)`. Used internally by the replay-pin
    /// depress-and-snap-back micro-interaction in the catalog.
    public static func easeInOut(duration: Duration) -> Animation {
        .timingCurve(0.65, 0.0, 0.35, 1.0, duration: duration.seconds)
    }
}

// MARK: - Duration → seconds bridge
//
// SwiftUI's `Animation` API takes `TimeInterval` (Double seconds), not Swift's
// `Duration`. Keep the public surface in `Duration` (typed, Sendable, the
// modern default) and convert at the boundary.

extension Duration {
    /// Total seconds as Double. Used internally to bridge to SwiftUI's
    /// `Animation.timingCurve(_:_:_:_:duration:)`, which still takes Double.
    var seconds: Double {
        let parts = components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}
