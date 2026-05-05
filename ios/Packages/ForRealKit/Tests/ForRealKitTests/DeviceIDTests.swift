import Testing
import Foundation
@testable import ForRealKit

@Suite("DeviceID")
struct DeviceIDTests {

    @Test("generates a UUID-shaped string when none is stored")
    func generatesNewUUID() {
        let store = InMemoryDeviceIDStore()
        let id = DeviceID.resolve(store: store)
        #expect(id.count == 36)
        #expect(id.contains("-"))
    }

    @Test("returns the same id on subsequent calls")
    func stableAcrossCalls() {
        let store = InMemoryDeviceIDStore()
        let a = DeviceID.resolve(store: store)
        let b = DeviceID.resolve(store: store)
        #expect(a == b)
    }
}

final class InMemoryDeviceIDStore: DeviceIDStore, @unchecked Sendable {
    private var value: String?
    func read() -> String? { value }
    func write(_ id: String) { value = id }
}
