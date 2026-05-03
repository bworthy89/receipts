import Testing
import Foundation
import Models
@testable import DeepCheck

@Suite("Source + Investigation models")
struct InvestigationTests {

    @Test("Source is Identifiable + Equatable")
    func sourceShape() {
        let date = Date()
        let a = Source(id: "s1", outlet: "Reuters", excerpt: "x", publishedOn: date)
        let b = Source(id: "s1", outlet: "Reuters", excerpt: "x", publishedOn: date)
        let c = Source(id: "s1", outlet: "Reuters", excerpt: "y", publishedOn: date)
        #expect(a.id == "s1")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("EvidenceQuote is Identifiable + Equatable")
    func quoteShape() {
        let a = EvidenceQuote(id: "q1", quote: "x", attribution: "Reuters")
        let b = EvidenceQuote(id: "q1", quote: "x", attribution: "Reuters")
        let c = EvidenceQuote(id: "q1", quote: "y", attribution: "Reuters")
        #expect(a.id == "q1")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("Investigation aggregates case + sources + evidence + verdict")
    func investigationShape() {
        let kase = Case(caseID: "c1", caseNumber: "CASE-26-0503-001", headline: "x")
        let inv = Investigation(
            kase: kase,
            sources: [],
            evidence: [],
            verdict: .confirmed
        )
        #expect(inv.kase.caseID == "c1")
        #expect(inv.verdict == .confirmed)
    }
}
