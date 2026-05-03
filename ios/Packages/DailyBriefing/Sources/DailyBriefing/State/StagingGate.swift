// MARK: - StagingGate
//
// Decides whether the briefing should re-stage on appear (lights-up + pin-
// drops) or render fully assembled.
//
// Per the 2026-05-03 brief §7 Interaction Model:
//   "First-per-day gating = local-only via UserDefaults (last-staged-date).
//    On a fresh install on May 4 morning the staging plays once. App
//    background/foreground within the same day = no replay."
//
// Pure logic, testable on the macOS host: takes a clock and a key-value store
// rather than reading UserDefaults.standard / Date() directly. The default
// `live()` factory wires it to the real ones.

import Foundation

public final class StagingGate: @unchecked Sendable {

    /// Storage abstraction. UserDefaults satisfies it; tests inject a dictionary.
    public protocol Store: Sendable {
        func string(forKey key: String) -> String?
        func set(_ value: String, forKey key: String)
    }

    private let store: any Store
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private let key: String

    public init(
        store: any Store,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = Calendar(identifier: .gregorian),
        key: String = "DailyBriefing.lastStagedDate"
    ) {
        self.store = store
        self.now = now
        self.calendar = calendar
        self.key = key
    }

    /// Returns true if the briefing has not yet staged today. The gate does
    /// NOT mark itself consumed — callers must call `markStaged()` once the
    /// staging animation actually begins, so a crash mid-staging on first
    /// launch still re-stages on next open instead of skipping the
    /// once-per-day moment.
    public func shouldStage() -> Bool {
        let lastStamp = store.string(forKey: key)
        let todayStamp = Self.dayStamp(for: now(), calendar: calendar)
        return lastStamp != todayStamp
    }

    /// Records that today's staging has played. Idempotent within a day.
    public func markStaged() {
        let todayStamp = Self.dayStamp(for: now(), calendar: calendar)
        store.set(todayStamp, forKey: key)
    }

    /// `YYYY-MM-DD` in the supplied calendar. ISO-style chosen for sortability
    /// in case future debugging wants to tail this value.
    static func dayStamp(for date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}

// MARK: - UserDefaults Store

extension UserDefaults: StagingGate.Store {
    public func set(_ value: String, forKey key: String) {
        set(value as Any?, forKey: key)
    }
}

// MARK: - Live factory

extension StagingGate {
    /// Convenience for production code: UserDefaults.standard + Date.now.
    public static func live() -> StagingGate {
        StagingGate(store: UserDefaults.standard)
    }
}
