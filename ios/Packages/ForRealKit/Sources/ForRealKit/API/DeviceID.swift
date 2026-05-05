import Foundation
#if canImport(Security)
import Security
#endif

public protocol DeviceIDStore: Sendable {
    func read() -> String?
    func write(_ id: String)
}

public enum DeviceID {

    /// Resolves the device's stable ID, generating + persisting one if none exists.
    public static func resolve(store: any DeviceIDStore = KeychainDeviceIDStore()) -> String {
        if let existing = store.read() { return existing }
        let fresh = UUID().uuidString
        store.write(fresh)
        return fresh
    }
}

#if canImport(Security)
public final class KeychainDeviceIDStore: DeviceIDStore, Sendable {

    private let service = "com.bworthy.forreal.device-id"
    private let account = "default"

    public init() {}

    public func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
            kSecReturnData as String:      true,
            kSecMatchLimit as String:      kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    public func write(_ id: String) {
        let data = Data(id.utf8)
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String]   = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }
}
#else
public final class KeychainDeviceIDStore: DeviceIDStore, Sendable {
    public init() {}
    public func read() -> String? { nil }
    public func write(_ id: String) {}
}
#endif
