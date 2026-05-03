import Testing
import Models
@testable import DailyBriefing

@Suite("Case model")
struct CaseTests {

    /// Identifiable: `id` returns `caseID`. SwiftUI ForEach uses this for
    /// stable identity across staging re-renders.
    @Test("id mirrors caseID")
    func identifiableMirrorsCaseID() {
        let kase = Case(caseID: "abc-123", caseNumber: "CASE-26-0503-001", headline: "x")
        #expect(kase.id == "abc-123")
    }

    /// Equatable: same fields equal, different verdict differs.
    @Test("Equatable across verdicts")
    func equatableAcrossVerdicts() {
        let a = Case(caseID: "x", caseNumber: "CASE-26-0503-001", headline: "y")
        let b = Case(caseID: "x", caseNumber: "CASE-26-0503-001", headline: "y")
        let c = Case(caseID: "x", caseNumber: "CASE-26-0503-001", headline: "y", verdict: .confirmed)
        #expect(a == b)
        #expect(a != c)
    }

    /// Verdict raw values match the brief's stamp inscriptions exactly.
    /// The TornNote slams these strings as the visible stamp text — drift
    /// would change what the user sees.
    @Test("Verdict raw values match stamp inscriptions")
    func verdictInscriptions() {
        #expect(Case.Verdict.confirmed.rawValue == "CONFIRMED")
        #expect(Case.Verdict.busted.rawValue == "BUSTED")
        #expect(Case.Verdict.coldCase.rawValue == "COLD CASE")
    }
}
