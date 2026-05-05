import Foundation

public enum APIEnvironment: Sendable {
    case dev
    case staging
    case production
    case custom(URL)

    public var baseURL: URL {
        switch self {
        case .dev:        URL(string: "http://127.0.0.1:8787")!
        case .staging:    URL(string: "https://crimeboard-api-staging.workers.dev")!
        case .production: URL(string: "https://crimeboard-api.workers.dev")!
        case .custom(let url): url
        }
    }
}
