// MARK: - MockProvider
//
// Hardcoded roster of 10 wire-service-register headlines for the production-
// ready preview build. 3 are pre-marked investigated to exercise the post-
// Deep-Check verdict-stamp visual on the board.
//
// Per the 2026-05-03 brief §8 Content Requirements: 10 mock headlines, real
// wire-service register (not jokey; the dry humor lives in the FRAME, never
// the case itself). Mock case-IDs format `CASE-26-0503-001`–`010`.
//
// The roster is keyed off year-month-day so the same headlines appear if the
// user's clock is on May 3, regardless of which week the simulator was last
// booted. A different day rotates a deterministic hash-shuffle of the same
// 10 — keeps the demo fresh for screenshot review without needing network
// data.

import Foundation
import Models

public struct MockProvider: DailyBriefingProvider {

    public init() {}

    public func roster(for day: Date) async throws -> [Case] {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        let dayKey = (comps.year ?? 2026) * 10_000
            + (comps.month ?? 5) * 100
            + (comps.day ?? 3)

        let baseHeadlines = Self.headlines

        // Stable per-day permutation — same day = same order, next day rotates.
        var shuffled = baseHeadlines.indices.map { $0 }
        var rng = SeededRNG(seed: UInt64(dayKey))
        shuffled.shuffle(using: &rng)

        let dayStamp = String(format: "%02d%02d", comps.month ?? 5, comps.day ?? 3)

        return shuffled.enumerated().map { (slot, originalIndex) in
            let entry = baseHeadlines[originalIndex]
            let serial = String(format: "%03d", slot + 1)
            // caseID is stable per-headline (does NOT include the day) so
            // DeepCheck's mock provider can match an investigation to a
            // briefing pin by ID. The display caseNumber still rotates daily.
            return Case(
                caseID: "mock-headline-\(originalIndex)",
                caseNumber: "CASE-26-\(dayStamp)-\(serial)",
                headline: entry.headline,
                verdict: entry.verdict
            )
        }
    }

    // The 10 mock headlines. Mix of politics, science, business, local, and
    // weird. Investigated/uninvestigated mix exercises the stamp visual.
    //
    // Verdict picks: CONFIRMED on cases that lean factual-as-reported; BUSTED
    // on the council vote (mock bias-busted call); the rest live as
    // uninvestigated to give the board breathing room — a fully-stamped board
    // would dilute the visual punch of the stamp.
    private static let headlines: [Entry] = [
        Entry("Senate panel deadlocks on AI export-control bill, third hearing scheduled", nil),
        Entry("FDA recalls three insulin pumps over delivery-rate firmware fault", .confirmed),
        Entry("Cargo ship grounded in San Francisco Bay; salvage crews stage at Treasure Island", nil),
        Entry("Two Mars science programs face cuts in House appropriations markup", nil),
        Entry("Antarctic ice shelf calves 1,200 sq-km berg, scientists call it 'overdue'", .confirmed),
        Entry("Japan's central bank holds rates, signals no shift through summer", nil),
        Entry("Outage at major DNS provider takes down banking apps for ninety minutes", nil),
        Entry("City council rejects bid to redevelop riverfront industrial parcel, 6-3", .busted),
        Entry("Auto union ratifies tentative agreement with three-shift assembly plant", nil),
        Entry("Researchers report novel battery chemistry doubling cycle life in lab tests", nil),
    ]

    private struct Entry {
        let headline: String
        let verdict: Case.Verdict?
        init(_ headline: String, _ verdict: Case.Verdict?) {
            self.headline = headline
            self.verdict = verdict
        }
    }
}

// MARK: - SeededRNG
//
// Splitmix64 PRNG — small, fast, deterministic. Used both here for the per-day
// shuffle and by PinLayout for stable per-day positions. Same seed → same
// stream of values across runs and platforms.
//
// Public so PinLayout (and tests) can construct one with a known seed.

public struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        // Mix the seed once so seed=0 doesn't produce a zero state.
        self.state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Stable, process-independent hash of a string's UTF-8 bytes.
    ///
    /// Use this instead of `Hasher` whenever a seed must be the same across
    /// app launches (e.g. per-pin paper-tear shapes that should be stable so
    /// a returning user sees "the same note" on the cork). Swift's `Hasher`
    /// is randomly seeded per-process and is not suitable for that.
    ///
    /// Mixes each byte into the splitmix64 finalizer, which is the same
    /// chunked-mix shape `next()` uses, so the seed quality matches what
    /// `init(seed:)` consumers expect.
    public static func seed(from string: String) -> UInt64 {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        for byte in string.utf8 {
            state = state &+ UInt64(byte)
            state = (state ^ (state >> 30)) &* 0xBF58_476D_1CE4_E5B9
            state = (state ^ (state >> 27)) &* 0x94D0_49BB_1331_11EB
            state = state ^ (state >> 31)
        }
        return state
    }
}
