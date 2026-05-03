import Testing
import Foundation
import Models
@testable import DeepCheck

@Suite("DeepCheck.MockProvider")
struct MockProviderTests {

    /// Every briefing case (`mock-headline-0` … `mock-headline-9`) must have
    /// a canned investigation. If a future addition to the briefing roster
    /// adds case 10, this test is the early signal.
    @Test("Provider has canned data for all 10 briefing cases")
    func coversAllTenBriefingCases() async throws {
        let provider = MockProvider()
        for i in 0..<10 {
            let kase = Case(
                caseID: "mock-headline-\(i)",
                caseNumber: "CASE-26-0503-001",
                headline: "stub"
            )
            // Throws if the case is missing — no #expect, just no-throw.
            _ = try await provider.investigation(for: kase)
        }
    }

    @Test("Each canned investigation carries 5 sources and 5 quotes")
    func everyCaseHasFiveAndFive() async throws {
        let provider = MockProvider()
        for i in 0..<10 {
            let kase = Case(
                caseID: "mock-headline-\(i)",
                caseNumber: "CASE-26-0503-001",
                headline: "stub"
            )
            let inv = try await provider.investigation(for: kase)
            #expect(inv.sources.count == 5, "case \(i) has \(inv.sources.count) sources, want 5")
            #expect(inv.evidence.count == 5, "case \(i) has \(inv.evidence.count) quotes, want 5")
        }
    }

    /// Verdict distribution is the 4 / 3 / 3 mix called out in the brief §8
    /// so all three stamp variants are exercised. If someone retunes the
    /// distribution, this test is the explicit signal.
    @Test("Verdict distribution is 4 CONFIRMED / 3 BUSTED / 3 COLD CASE")
    func verdictDistribution() async throws {
        let provider = MockProvider()
        var counts: [Case.Verdict: Int] = [:]
        for i in 0..<10 {
            let kase = Case(caseID: "mock-headline-\(i)", caseNumber: "x", headline: "x")
            let inv = try await provider.investigation(for: kase)
            counts[inv.verdict, default: 0] += 1
        }
        #expect(counts[.confirmed] == 4)
        #expect(counts[.busted] == 3)
        #expect(counts[.coldCase] == 3)
    }

    /// Provider re-binds the live case onto the canned investigation, so the
    /// returned `inv.kase` carries the briefing's current caseNumber rather
    /// than the canned stub.
    @Test("Returned investigation carries the live case identity")
    func reBindsLiveCase() async throws {
        let provider = MockProvider()
        let live = Case(
            caseID: "mock-headline-0",
            caseNumber: "CASE-26-0503-001",
            headline: "live headline"
        )
        let inv = try await provider.investigation(for: live)
        #expect(inv.kase.caseNumber == "CASE-26-0503-001")
        #expect(inv.kase.headline == "live headline")
    }

    /// Unknown caseID throws a typed error rather than crashing or returning
    /// stale data.
    @Test("Unknown caseID throws DeepCheckProviderError.unknownCase")
    func unknownCaseThrows() async {
        let provider = MockProvider()
        let bogus = Case(caseID: "not-a-real-case", caseNumber: "x", headline: "x")
        await #expect(throws: DeepCheckProviderError.self) {
            _ = try await provider.investigation(for: bogus)
        }
    }

    /// Investigations with verdicts CONFIRMED for cases 1 and 4, BUSTED for
    /// case 7 — these match the pre-stamped state in DailyBriefing's
    /// MockProvider so the briefing's investigated mix and Deep Check's
    /// verdict are consistent.
    @Test("Pre-stamped briefing cases match DeepCheck verdicts")
    func prestampedConsistency() async throws {
        let provider = MockProvider()
        let case1 = try await provider.investigation(for: Case(caseID: "mock-headline-1", caseNumber: "x", headline: "x"))
        let case4 = try await provider.investigation(for: Case(caseID: "mock-headline-4", caseNumber: "x", headline: "x"))
        let case7 = try await provider.investigation(for: Case(caseID: "mock-headline-7", caseNumber: "x", headline: "x"))
        #expect(case1.verdict == .confirmed)
        #expect(case4.verdict == .confirmed)
        #expect(case7.verdict == .busted)
    }
}
