import Foundation

public struct Fax: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sourceURL: String
    public let sourceType: SourceType
    public let sourceProvider: SourceProvider
    public let title: String?
    public let status: Status
    public let finalVerdict: Verdict?
    public let finalCommentary: String?
    public let errorCode: String?
    public let createdAt: Int
    public let finishedAt: Int?
    public let claims: [Claim]

    public enum Status: String, Codable, Sendable, Equatable {
        case pending, streaming, done, failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sourceURL = "source_url"
        case sourceType = "source_type"
        case sourceProvider = "source_provider"
        case title, status
        case finalVerdict = "final_verdict"
        case finalCommentary = "final_commentary"
        case errorCode = "error_code"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
        case claims
    }

    public init(
        id: String,
        sourceURL: String,
        sourceType: SourceType,
        sourceProvider: SourceProvider,
        title: String?,
        status: Status,
        finalVerdict: Verdict?,
        finalCommentary: String?,
        errorCode: String?,
        createdAt: Int,
        finishedAt: Int?,
        claims: [Claim]
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceType = sourceType
        self.sourceProvider = sourceProvider
        self.title = title
        self.status = status
        self.finalVerdict = finalVerdict
        self.finalCommentary = finalCommentary
        self.errorCode = errorCode
        self.createdAt = createdAt
        self.finishedAt = finishedAt
        self.claims = claims
    }
}
