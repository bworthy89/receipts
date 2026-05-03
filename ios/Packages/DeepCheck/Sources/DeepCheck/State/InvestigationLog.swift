// MARK: - InvestigationLog
//
// Per-case played-already gate. Decides whether `DeepCheckScreen` should play
// the full 4-motion sequence (first investigation of this case) or skip
// straight to the settled board (revisit).
//
// Per the 2026-05-03 brief §7 Interaction Model:
//   "Replay decision: InvestigationLog keyed by caseID + UserDefaults. First
//    tap plays; subsequent skip. Cleared at fresh-install only."
//
// Pure logic, testable on the macOS host: takes a key-value store rather
// than reading UserDefaults.standard directly. The default `live()` factory
// wires it to the real one.
//
// Storage shape: a comma-separated list of investigated caseIDs in a single
// UserDefaults string. Comma-separated rather than `array(forKey:)` so the
// Store protocol stays string-keyed and matches `StagingGate`'s pattern.

import Foundation

public final class InvestigationLog: @unchecked Sendable {

    /// Storage abstraction. UserDefaults satisfies it; tests inject a memory
    /// store. (Same shape as `StagingGate.Store`, intentionally — these
    /// could share a typealias once a third caller appears.)
    public protocol Store: Sendable {
        func string(forKey key: String) -> String?
        func set(_ value: String, forKey key: String)
    }

    private let store: any Store
    private let key: String

    public init(
        store: any Store,
        key: String = "DeepCheck.investigatedCaseIDs"
    ) {
        self.store = store
        self.key = key
    }

    /// Returns true if the given case has not yet been investigated; the
    /// screen should play the full sequence. Returns false on revisit; the
    /// screen should skip to the settled board.
    public func shouldPlay(caseID: String) -> Bool {
        !investigatedSet().contains(caseID)
    }

    /// Records that a case has been investigated. Idempotent — calling twice
    /// for the same caseID is fine.
    public func markPlayed(caseID: String) {
        var ids = investigatedSet()
        ids.insert(caseID)
        store.set(serialize(ids), forKey: key)
    }

    private func investigatedSet() -> Set<String> {
        guard let raw = store.string(forKey: key), !raw.isEmpty else { return [] }
        return Set(raw.split(separator: ",").map(String.init))
    }

    private func serialize(_ ids: Set<String>) -> String {
        // Sorted so the stored value is stable for inspection during dev;
        // not load-bearing for correctness.
        ids.sorted().joined(separator: ",")
    }
}

// MARK: - UserDefaults Store
//
// Wrapper rather than retroactive UserDefaults conformance. DailyBriefing's
// `StagingGate.Store` extension already adds the matching String-typed
// `set(_:forKey:)` to UserDefaults; declaring a second retroactive
// conformance with the same witness in this module would risk a duplicate-
// definition link error if both packages ever ended up in the same target.

// `UserDefaults` is thread-safe per Apple's docs but Foundation hasn't yet
// annotated it `Sendable`, so the wrapper is `@unchecked Sendable`.
struct UserDefaultsInvestigationStore: InvestigationLog.Store, @unchecked Sendable {
    let defaults: UserDefaults

    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    func set(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

// MARK: - Live factory

extension InvestigationLog {
    /// Convenience for production code: UserDefaults.standard.
    public static func live() -> InvestigationLog {
        InvestigationLog(store: UserDefaultsInvestigationStore(defaults: .standard))
    }
}
