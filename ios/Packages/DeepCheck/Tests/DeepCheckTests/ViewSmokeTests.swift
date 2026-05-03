import Testing
import SwiftUI
import Foundation
import Models
@testable import DeepCheck

@Suite("DeepCheck view surface")
@MainActor
struct ViewSmokeTests {

    @Test("HeadlinePin constructs with and without verdict")
    func headlinePinConstructors() {
        let untouched = Case(caseID: "x", caseNumber: "CASE-26-0503-001", headline: "y")
        let stamped = Case(caseID: "z", caseNumber: "CASE-26-0503-002", headline: "y", verdict: .confirmed)
        let _: any View = HeadlinePin(untouched)
        let _: any View = HeadlinePin(stamped)
    }

    @Test("SourcePin constructs from a Source")
    func sourcePinConstructor() {
        let source = Source(
            id: "s1",
            outlet: "Reuters",
            excerpt: "x",
            publishedOn: Date()
        )
        let _: any View = SourcePin(source)
    }

    @Test("EvidenceDossier constructs from quotes")
    func dossierConstructor() {
        let quotes = (0..<3).map {
            EvidenceQuote(id: "q\($0)", quote: "x", attribution: "Reuters")
        }
        let _: any View = EvidenceDossier(quotes)
    }

    /// DeepCheckScreen accepts dependency-injected provider, log, and a
    /// dismiss closure so previews and the briefing's fullScreenCover both
    /// drive it.
    @Test("DeepCheckScreen constructs with injected dependencies")
    func screenConstructor() {
        let kase = Case(caseID: "mock-headline-0", caseNumber: "CASE-26-0503-001", headline: "x")
        let _: any View = DeepCheckScreen(
            kase: kase,
            provider: MockProvider(),
            log: InvestigationLog(store: InMemoryStore()),
            onDismiss: {}
        )
    }
}

private final class InMemoryStore: InvestigationLog.Store, @unchecked Sendable {
    private var dict: [String: String] = [:]
    func string(forKey key: String) -> String? { dict[key] }
    func set(_ value: String, forKey key: String) { dict[key] = value }
}
