import Foundation

public enum APIError: Error, Sendable, Equatable {
    case notFound
    case forbidden
    case unsupportedProvider
    case dailyCapReached(message: String)
    case http(status: Int, body: String?)
    case decoding(message: String)
    case transport(message: String)
}
