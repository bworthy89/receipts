// MARK: - Case
//
// A pin on the daily-briefing board. UI-driving model for now; will map to a
// backend wire format when Deep Check ships and the API surfaces real cases.
//
// Per the 2026-05-03 daily-briefing brief §6:
//   • Headline-only at the briefing layer (no thumbnail, no outlets, no stamp
//     until after Deep Check).
//   • `verdict` is `nil` for uninvestigated cases. After Deep Check, it carries
//     the stamp inscription that will be slammed onto the torn note.
//
// Identifiable via `caseID` so SwiftUI ForEach is stable across re-staging.
// `caseNumber` is the wire-style mono label (`CASE-26-0503-001`); kept distinct
// from the structural identity so display formatting can change without
// breaking diffs.

import Foundation

public struct Case: Sendable, Equatable, Identifiable {
    public let caseID: String
    public let caseNumber: String
    public let headline: String
    public let verdict: Verdict?

    public var id: String { caseID }

    public enum Verdict: String, Sendable, Equatable {
        case confirmed = "CONFIRMED"
        case busted = "BUSTED"
        case coldCase = "COLD CASE"
    }

    public init(
        caseID: String,
        caseNumber: String,
        headline: String,
        verdict: Verdict? = nil
    ) {
        self.caseID = caseID
        self.caseNumber = caseNumber
        self.headline = headline
        self.verdict = verdict
    }
}
