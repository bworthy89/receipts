import Testing
import Foundation
@testable import DailyBriefing

@Suite("MockProvider")
struct MockProviderTests {

    /// The brief commits to 10 cases per day. The screen-level VoiceOver copy
    /// reads "Case [N] of 10. …" — anything else and the contract drifts.
    @Test("Roster has exactly 10 cases")
    func rosterHasTenCases() async throws {
        let provider = MockProvider()
        let day = Self.makeDay(year: 2026, month: 5, day: 3)
        let cases = try await provider.roster(for: day)
        #expect(cases.count == 10)
    }

    /// Roster is stable for a given calendar day. The screen relies on stable
    /// identity across re-renders within a day — the staging animation
    /// staggers PinDrops by ForEach index, so order changes mid-day would
    /// scramble which pin lands when.
    @Test("Roster is identical across calls for the same day")
    func rosterStableWithinDay() async throws {
        let provider = MockProvider()
        let day = Self.makeDay(year: 2026, month: 5, day: 3)
        let first = try await provider.roster(for: day)
        let second = try await provider.roster(for: day)
        #expect(first == second)
    }

    /// Different calendar days produce different orderings (the seeded
    /// shuffle rotates daily). We don't assert "completely different" — small
    /// permutations are valid — only that at least one slot differs, which
    /// proves the day key is feeding the RNG.
    @Test("Roster rotates across days")
    func rosterRotatesAcrossDays() async throws {
        let provider = MockProvider()
        let mayThird = try await provider.roster(for: Self.makeDay(year: 2026, month: 5, day: 3))
        let mayFourth = try await provider.roster(for: Self.makeDay(year: 2026, month: 5, day: 4))

        let mayThirdIDs = mayThird.map(\.caseID)
        let mayFourthIDs = mayFourth.map(\.caseID)
        #expect(mayThirdIDs != mayFourthIDs)
    }

    /// At least one case must arrive pre-investigated (verdict != nil) so the
    /// post-Deep-Check stamp visual is exercised on the design board. The
    /// brief mocks 3 of 10; we check ≥1 to allow tuning the count later
    /// without breaking the test.
    @Test("Roster contains at least one investigated case")
    func rosterHasInvestigatedMix() async throws {
        let provider = MockProvider()
        let day = Self.makeDay(year: 2026, month: 5, day: 3)
        let cases = try await provider.roster(for: day)
        let investigated = cases.filter { $0.verdict != nil }
        #expect(investigated.count >= 1)
    }

    /// Case numbers follow `CASE-26-MMDD-NNN` format. The format string is in
    /// the brief §8 Content Requirements; if it changes, the design contract
    /// changes too.
    @Test("Case numbers are CASE-26-MMDD-NNN format")
    func caseNumberFormat() async throws {
        let provider = MockProvider()
        let day = Self.makeDay(year: 2026, month: 5, day: 3)
        let cases = try await provider.roster(for: day)

        for kase in cases {
            #expect(kase.caseNumber.hasPrefix("CASE-26-0503-"))
            #expect(kase.caseNumber.count == "CASE-26-0503-001".count)
        }
    }

    /// Provider is concurrency-correct — multiple roster() calls in flight
    /// from different tasks must not crash or interleave state. Smoke-tested
    /// by racing two concurrent calls for the same day.
    @Test("Provider tolerates concurrent calls")
    func concurrentCalls() async throws {
        let provider = MockProvider()
        let day = Self.makeDay(year: 2026, month: 5, day: 3)
        async let a = provider.roster(for: day)
        async let b = provider.roster(for: day)
        let (left, right) = try await (a, b)
        #expect(left == right)
    }

    private static func makeDay(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 12
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date()
    }
}

@Suite("SeededRNG")
struct SeededRNGTests {

    /// Same seed produces the same stream — the property the layout relies on
    /// for "stable per day" placements.
    @Test("Same seed produces same stream")
    func deterministic() {
        var a = SeededRNG(seed: 42)
        var b = SeededRNG(seed: 42)
        for _ in 0..<10 {
            #expect(a.next() == b.next())
        }
    }

    /// Different seeds produce different streams (else the per-day rotation
    /// would be a no-op).
    @Test("Different seeds produce different streams")
    func differentSeedsDiffer() {
        var a = SeededRNG(seed: 42)
        var b = SeededRNG(seed: 43)
        var anyDifferent = false
        for _ in 0..<10 {
            if a.next() != b.next() { anyDifferent = true; break }
        }
        #expect(anyDifferent)
    }

    /// Seed=0 must not produce a degenerate all-zero stream — the splitmix
    /// constructor pre-mixes the seed to avoid this.
    @Test("Seed=0 produces non-zero output")
    func seedZeroNotDegenerate() {
        var rng = SeededRNG(seed: 0)
        var sawNonZero = false
        for _ in 0..<5 {
            if rng.next() != 0 { sawNonZero = true; break }
        }
        #expect(sawNonZero)
    }

    /// `seed(from:)` is the process-stable string→seed bridge used by the
    /// torn-paper shape. Same string MUST produce the same seed across calls
    /// — Swift's built-in `Hasher` is randomly seeded per process, which is
    /// the bug this method exists to avoid.
    @Test("seed(from:) is process-stable for the same string")
    func seedFromStringStable() {
        let a = SeededRNG.seed(from: "mock-20260503-7")
        let b = SeededRNG.seed(from: "mock-20260503-7")
        #expect(a == b)
    }

    /// Different strings produce different seeds (so each pin's tear shape
    /// is distinct).
    @Test("seed(from:) varies across distinct inputs")
    func seedFromStringDiffers() {
        let a = SeededRNG.seed(from: "case-1")
        let b = SeededRNG.seed(from: "case-2")
        #expect(a != b)
    }

    /// Empty input is allowed (returns the initial state). Smoke check that
    /// the for-loop over an empty utf8 sequence doesn't crash.
    @Test("seed(from:) handles empty string")
    func seedFromEmptyString() {
        _ = SeededRNG.seed(from: "")
    }
}
