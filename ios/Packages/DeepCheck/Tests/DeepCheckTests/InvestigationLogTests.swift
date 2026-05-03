import Testing
import Foundation
import Models
@testable import DeepCheck

@Suite("InvestigationLog")
struct InvestigationLogTests {

    @Test("Fresh log: should play any case")
    func freshLogPlays() {
        let log = InvestigationLog(store: MemoryStore())
        #expect(log.shouldPlay(caseID: "case-1"))
        #expect(log.shouldPlay(caseID: "case-2"))
    }

    @Test("After markInvestigated, that case skips on revisit")
    func markedCaseSkipsRevisit() {
        let log = InvestigationLog(store: MemoryStore())
        #expect(log.shouldPlay(caseID: "case-1"))
        log.markInvestigated(Self.entry(caseID: "case-1"))
        #expect(!log.shouldPlay(caseID: "case-1"))
    }

    @Test("Other cases still play after one is marked")
    func othersStillPlay() {
        let log = InvestigationLog(store: MemoryStore())
        log.markInvestigated(Self.entry(caseID: "case-1"))
        #expect(!log.shouldPlay(caseID: "case-1"))
        #expect(log.shouldPlay(caseID: "case-2"))
        #expect(log.shouldPlay(caseID: "case-3"))
    }

    /// Re-marking the same case overwrites with the new entry — the schema
    /// is keyed by caseID, last-write-wins. Deliberate: lets tests inject
    /// fixed dates and lets a future "re-investigate" flow update verdict.
    @Test("markInvestigated is idempotent and overwrites")
    func markIdempotentOverwrites() {
        let log = InvestigationLog(store: MemoryStore())
        let first = Self.entry(caseID: "case-1", verdict: .confirmed)
        let second = Self.entry(caseID: "case-1", verdict: .busted)
        log.markInvestigated(first)
        log.markInvestigated(second)

        let stored = log.entry(for: "case-1")
        #expect(stored?.verdict == .busted)
    }

    /// Log persists across InvestigationLog instances backed by the same
    /// store — the screen creates a fresh log per push but the state must
    /// survive.
    @Test("State survives across log instances")
    func surviveAcrossInstances() {
        let store = MemoryStore()
        let log1 = InvestigationLog(store: store)
        log1.markInvestigated(Self.entry(caseID: "case-1"))

        let log2 = InvestigationLog(store: store)
        #expect(!log2.shouldPlay(caseID: "case-1"))
        #expect(log2.shouldPlay(caseID: "case-2"))
        #expect(log2.entry(for: "case-1")?.headline == "Stub headline")
    }

    /// `count` returns the number of investigated cases — drives the
    /// briefing's "ARCHIVE · N FILED" footer.
    @Test("count reflects investigated cases")
    func countReflectsInvestigated() {
        let log = InvestigationLog(store: MemoryStore())
        #expect(log.count == 0)
        log.markInvestigated(Self.entry(caseID: "a"))
        log.markInvestigated(Self.entry(caseID: "b"))
        log.markInvestigated(Self.entry(caseID: "c"))
        #expect(log.count == 3)
    }

    /// `allEntries` returns every archived entry. Used by Archive's
    /// rendering to enumerate the polaroid stack.
    @Test("allEntries returns every entry")
    func allEntriesEnumerates() {
        let log = InvestigationLog(store: MemoryStore())
        log.markInvestigated(Self.entry(caseID: "a", verdict: .confirmed))
        log.markInvestigated(Self.entry(caseID: "b", verdict: .busted))
        let ids = Set(log.allEntries().map(\.caseID))
        #expect(ids == ["a", "b"])
    }

    /// Round-trip preserves all fields. Per the brief §4 schema upgrade —
    /// the log IS the archive's source of truth, so every field has to
    /// survive serialization cleanly.
    @Test("ArchiveEntry round-trips through storage")
    func entryRoundTripsAllFields() {
        let store = MemoryStore()
        let log1 = InvestigationLog(store: store)
        let original = ArchiveEntry(
            caseID: "case-1",
            caseNumber: "CASE-26-0503-007",
            headline: "Some \"quoted\" headline with, commas",
            verdict: .coldCase,
            investigatedOn: Date(timeIntervalSince1970: 1_756_080_000)
        )
        log1.markInvestigated(original)

        let log2 = InvestigationLog(store: store)
        #expect(log2.entry(for: "case-1") == original)
    }

    /// Legacy v2 storage (`["case-a","case-b"]` JSON array) fails open to
    /// empty rather than crashing — same fail-open contract as the v1→v2
    /// (comma → JSON) migration.
    @Test("Legacy [String] storage is treated as empty")
    func legacyArrayIsEmpty() {
        let store = MemoryStore()
        store.set(#"["case-a","case-b"]"#, forKey: "DeepCheck.investigatedCases")

        let log = InvestigationLog(store: store)
        #expect(log.shouldPlay(caseID: "case-a"))
        #expect(log.allEntries().isEmpty)
    }

    /// A corrupt or hand-edited stored value must not crash.
    @Test("Corrupt store value is treated as empty, not crashed")
    func corruptStoreIsEmpty() {
        let store = MemoryStore()
        store.set("not-valid-json{whatever", forKey: "DeepCheck.investigatedCases")

        let log = InvestigationLog(store: store)
        #expect(log.shouldPlay(caseID: "any-id"))

        log.markInvestigated(Self.entry(caseID: "case-1"))
        #expect(!log.shouldPlay(caseID: "case-1"))
    }

    // MARK: - Helpers

    private static func entry(
        caseID: String,
        verdict: Case.Verdict = .confirmed
    ) -> ArchiveEntry {
        ArchiveEntry(
            caseID: caseID,
            caseNumber: "CASE-26-0503-001",
            headline: "Stub headline",
            verdict: verdict,
            investigatedOn: Date(timeIntervalSince1970: 1_756_080_000)
        )
    }
}

private final class MemoryStore: InvestigationLog.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}
