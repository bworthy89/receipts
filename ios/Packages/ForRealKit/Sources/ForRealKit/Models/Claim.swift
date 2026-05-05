import Foundation

public struct Claim: Codable, Sendable, Equatable, Identifiable {
    public let position: Int
    public let claimText: String
    public let verdict: Verdict
    public let commentary: String
    public let sources: [Source]
    public let resolvedAt: Int?

    public var id: Int { position }

    public struct Source: Codable, Sendable, Equatable, Hashable {
        public let url: String
        public let title: String

        public init(url: String, title: String) {
            self.url = url
            self.title = title
        }
    }

    enum CodingKeys: String, CodingKey {
        case position
        case claimText = "claim_text"
        case verdict, commentary, sources
        case resolvedAt = "resolved_at"
    }

    public init(
        position: Int,
        claimText: String,
        verdict: Verdict,
        commentary: String,
        sources: [Source],
        resolvedAt: Int? = nil
    ) {
        self.position = position
        self.claimText = claimText
        self.verdict = verdict
        self.commentary = commentary
        self.sources = sources
        self.resolvedAt = resolvedAt
    }
}
