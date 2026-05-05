import Foundation

public final class SSEStreamConsumer: Sendable {

    public enum Event: Sendable {
        case status(StatusPayload)
        case claimFinal(Claim)
        case receiptFinal(ReceiptFinalPayload)
        case error(ErrorPayload)

        public var kindLabel: String {
            switch self {
            case .status:        "status"
            case .claimFinal:    "claim_final"
            case .receiptFinal:  "receipt_final"
            case .error:         "error"
            }
        }
    }

    public struct StatusPayload: Decodable, Sendable, Equatable {
        public let status: String
    }

    public struct ReceiptFinalPayload: Decodable, Sendable, Equatable {
        public let finalVerdict: Verdict
        public let finalCommentary: String

        enum CodingKeys: String, CodingKey {
            case finalVerdict = "final_verdict"
            case finalCommentary = "final_commentary"
        }
    }

    public struct ErrorPayload: Decodable, Sendable, Equatable {
        public let errorCode: String
        public let message: String

        enum CodingKeys: String, CodingKey {
            case errorCode = "error_code"
            case message
        }
    }

    private let environment: APIEnvironment
    private let deviceID: String
    private let session: URLSession

    public init(environment: APIEnvironment, deviceID: String, session: URLSession = .shared) {
        self.environment = environment
        self.deviceID = deviceID
        self.session = session
    }

    public func events(forFaxID id: String) -> AsyncThrowingStream<Event, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: environment.baseURL.appendingPathComponent("/v1/receipts/\(id)/stream"))
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw APIError.http(status: status, body: nil)
                    }

                    // Manually accumulate bytes into lines so that empty lines
                    // (the SSE block separator "\n\n") are preserved.
                    // bytes.lines silently drops empty lines, breaking the SSE protocol.
                    var lineBuffer: [UInt8] = []
                    var blockBuffer = ""

                    for try await byte in bytes {
                        if byte == UInt8(ascii: "\n") {
                            // Completed one line.
                            let line = String(bytes: lineBuffer, encoding: .utf8) ?? ""
                            lineBuffer = []

                            if line.isEmpty {
                                // Empty line = end of SSE event block.
                                if !blockBuffer.isEmpty {
                                    let event = try Self.parseBlock(blockBuffer)
                                    continuation.yield(event)
                                    blockBuffer = ""
                                }
                            } else {
                                // Strip optional carriage return from CRLF streams.
                                let trimmed = line.hasSuffix("\r") ? String(line.dropLast()) : line
                                if !blockBuffer.isEmpty { blockBuffer += "\n" }
                                blockBuffer += trimmed
                            }
                        } else {
                            lineBuffer.append(byte)
                        }
                    }
                    // Flush any trailing line without a final newline.
                    if !lineBuffer.isEmpty {
                        let line = String(bytes: lineBuffer, encoding: .utf8) ?? ""
                        let trimmed = line.hasSuffix("\r") ? String(line.dropLast()) : line
                        if !trimmed.isEmpty {
                            if !blockBuffer.isEmpty { blockBuffer += "\n" }
                            blockBuffer += trimmed
                        }
                    }
                    // Flush any trailing block without a final blank line.
                    if !blockBuffer.isEmpty {
                        let event = try Self.parseBlock(blockBuffer)
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Parses a single SSE event block (one or more `event:` / `data:` lines, no trailing blank).
    public static func parseBlock(_ block: String) throws -> Event {
        var eventName = "message"
        var dataLines: [String] = []
        for line in block.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("event: ") {
                eventName = String(line.dropFirst("event: ".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data: ") {
                dataLines.append(String(line.dropFirst("data: ".count)))
            }
        }
        let data = Data(dataLines.joined(separator: "\n").utf8)

        switch eventName {
        case "status":
            return .status(try JSONDecoder().decode(StatusPayload.self, from: data))
        case "claim_final":
            return .claimFinal(try JSONDecoder().decode(Claim.self, from: data))
        case "receipt_final":
            return .receiptFinal(try JSONDecoder().decode(ReceiptFinalPayload.self, from: data))
        case "error":
            return .error(try JSONDecoder().decode(ErrorPayload.self, from: data))
        default:
            throw APIError.decoding(message: "unknown SSE event: \(eventName)")
        }
    }
}
