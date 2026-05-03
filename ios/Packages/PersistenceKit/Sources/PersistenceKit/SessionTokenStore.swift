import Foundation
import APIClient

/// Reads, writes, and deletes the session token in the iOS Keychain.
/// Conforms to APIClient's SessionTokenProvider so the APIClient can pull tokens directly.
public final class SessionTokenStore: SessionTokenProvider, Sendable {
    private let storage: KeychainStorage

    public init(service: String = "com.bworthy.receipts.session", account: String = "current") {
        self.storage = KeychainStorage(service: service, account: account)
    }

    public func currentToken() async -> String? {
        guard let data = try? storage.read() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ token: String) throws {
        try storage.write(Data(token.utf8))
    }

    public func clear() throws {
        try storage.delete()
    }
}
