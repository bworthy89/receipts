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
// Storage shape: a JSON-encoded `[String]` in a single UserDefaults string.
// JSON-encoded rather than a comma-separated list so the storage doesn't
// break if a future real provider uses a caseID containing the delimiter
// character. The Store protocol stays string-keyed (and matches
// `StagingGate`'s pattern); JSON-handling lives inside `InvestigationLog`.

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
        guard
            let raw = store.string(forKey: key),
            !raw.isEmpty,
            let data = raw.data(using: .utf8),
            let decoded = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(decoded)
    }

    private func serialize(_ ids: Set<String>) -> String {
        // Sorted so the stored value is stable for inspection during dev
        // (not load-bearing for correctness, but useful when grepping the
        // UserDefaults plist).
        let sorted = ids.sorted()
        guard
            let data = try? JSONEncoder().encode(sorted),
            let raw = String(data: data, encoding: .utf8)
        else { return "[]" }
        return raw
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
