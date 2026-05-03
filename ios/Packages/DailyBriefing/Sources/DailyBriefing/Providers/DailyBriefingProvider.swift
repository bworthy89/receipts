// MARK: - DailyBriefingProvider
//
// Source of the day's case roster. Protocol so the screen doesn't know whether
// the cases came from a fixture, a backend, or an on-device model.
//
// Per the 2026-05-03 brief §10 open question: roster source is TBD
// architecturally. This protocol is the seam where the eventual real source
// lands without touching the screen code.
//
// `roster(for:)` takes a calendar date so the provider can serve a stable
// roster within a day and rotate at midnight. The Date is the user's local
// "today" — the screen does not pass UTC.

import Foundation

public protocol DailyBriefingProvider: Sendable {
    /// Returns the cases for the given local day. Implementations must return
    /// the same roster for the same date within a session — the screen relies
    /// on stable identity across re-renders.
    func roster(for day: Date) async throws -> [Case]
}

/// Convenience: the briefing brief asks for exactly 10 cases per day. The
/// protocol doesn't enforce 10 (a future provider might surface fewer on a
/// quiet day), but the design target is 10. Documented here, not as a
/// precondition.
public enum DailyBriefingTarget {
    public static let pinsPerDay = 10
}
