import Testing
import Foundation
@testable import ForRealKit

@Suite("SSE block parser")
struct SSEParserTests {

    @Test("parses a status event")
    func parsesStatus() throws {
        let block = "event: status\ndata: {\"status\":\"streaming\"}"
        let event = try SSEStreamConsumer.parseBlock(block)

        if case .status(let payload) = event {
            #expect(payload.status == "streaming")
        } else {
            Issue.record("expected status event")
        }
    }

    @Test("parses a claim_final event")
    func parsesClaim() throws {
        let block = """
        event: claim_final
        data: {"position":1,"claim_text":"x","verdict":"nope","commentary":"no","sources":[]}
        """
        let event = try SSEStreamConsumer.parseBlock(block)
        if case .claimFinal(let claim) = event {
            #expect(claim.position == 1)
            #expect(claim.verdict == .nope)
        } else {
            Issue.record("expected claim_final event")
        }
    }

    @Test("parses a receipt_final event")
    func parsesFinal() throws {
        let block = """
        event: receipt_final
        data: {"final_verdict":"mixed","final_commentary":"meh"}
        """
        let event = try SSEStreamConsumer.parseBlock(block)
        if case .receiptFinal(let payload) = event {
            #expect(payload.finalVerdict == .mixed)
            #expect(payload.finalCommentary == "meh")
        } else {
            Issue.record("expected receipt_final event")
        }
    }

    @Test("parses an error event")
    func parsesError() throws {
        let block = """
        event: error
        data: {"error_code":"provider_blocked","message":"oops"}
        """
        let event = try SSEStreamConsumer.parseBlock(block)
        if case .error(let payload) = event {
            #expect(payload.errorCode == "provider_blocked")
        } else {
            Issue.record("expected error event")
        }
    }
}

@Suite("SSEStreamConsumer (live network — requires deployed dev worker)")
struct SSEStreamConsumerLiveTests {

    @Test("end-to-end: post then stream produces the full event sequence")
    func postThenStream() async throws {
        let device = "test-device-fr-sse-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        let post = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-sse-\(UUID().uuidString)")

        let consumer = SSEStreamConsumer(environment: .dev, deviceID: device)
        var events: [SSEStreamConsumer.Event] = []
        for try await event in consumer.events(forFaxID: post.receiptID) {
            events.append(event)
        }

        let kinds = events.map { $0.kindLabel }
        #expect(kinds == ["status", "claim_final", "claim_final", "claim_final", "receipt_final"])
    }
}
