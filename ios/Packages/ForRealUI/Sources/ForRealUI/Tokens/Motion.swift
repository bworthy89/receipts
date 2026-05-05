import SwiftUI

public struct ForRealMotionToken: Equatable, Sendable {
    public let duration: Double
    public let curve: Animation
}

public enum ForRealMotion {
    /// Fax sheet rising over Home. ~350ms ease-out-quart.
    public static let sheetUp = ForRealMotionToken(
        duration: 0.35,
        curve: .timingCurve(0.165, 0.84, 0.44, 1.0, duration: 0.35) // ease-out-quart
    )

    /// Claim card appearing — fade + slide-up 16pt. ~250ms ease-out-quart.
    public static let claimArrival = ForRealMotionToken(
        duration: 0.25,
        curve: .timingCurve(0.165, 0.84, 0.44, 1.0, duration: 0.25)
    )

    /// Verdict word pushing in from the top. ~280ms ease-out-quint.
    public static let verdictPushIn = ForRealMotionToken(
        duration: 0.28,
        curve: .timingCurve(0.23, 1.0, 0.32, 1.0, duration: 0.28) // ease-out-quint
    )

    /// Reduce-Motion highlight beat — quick color flash to mark arrival.
    public static let reduceMotionHighlight = ForRealMotionToken(
        duration: 0.10,
        curve: .easeOut(duration: 0.10)
    )
}
