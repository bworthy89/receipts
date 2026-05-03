import Testing
import Foundation
@testable import DeepCheck

@Suite("InvestigationLog")
struct InvestigationLogTests {

    @Test("Fresh log: should play any case")
    func freshLogPlays() {
        let store = MemoryStore()
        let log = InvestigationLog(store: store)
        #expect(log.shouldPlay(caseID: "case-1"))
        #expect(log.shouldPlay(caseID: "case-2"))
    }

    @Test("After markPlayed, that case skips on revisit")
    func markedCaseSkipsRevisit() {
        let store = MemoryStore()
        let log = InvestigationLog(store: store)
        #expect(log.shouldPlay(caseID: "case-1"))
        log.markPlayed(caseID: "case-1")
        #expect(!log.shouldPlay(caseID: "case-1"))
    }

    @Test("Other cases still play after one is marked")
    func othersStillPlay() {
        let store = MemoryStore()
        let log = InvestigationLog(store: store)
        log.markPlayed(caseID: "case-1")
        #expect(!log.shouldPlay(caseID: "case-1"))
        #expect(log.shouldPlay(caseID: "case-2"))
        #expect(log.shouldPlay(caseID: "case-3"))
    }

    @Test("markPlayed is idempotent")
    func markIdempotent() {
        let store = MemoryStore()
        let log = InvestigationLog(store: store)
        log.markPlayed(caseID: "case-1")
        log.markPlayed(caseID: "case-1")
        #expect(!log.shouldPlay(caseID: "case-1"))
    }

    /// Log persists across InvestigationLog instances backed by the same
    /// store — the screen creates a fresh log per push but the state must
    /// survive.
    @Test("State survives across log instances")
    func surviveAcrossInstances() {
        let store = MemoryStore()
        let log1 = InvestigationLog(store: store)
        log1.markPlayed(caseID: "case-1")

        let log2 = InvestigationLog(store: store)
        #expect(!log2.shouldPlay(caseID: "case-1"))
        #expect(log2.shouldPlay(caseID: "case-2"))
    }

    /// The serialized stored value is a JSON-encoded `[String]`, sorted
    /// for stable dev-time inspection. JSON rather than a delimiter-
    /// separated list so the storage doesn't break if a real provider ever
    /// uses a caseID containing the delimiter.
    @Test("Serialized form is JSON-encoded, sorted")
    func serializedShape() {
        let store = MemoryStore()
        let log = InvestigationLog(store: store, key: "test.key")
        log.markPlayed(caseID: "b")
        log.markPlayed(caseID: "a")
        log.markPlayed(caseID: "c")
        #expect(store.string(forKey: "test.key") == #"["a","b","c"]"#)
    }

    /// CaseIDs containing commas, brackets, quotes, or other special chars
    /// must round-trip cleanly. The pre-fix comma-separated format silently
    /// corrupted IDs containing commas — JSON encoding is robust.
    @Test("CaseIDs with special characters round-trip cleanly")
    func specialCharsRoundTrip() {
        let store = MemoryStore()
        let weirdIDs = [
            "case,with,commas",
            "case\"with\"quotes",
            "case[with]brackets",
            "case\\with\\backslashes",
            "case-with-newlines\nand-tabs\t",
        ]

        do {
            let log = InvestigationLog(store: store, key: "test.key")
            for id in weirdIDs {
                log.markPlayed(caseID: id)
            }
        }

        // Re-create from the same store to confirm persistence + parse path.
        let log2 = InvestigationLog(store: store, key: "test.key")
        for id in weirdIDs {
            #expect(!log2.shouldPlay(caseID: id), "expected \(id) to be marked played")
        }
        #expect(log2.shouldPlay(caseID: "untouched-id"))
    }

    /// A corrupt store value (legacy comma-separated, hand-edited, etc.)
    /// must not crash; the log treats it as empty and rebuilds from there.
    @Test("Corrupt store value is treated as empty, not crashed")
    func corruptStoreIsEmpty() {
        let store = MemoryStore()
        store.set("not-valid-json,whatever", forKey: "test.key")

        let log = InvestigationLog(store: store, key: "test.key")
        #expect(log.shouldPlay(caseID: "any-id"))

        // Marking a new case should overwrite with valid JSON; subsequent
        // reads round-trip.
        log.markPlayed(caseID: "case-1")
        #expect(!log.shouldPlay(caseID: "case-1"))
    }
}

private final class MemoryStore: InvestigationLog.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}
