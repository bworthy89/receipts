// MARK: - MockSeed
//
// DEBUG-only helper that pre-populates an empty InvestigationLog with
// archive entries across multiple days, so the archive demos as non-empty
// without requiring the user to play through Deep Check on every case.
//
// Per the 2026-05-03 archive-shape brief §10:
//   "DEBUG-only mock seed. Pre-populate the log with N cases for screenshot
//    review. Decide N = 4–5 across 2–3 days at craft time."
//
// Five cases across three days (TODAY · 2, YESTERDAY · 2, TWO DAYS AGO · 1).
// Verdict mix matches the briefing's pre-stamped state for case 1 / 4 / 7
// so the archive doesn't disagree with the briefing about what happened.

import Foundation
import Models
import DeepCheck

#if DEBUG
public enum ArchiveMockSeed {

    /// Populate `log` with 5 demo entries IF it's empty. Existing entries
    /// are left alone — never overwrite the user's real investigations.
    public static func seedIfEmpty(_ log: InvestigationLog, now: Date = Date()) {
        guard log.allEntries().isEmpty else { return }

        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today) ?? today

        let entries: [ArchiveEntry] = [
            // TODAY · 2 cases
            ArchiveEntry(
                caseID: "mock-headline-1",
                caseNumber: "CASE-26-0503-005",
                headline: "FDA recalls three insulin pumps over delivery-rate firmware fault",
                verdict: .confirmed,
                investigatedOn: today.addingTimeInterval(45_300) // ~12:35
            ),
            ArchiveEntry(
                caseID: "mock-headline-3",
                caseNumber: "CASE-26-0503-009",
                headline: "Two Mars science programs face cuts in House appropriations markup",
                verdict: .busted,
                investigatedOn: today.addingTimeInterval(33_900) // ~09:25
            ),
            // YESTERDAY · 2 cases
            ArchiveEntry(
                caseID: "mock-headline-4",
                caseNumber: "CASE-26-0502-002",
                headline: "Antarctic ice shelf calves 1,200 sq-km berg, scientists call it 'overdue'",
                verdict: .confirmed,
                investigatedOn: yesterday.addingTimeInterval(57_600) // ~16:00
            ),
            ArchiveEntry(
                caseID: "mock-headline-7",
                caseNumber: "CASE-26-0502-008",
                headline: "City council rejects bid to redevelop riverfront industrial parcel, 6-3",
                verdict: .busted,
                investigatedOn: yesterday.addingTimeInterval(28_800) // ~08:00
            ),
            // TWO DAYS AGO · 1 case
            ArchiveEntry(
                caseID: "mock-headline-9",
                caseNumber: "CASE-26-0501-004",
                headline: "Researchers report novel battery chemistry doubling cycle life in lab tests",
                verdict: .coldCase,
                investigatedOn: twoDaysAgo.addingTimeInterval(73_200) // ~20:20
            ),
        ]

        for entry in entries {
            log.markInvestigated(entry)
        }
    }
}
#endif
