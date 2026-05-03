import Testing
import SwiftUI
import Foundation
import Models
import DeepCheck
@testable import Archive

@Suite("Archive view surface")
@MainActor
struct ViewSmokeTests {

    @Test("ArchivePolaroid constructs from an ArchiveEntry")
    func polaroidConstructor() {
        let entry = ArchiveEntry(
            caseID: "c1",
            caseNumber: "CASE-26-0503-001",
            headline: "x",
            verdict: .confirmed,
            investigatedOn: Date()
        )
        let _: any View = ArchivePolaroid(entry)
    }

    @Test("ArchiveScreen constructs with injected dependencies")
    func screenConstructor() {
        let _: any View = ArchiveScreen(
            log: InvestigationLog(store: InMemoryStore()),
            provider: DeepCheck.MockProvider(),
            onDismiss: {}
        )
    }

    /// Mock seed populates an empty log with 5 entries across 3 days.
    /// Idempotent — re-running on a non-empty log is a no-op (never
    /// overwrites real investigations).
    @Test("Seed adds 5 entries across 3 days when log is empty")
    func mockSeedPopulates() {
        let log = InvestigationLog(store: InMemoryStore())
        ArchiveMockSeed.seedIfEmpty(log)
        #expect(log.allEntries().count == 5)
    }

    @Test("Seed is a no-op when log is already populated")
    func mockSeedIdempotent() {
        let log = InvestigationLog(store: InMemoryStore())
        log.markInvestigated(ArchiveEntry(
            caseID: "real",
            caseNumber: "x",
            headline: "y",
            verdict: .confirmed,
            investigatedOn: Date()
        ))
        ArchiveMockSeed.seedIfEmpty(log)
        #expect(log.allEntries().count == 1)
        #expect(log.entry(for: "real") != nil)
    }
}

private final class InMemoryStore: InvestigationLog.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}
