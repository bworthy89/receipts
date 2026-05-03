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

    /// The serialized stored value separates IDs with commas. Tests reach
    /// into the store to confirm the format because the brief's "stored as
    /// a comma-separated list" detail is what makes the format inspectable
    /// during dev (vs an opaque array-of-strings UserDefaults key).
    @Test("Serialized form is comma-separated, sorted")
    func serializedShape() {
        let store = MemoryStore()
        let log = InvestigationLog(store: store, key: "test.key")
        log.markPlayed(caseID: "b")
        log.markPlayed(caseID: "a")
        log.markPlayed(caseID: "c")
        #expect(store.string(forKey: "test.key") == "a,b,c")
    }
}

private final class MemoryStore: InvestigationLog.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}
