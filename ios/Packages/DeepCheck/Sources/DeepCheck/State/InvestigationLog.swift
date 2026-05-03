// MARK: - InvestigationLog
//
// Per-case played-already gate AND archive-entry store. Decides whether
// `DeepCheckScreen` should play the full 4-motion sequence (first
// investigation of this case) or skip straight to the settled board
// (revisit). Also retains the case + verdict snapshot per investigation
// so `Archive` can render its polaroid stack without a provider hop.
//
// Schema upgrade (2026-05-03 archive-shape brief §4): storage shifted
// from a JSON-encoded `[String]` of caseIDs to a JSON-encoded
// `[caseID: ArchiveEntry]` dict. Old format fails open to empty —
// same fail-open behaviour as the v1→v2 (comma → JSON) migration.
//
// Pure logic, testable on the macOS host: takes a key-value store rather
// than reading UserDefaults.standard directly. The default `live()` factory
// wires it to the real one.

import Foundation
import Models

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
        key: String = "DeepCheck.investigatedCases"
    ) {
        self.store = store
        self.key = key
    }

    /// Returns true if the given case has not yet been investigated; the
    /// screen should play the full sequence. Returns false on revisit; the
    /// screen should skip to the settled board.
    public func shouldPlay(caseID: String) -> Bool {
        loadEntries()[caseID] == nil
    }

    /// Records a completed investigation. Snapshot of the case + verdict at
    /// investigation time so the archive can render without depending on
    /// the provider's current state.
    public func markInvestigated(_ entry: ArchiveEntry) {
        var entries = loadEntries()
        entries[entry.caseID] = entry
        save(entries)
    }

    /// Returns the archive entry for a single case, or nil if not yet
    /// investigated.
    public func entry(for caseID: String) -> ArchiveEntry? {
        loadEntries()[caseID]
    }

    /// All archived entries. Order is unspecified — callers (e.g. `Archive`)
    /// sort by `investigatedOn` themselves.
    public func allEntries() -> [ArchiveEntry] {
        Array(loadEntries().values)
    }

    /// Number of cases on file. Drives the briefing's
    /// "ARCHIVE · N FILED" footer caption.
    public var count: Int {
        loadEntries().count
    }

    // MARK: - Storage

    private func loadEntries() -> [String: ArchiveEntry] {
        guard
            let raw = store.string(forKey: key),
            !raw.isEmpty,
            let data = raw.data(using: .utf8)
        else { return [:] }
        // Try the current schema first.
        if let decoded = try? JSONDecoder.archive.decode([String: ArchiveEntry].self, from: data) {
            return decoded
        }
        // Fail-open for any earlier schema (v1 comma-separated, v2 JSON
        // [String]). The next markInvestigated call overwrites with the
        // current schema; users lose any prior unmarked-rich state, which
        // doesn't exist in practice for the v1→v3 jump (no real users yet).
        return [:]
    }

    private func save(_ entries: [String: ArchiveEntry]) {
        guard
            let data = try? JSONEncoder.archive.encode(entries),
            let raw = String(data: data, encoding: .utf8)
        else { return }
        store.set(raw, forKey: key)
    }
}

// MARK: - ArchiveEntry
//
// One investigated case as stored in the log. Snapshot of the case data
// (caseNumber, headline) at investigation time so the archive doesn't need
// to query a provider to render — the data lives with the log entry. The
// verdict and investigatedOn round out the per-card content.

public struct ArchiveEntry: Sendable, Equatable, Identifiable, Codable {
    public let caseID: String
    public let caseNumber: String
    public let headline: String
    public let verdict: Case.Verdict
    public let investigatedOn: Date

    public var id: String { caseID }

    public init(
        caseID: String,
        caseNumber: String,
        headline: String,
        verdict: Case.Verdict,
        investigatedOn: Date
    ) {
        self.caseID = caseID
        self.caseNumber = caseNumber
        self.headline = headline
        self.verdict = verdict
        self.investigatedOn = investigatedOn
    }
}

// MARK: - Codable on Verdict

extension Case.Verdict: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let v = Self(rawValue: raw) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown verdict raw value: \(raw)"
            ))
        }
        self = v
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}

// MARK: - Shared encoders/decoders

extension JSONEncoder {
    /// ISO8601 dates so the persisted form is human-readable when grepping
    /// the UserDefaults plist during dev.
    fileprivate static let archive: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}

extension JSONDecoder {
    fileprivate static let archive: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
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
