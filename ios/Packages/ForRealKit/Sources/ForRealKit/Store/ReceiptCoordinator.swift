import Foundation
import Observation

public protocol ReceiptAPI: Sendable {
    func postFax(url: String) async throws -> APIClient.PostFaxResult
}

public protocol ReceiptSSE: Sendable {
    func events(forFaxID id: String) -> AsyncThrowingStream<SSEStreamConsumer.Event, Error>
}

extension APIClient: ReceiptAPI {}
extension SSEStreamConsumer: ReceiptSSE {}

@Observable
@MainActor
public final class ReceiptCoordinator {

    public enum State: Equatable {
        case idle
        case streaming(faxID: String, partial: [Claim], final: PartialFinal?)
        case final(Fax)
        case failed(errorCode: String)

        public struct PartialFinal: Equatable, Sendable {
            public var verdict: Verdict
            public var commentary: String
        }
    }

    public private(set) var state: State = .idle

    private let client: any ReceiptAPI
    private let consumer: any ReceiptSSE
    private let store: FaxStore

    public init(client: any ReceiptAPI, consumer: any ReceiptSSE, store: FaxStore) {
        self.client = client
        self.consumer = consumer
        self.store = store
    }

    public func analyze(url: String) async throws {
        let post = try await client.postFax(url: url)
        let faxID = post.receiptID

        var partial: [Claim] = []
        var partialFinal: State.PartialFinal?
        state = .streaming(faxID: faxID, partial: partial, final: partialFinal)

        for try await event in consumer.events(forFaxID: faxID) {
            switch event {
            case .status:
                continue
            case .claimFinal(let claim):
                partial.append(claim)
                state = .streaming(faxID: faxID, partial: partial, final: partialFinal)
            case .receiptFinal(let payload):
                partialFinal = .init(verdict: payload.finalVerdict, commentary: payload.finalCommentary)
                state = .streaming(faxID: faxID, partial: partial, final: partialFinal)
            case .error(let payload):
                state = .failed(errorCode: payload.errorCode)
                return
            }
        }

        guard let partialFinal else {
            // Stream ended without a receipt_final; treat as failure.
            state = .failed(errorCode: "stream_ended_unexpectedly")
            return
        }

        let now = Int(Date().timeIntervalSince1970)
        let fax = Fax(
            id: faxID,
            sourceURL: url,
            sourceType: inferType(from: url),
            sourceProvider: inferProvider(from: url),
            title: nil,
            status: .done,
            finalVerdict: partialFinal.verdict,
            finalCommentary: partialFinal.commentary,
            errorCode: nil,
            createdAt: now,
            finishedAt: now,
            claims: partial.sorted { $0.position < $1.position }
        )
        try store.upsert(fax)
        state = .final(fax)
    }

    public func reset() { state = .idle }

    // MARK: - URL inference (lightweight; the backend already classifies authoritatively)

    private func inferType(from url: String) -> SourceType {
        if url.contains("tiktok.com") || url.contains("youtube.com") || url.contains("youtu.be") {
            return .video
        }
        return .article
    }

    private func inferProvider(from url: String) -> SourceProvider {
        if url.contains("tiktok.com") { return .tiktok }
        if url.contains("youtube.com") || url.contains("youtu.be") { return .youtube }
        return .article
    }
}
