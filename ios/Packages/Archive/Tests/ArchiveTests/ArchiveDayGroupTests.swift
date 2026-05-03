import Testing
import Foundation
import Models
import DeepCheck
@testable import Archive

@Suite("ArchiveGrouping")
struct ArchiveGroupingTests {

    private static let cal = Calendar(identifier: .gregorian)

    /// Empty input produces no groups (handled defensively for first-launch
    /// archives).
    @Test("Empty entries produce no groups")
    func emptyProducesNothing() {
        let groups = ArchiveGrouping.groups(from: [], now: Self.day(2026, 5, 3))
        #expect(groups.isEmpty)
    }

    /// Entries on multiple days bucket into separate groups, and the
    /// groups themselves are sorted reverse-chronologically.
    @Test("Multi-day entries bucket and sort newest-first")
    func multiDayBuckets() {
        let today = Self.timestamp(2026, 5, 3, 12, 0)
        let yesterday = Self.timestamp(2026, 5, 2, 8, 0)
        let twoAgo = Self.timestamp(2026, 5, 1, 20, 0)

        let entries = [
            Self.entry("c1", on: today),
            Self.entry("c2", on: yesterday),
            Self.entry("c3", on: twoAgo),
        ]

        let groups = ArchiveGrouping.groups(from: entries, now: today)
        #expect(groups.count == 3)
        #expect(groups[0].entries.map(\.caseID) == ["c1"])
        #expect(groups[1].entries.map(\.caseID) == ["c2"])
        #expect(groups[2].entries.map(\.caseID) == ["c3"])
    }

    /// Within a day, entries are sorted reverse-chronologically by
    /// investigatedOn.
    @Test("Within-day entries sort reverse-chronologically")
    func withinDaySort() {
        let morning = Self.timestamp(2026, 5, 3, 8, 0)
        let noon = Self.timestamp(2026, 5, 3, 12, 0)
        let evening = Self.timestamp(2026, 5, 3, 19, 0)

        let entries = [
            Self.entry("morning", on: morning),
            Self.entry("evening", on: evening),
            Self.entry("noon", on: noon),
        ]

        let groups = ArchiveGrouping.groups(from: entries, now: noon)
        #expect(groups.count == 1)
        #expect(groups[0].entries.map(\.caseID) == ["evening", "noon", "morning"])
    }

    /// "TODAY" label appears for the 0-day-back group; absolute date is
    /// dropped (TODAY implies it, saves row width).
    @Test("Header for today reads TODAY (no date)")
    func todayHeaderLabel() {
        let now = Self.timestamp(2026, 5, 3, 12, 0)
        let entries = [Self.entry("c1", on: now)]
        let groups = ArchiveGrouping.groups(from: entries, now: now)
        #expect(groups[0].header == "TODAY · 1 CASE")
    }

    /// "YESTERDAY" label appears for the 1-day-back group; absolute date
    /// is dropped for the same reason.
    @Test("Header for yesterday reads YESTERDAY (no date)")
    func yesterdayHeaderLabel() {
        let now = Self.timestamp(2026, 5, 3, 12, 0)
        let yesterday = Self.timestamp(2026, 5, 2, 12, 0)
        let entries = [Self.entry("c1", on: yesterday)]
        let groups = ArchiveGrouping.groups(from: entries, now: now)
        #expect(groups[0].header == "YESTERDAY · 1 CASE")
    }

    /// Older days drop the relative prefix and use the absolute date.
    @Test("Older days use absolute date only")
    func olderUsesAbsolute() {
        let now = Self.timestamp(2026, 5, 3, 12, 0)
        let twoAgo = Self.timestamp(2026, 5, 1, 12, 0)
        let entries = [Self.entry("c1", on: twoAgo)]
        let groups = ArchiveGrouping.groups(from: entries, now: now)
        #expect(!groups[0].header.contains("TODAY"))
        #expect(!groups[0].header.contains("YESTERDAY"))
        #expect(groups[0].header.hasPrefix("MAY 01"))
    }

    /// Plural noun for ≥2 cases, singular for exactly 1.
    @Test("Header pluralizes CASES vs CASE correctly")
    func headerPluralization() {
        let now = Self.timestamp(2026, 5, 3, 12, 0)
        let one = [Self.entry("a", on: now)]
        let two = [Self.entry("a", on: now), Self.entry("b", on: now)]
        #expect(ArchiveGrouping.groups(from: one, now: now)[0].header.hasSuffix("1 CASE"))
        #expect(ArchiveGrouping.groups(from: two, now: now)[0].header.hasSuffix("2 CASES"))
    }

    // MARK: - Helpers

    private static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return cal.date(from: c) ?? Date()
    }

    private static func timestamp(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = hour; c.minute = minute
        return cal.date(from: c) ?? Date()
    }

    private static func entry(_ id: String, on date: Date) -> ArchiveEntry {
        ArchiveEntry(
            caseID: id,
            caseNumber: "CASE-26-0503-001",
            headline: "Stub headline",
            verdict: .confirmed,
            investigatedOn: date
        )
    }
}
