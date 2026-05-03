import Foundation
import Models

/// One of the three deployed environments. The iOS app ships pointed at `.production`;
/// during development it points at `.dev`.
public enum APIEnvironment: Sendable {
    case dev
    case staging
    case production

    public var baseURL: URL {
        switch self {
        case .dev:
            URL(string: "https://crimeboard-api.bworthy89.workers.dev")!
        case .staging:
            URL(string: "https://crimeboard-api-staging.bworthy89.workers.dev")!
        case .production:
            URL(string: "https://crimeboard-api-prod.bworthy89.workers.dev")!
        }
    }
}

/// Body type for `POST /auth/apple`. Wire format is snake_case (matches the rest of the API).
public struct AuthAppleRequest: Encodable, Sendable {
    public let identityToken: String

    public init(identityToken: String) {
        self.identityToken = identityToken
    }

    private enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
    }
}

/// Response from `POST /auth/apple`. Wire format is snake_case throughout.
public struct AuthAppleResponse: Decodable, Sendable {
    public let sessionToken: String
    public let user: AuthUser

    public struct AuthUser: Decodable, Sendable {
        public let id: String
        public let email: String?
        public let createdAt: Date
        public let proUntil: Date?
        public let feedMode: FeedMode

        private enum CodingKeys: String, CodingKey {
            case id, email
            case createdAt = "created_at"
            case proUntil = "pro_until"
            case feedMode = "feed_mode"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case user
    }
}

/// Body type for `PATCH /me`. All fields optional; only present ones are updated server-side.
public struct PatchMeRequest: Encodable, Sendable {
    public let feedMode: FeedMode?
    public let selectedTopics: [String]?
    public let selectedOutlets: [String]?
    public let excludedOutlets: [String]?

    public init(
        feedMode: FeedMode? = nil,
        selectedTopics: [String]? = nil,
        selectedOutlets: [String]? = nil,
        excludedOutlets: [String]? = nil
    ) {
        self.feedMode = feedMode
        self.selectedTopics = selectedTopics
        self.selectedOutlets = selectedOutlets
        self.excludedOutlets = excludedOutlets
    }

    private enum CodingKeys: String, CodingKey {
        case feedMode = "feed_mode"
        case selectedTopics = "selected_topics"
        case selectedOutlets = "selected_outlets"
        case excludedOutlets = "excluded_outlets"
    }
}
