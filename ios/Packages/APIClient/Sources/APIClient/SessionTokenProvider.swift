import Foundation

/// Supplies the session token for authenticated requests. Implemented by PersistenceKit
/// (Keychain-backed) in production and by inline test doubles in unit tests.
public protocol SessionTokenProvider: Sendable {
    func currentToken() async -> String?
}

/// A no-op provider for unauthenticated calls (e.g. `/health`, `/auth/apple`).
public struct NullSessionTokenProvider: SessionTokenProvider {
    public init() {}
    public func currentToken() async -> String? { nil }
}
