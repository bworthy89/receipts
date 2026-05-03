// MARK: - ArchiveDayGroup
//
// Pure-Swift bucketing of `ArchiveEntry`s into day-grouped sections, sorted
// reverse-chronologically. Each section gets a header label:
//   • "TODAY · MAY 03 · 3 CASES"
//   • "YESTERDAY · MAY 02 · 5 CASES"
//   • "MAY 01 · 2 CASES"  (older days drop the relative-day prefix)
//
// Per the 2026-05-03 archive-shape brief §5 + §8.
//
// Logic lives outside the View so the grouping/sorting/labelling is unit-
// testable on the macOS host without booting the simulator.

import Foundation
import DeepCheck

public struct ArchiveDayGroup: Sendable, Equatable, Identifiable {
    /// Stable identifier — the calendar day the entries fall on. Two
    /// renders of the same day produce the same id, so SwiftUI ForEach is
    /// stable.
    public let id: DateComponents
    /// Header label, fully formatted ("TODAY · MAY 03 · 3 CASES").
    public let header: String
    /// Entries in this group, sorted by `investigatedOn` descending.
    public let entries: [ArchiveEntry]

    public init(id: DateComponents, header: String, entries: [ArchiveEntry]) {
        self.id = id
        self.header = header
        self.entries = entries
    }
}

public enum ArchiveGrouping {

    /// Bucket archive entries into day-grouped sections, sorted
    /// reverse-chronologically. `now` controls the "TODAY"/"YESTERDAY"
    /// boundary so tests can pin a specific day.
    public static func groups(
        from entries: [ArchiveEntry],
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [ArchiveDayGroup] {
        guard !entries.isEmpty else { return [] }

        // Bucket by calendar day.
        let buckets: [DateComponents: [ArchiveEntry]] = Dictionary(grouping: entries) { entry in
            calendar.dateComponents([.year, .month, .day], from: entry.investigatedOn)
        }

        // Sort each bucket reverse-chronologically by investigatedOn.
        let sortedBuckets = buckets.mapValues { $0.sorted { $0.investigatedOn > $1.investigatedOn } }

        // Sort the buckets themselves by their day, descending.
        let orderedKeys = sortedBuckets.keys.sorted { lhs, rhs in
            guard
                let lDate = calendar.date(from: lhs),
                let rDate = calendar.date(from: rhs)
            else { return false }
            return lDate > rDate
        }

        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let todayDate = calendar.date(from: todayComponents) ?? now

        return orderedKeys.compactMap { dayKey in
            let bucketEntries = sortedBuckets[dayKey] ?? []
            guard let dayDate = calendar.date(from: dayKey) else { return nil }
            let header = formatHeader(
                dayDate: dayDate,
                todayDate: todayDate,
                count: bucketEntries.count,
                calendar: calendar
            )
            return ArchiveDayGroup(id: dayKey, header: header, entries: bucketEntries)
        }
    }

    /// Format header for a single day. "TODAY" and "YESTERDAY" labels for
    /// the 0/1-day-back groups (the relative label implies the absolute
    /// date and saves horizontal room on a phone); absolute date for older.
    static func formatHeader(
        dayDate: Date,
        todayDate: Date,
        count: Int,
        calendar: Calendar
    ) -> String {
        let dayDelta = calendar.dateComponents([.day], from: dayDate, to: todayDate).day ?? 0
        let casesNoun = count == 1 ? "CASE" : "CASES"

        switch dayDelta {
        case 0:
            return "TODAY · \(count) \(casesNoun)"
        case 1:
            return "YESTERDAY · \(count) \(casesNoun)"
        default:
            return "\(monthDayStamp(dayDate, calendar: calendar)) · \(count) \(casesNoun)"
        }
    }

    private static let monthShort = [
        "JAN","FEB","MAR","APR","MAY","JUN",
        "JUL","AUG","SEP","OCT","NOV","DEC",
    ]

    private static func monthDayStamp(_ date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.month, .day], from: date)
        let m = monthShort[max(1, min(12, comps.month ?? 1)) - 1]
        let d = String(format: "%02d", comps.day ?? 1)
        return "\(m) \(d)"
    }
}

