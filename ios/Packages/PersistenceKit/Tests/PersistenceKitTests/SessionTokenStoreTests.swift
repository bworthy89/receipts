import Testing
import Foundation
@testable import PersistenceKit

@Suite("SessionTokenStore")
struct SessionTokenStoreTests {

    /// Each test uses a unique service string so the underlying Keychain rows don't collide.
    private func uniqueStore() -> SessionTokenStore {
        SessionTokenStore(service: "com.bworthy.receipts.tests.\(UUID().uuidString)")
    }

    @Test("currentToken returns nil when nothing stored")
    func emptyStoreReturnsNil() async {
        let store = uniqueStore()
        let token = await store.currentToken()
        #expect(token == nil)
    }

    @Test("save then currentToken returns the saved value")
    func roundTrip() async throws {
        let store = uniqueStore()
        try store.save("test.session.token")
        let token = await store.currentToken()
        #expect(token == "test.session.token")
        try store.clear()
    }

    @Test("save overwrites a previously saved token")
    func overwrite() async throws {
        let store = uniqueStore()
        try store.save("first")
        try store.save("second")
        let token = await store.currentToken()
        #expect(token == "second")
        try store.clear()
    }

    @Test("clear removes the stored token")
    func clearRemoves() async throws {
        let store = uniqueStore()
        try store.save("to-be-cleared")
        try store.clear()
        let token = await store.currentToken()
        #expect(token == nil)
    }
}
