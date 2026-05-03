import Testing
import SwiftUI
import Foundation
import Models
@testable import DailyBriefing

/// Smoke tests for the DailyBriefing SwiftUI surface — guard against API
/// regressions where a future commit drops a parameter or changes a public
/// init shape. View construction is enough; visual behavior is covered by the
/// simulator capture pass.
@Suite("DailyBriefing view surface")
@MainActor
struct ViewSmokeTests {

    @Test("TornNote constructs with and without verdict")
    func tornNoteConstructors() {
        let untouched = Case(caseID: "x", caseNumber: "CASE-26-0503-001", headline: "y")
        let stamped = Case(
            caseID: "z",
            caseNumber: "CASE-26-0503-002",
            headline: "y",
            verdict: .confirmed
        )
        let _: any View = TornNote(untouched, position: 1, total: 10)
        let _: any View = TornNote(stamped, position: 2, total: 10)
    }

    @Test("DateStamp constructs with explicit calendar")
    func dateStampConstructor() {
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 5, day: 3)) ?? Date()
        let _: any View = DateStamp(date: date)
    }

    /// DailyBriefingScreen accepts dependency-injected provider, gate, and
    /// clock so tests and previews can drive it deterministically.
    @Test("DailyBriefingScreen constructs with injected dependencies")
    func dailyBriefingScreenConstructor() {
        let _: any View = DailyBriefingScreen()
        let fixedDate = Date()
        let _: any View = DailyBriefingScreen(
            provider: MockProvider(),
            stagingGate: StagingGate(store: InMemoryStore()),
            clock: { fixedDate }
        )
    }
}

/// Test-local store so the smoke test doesn't touch UserDefaults.standard.
private final class InMemoryStore: StagingGate.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}
