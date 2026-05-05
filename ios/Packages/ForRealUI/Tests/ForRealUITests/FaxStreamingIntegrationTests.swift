import Testing
import SwiftUI
import SwiftData
@testable import ForRealUI
@testable import ForRealKit

@Suite("FaxSheet — streaming integration")
@MainActor
struct FaxStreamingIntegrationTests {

    @Test("FaxSheet derives state from coordinator (idle → streaming → final)")
    func deriveStateFromCoordinator() async throws {
        #if os(iOS)
        let mockClient = MockAPIClient()
        let mockConsumer = MockSSEConsumer(events: [
            .status(.init(status: "streaming")),
            .claimFinal(.fixture(position: 1, verdict: .nope)),
            .claimFinal(.fixture(position: 2, verdict: .mixed)),
            .claimFinal(.fixture(position: 3, verdict: .yep)),
            .receiptFinal(.init(finalVerdict: .mixed, finalCommentary: "ok")),
        ])
        let store = try makeStore()
        let coord = ReceiptCoordinator(client: mockClient, consumer: mockConsumer, store: store)

        let viewIdle = FaxSheet(state: .from(coord.state))
        if case .initial = viewIdle.state { /* ok */ } else { Issue.record("expected .initial") }

        try await coord.analyze(url: "https://yt/x")

        let viewFinal = FaxSheet(state: .from(coord.state))
        if case .final(let verdict, _, let claims) = viewFinal.state {
            #expect(verdict == .mixed)
            #expect(claims.count == 3)
        } else {
            Issue.record("expected .final")
        }
        #endif
    }

    private func makeStore() throws -> FaxStore {
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
    func postFax(url: String) async throws -> APIClient.PostFaxResult {
        .init(receiptID: "fax-mock", status: "pending", cached: false)
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
