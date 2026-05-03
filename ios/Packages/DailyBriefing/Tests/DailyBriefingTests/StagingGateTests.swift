import Testing
import Foundation
@testable import DailyBriefing

@Suite("StagingGate")
struct StagingGateTests {

    /// Fresh install on May 3 — first call should stage. The brief commits to
    /// "On a fresh install on May 4 morning the staging plays once."
    @Test("First call on a fresh store should stage")
    func firstCallStages() {
        let store = MemoryStore()
        let day = Self.makeDay(2026, 5, 3, hour: 7)
        let gate = StagingGate(store: store, now: { day })
        #expect(gate.shouldStage())
    }

    /// After markStaged on the same day, subsequent calls return false.
    /// The brief: "App background/foreground within the same day = no replay."
    @Test("After markStaged, same day returns false")
    func markStagedConsumes() {
        let store = MemoryStore()
        let day = Self.makeDay(2026, 5, 3, hour: 7)
        let gate = StagingGate(store: store, now: { day })

        #expect(gate.shouldStage())
        gate.markStaged()
        #expect(!gate.shouldStage())
    }

    /// Once midnight rolls over to the next day, shouldStage returns true
    /// again. Tested with a movable clock.
    @Test("Staging resets at the calendar day boundary")
    func resetsNextDay() {
        let store = MemoryStore()
        let storedClock = MovableClock(initial: Self.makeDay(2026, 5, 3, hour: 23))
        let gate = StagingGate(store: store, now: storedClock.now)

        #expect(gate.shouldStage())
        gate.markStaged()
        #expect(!gate.shouldStage())

        storedClock.set(Self.makeDay(2026, 5, 4, hour: 7))
        #expect(gate.shouldStage())
    }

    /// markStaged is idempotent within a day — calling twice is fine.
    @Test("markStaged is idempotent within a day")
    func markStagedIdempotent() {
        let store = MemoryStore()
        let day = Self.makeDay(2026, 5, 3, hour: 7)
        let gate = StagingGate(store: store, now: { day })

        gate.markStaged()
        gate.markStaged()
        #expect(!gate.shouldStage())
    }

    /// Day stamps roundtrip — canonical YYYY-MM-DD format. Checked via the
    /// internal helper so a future format change shows here first.
    @Test("dayStamp formats as YYYY-MM-DD")
    func dayStampFormat() {
        let date = Self.makeDay(2026, 5, 3, hour: 7)
        let stamp = StagingGate.dayStamp(for: date, calendar: Calendar(identifier: .gregorian))
        #expect(stamp == "2026-05-03")
    }

    private static func makeDay(_ year: Int, _ month: Int, _ day: Int, hour: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
    }
}

private final class MemoryStore: StagingGate.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}

private final class MovableClock: @unchecked Sendable {
    private var current: Date
    init(initial: Date) { self.current = initial }
    func set(_ date: Date) { current = date }
    var now: @Sendable () -> Date {
        { [weak self] in self?.current ?? Date() }
    }
}
