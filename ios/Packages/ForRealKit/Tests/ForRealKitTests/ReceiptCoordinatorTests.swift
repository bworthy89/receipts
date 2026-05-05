import Testing
import Foundation
import SwiftData
@testable import ForRealKit

@Suite("ReceiptCoordinator")
@MainActor
struct ReceiptCoordinatorTests {

    @Test("starting analysis transitions to streaming and yields claims")
    func happyPath() async throws {
        let mockClient = MockAPIClient()
        let mockConsumer = MockSSEConsumer(events: [
            .status(.init(status: "streaming")),
            .claimFinal(.fixture(position: 1, verdict: .nope)),
            .claimFinal(.fixture(position: 2, verdict: .mixed)),
            .claimFinal(.fixture(position: 3, verdict: .yep)),
            .receiptFinal(.init(finalVerdict: .mixed, finalCommentary: "ok")),
        ])
        let store = try inMemoryStore()
        let coord = ReceiptCoordinator(client: mockClient, consumer: mockConsumer, store: store)

        #expect(coord.state == .idle)
        try await coord.analyze(url: "https://yt/x")

        // After completion, state is .final with the synthesized fax.
        if case .final(let fax) = coord.state {
            #expect(fax.finalVerdict == .mixed)
            #expect(fax.claims.count == 3)
            #expect(fax.status == .done)
        } else {
            Issue.record("expected .final, got \(coord.state)")
        }

        // Persisted to the store.
        let persisted = try store.fetch(id: fax(coord.state).id)
        #expect(persisted?.finalVerdict == .mixed)
    }

    @Test("error event transitions to .failed")
    func errorPath() async throws {
        let mockClient = MockAPIClient()
        let mockConsumer = MockSSEConsumer(events: [
            .error(.init(errorCode: "provider_blocked", message: "oops")),
        ])
        let store = try inMemoryStore()
        let coord = ReceiptCoordinator(client: mockClient, consumer: mockConsumer, store: store)

        try await coord.analyze(url: "https://tt/x")

        if case .failed(let code) = coord.state {
            #expect(code == "provider_blocked")
        } else {
            Issue.record("expected .failed")
        }
    }

    private func fax(_ state: ReceiptCoordinator.State) -> Fax {
        if case .final(let fax) = state { return fax }
        fatalError("not final")
    }

    private func inMemoryStore() throws -> FaxStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PersistedFax.self, PersistedClaim.self, configurations: config)
        return FaxStore(container: container)
    }
}

// MARK: - Test doubles

extension Claim {
    static func fixture(position: Int, verdict: Verdict) -> Claim {
        Claim(position: position, claimText: "c\(position)", verdict: verdict,
              commentary: "x", sources: [], resolvedAt: 1700000000 + position)
    }
}

final class MockAPIClient: ReceiptAPI, @unchecked Sendable {
    var lastURL: String?
    func postFax(url: String) async throws -> APIClient.PostFaxResult {
        lastURL = url
        return .init(receiptID: "fax-mock", status: "pending", cached: false)
    }
}

final class MockSSEConsumer: ReceiptSSE, @unchecked Sendable {
    private var events: [SSEStreamConsumer.Event]
    init(events: [SSEStreamConsumer.Event]) { self.events = events }
    func events(forFaxID id: String) -> AsyncThrowingStream<SSEStreamConsumer.Event, Error> {
        let captured = events
        return AsyncThrowingStream { continuation in
            Task {
                for e in captured { continuation.yield(e) }
                continuation.finish()
            }
        }
    }
}
