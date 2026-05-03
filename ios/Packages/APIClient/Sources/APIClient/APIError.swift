import Foundation

public enum APIError: Error, Sendable, Equatable {
    /// Underlying transport failure (no network, DNS failure, TLS error, etc.).
    case transport(message: String)
    /// Server returned a non-2xx response.
    case http(status: Int, body: String)
    /// Server returned 2xx but the body didn't decode into the expected type.
    case decoding(message: String)
}
