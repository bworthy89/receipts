import Foundation

public struct User: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let email: String?
    public let createdAt: Date
    public let proUntil: Date?
    public let feedMode: FeedMode
    public let selectedTopics: [String]
    public let selectedOutlets: [String]
    public let excludedOutlets: [String]
    public let notificationPrefs: [String: AnyCodable]

    public init(
        id: String,
        email: String? = nil,
        createdAt: Date,
        proUntil: Date? = nil,
        feedMode: FeedMode = .strict,
        selectedTopics: [String] = [],
        selectedOutlets: [String] = [],
        excludedOutlets: [String] = [],
        notificationPrefs: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.proUntil = proUntil
        self.feedMode = feedMode
        self.selectedTopics = selectedTopics
        self.selectedOutlets = selectedOutlets
        self.excludedOutlets = excludedOutlets
        self.notificationPrefs = notificationPrefs
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case proUntil = "pro_until"
        case feedMode = "feed_mode"
        case selectedTopics = "selected_topics"
        case selectedOutlets = "selected_outlets"
        case excludedOutlets = "excluded_outlets"
        case notificationPrefs = "notification_prefs"
    }
}

/// Type-erased Codable wrapper for arbitrary JSON values inside `notification_prefs`.
/// We can't model the full pref shape statically because it'll grow over time.
public struct AnyCodable: Codable, Sendable, Equatable {
    public let value: any Sendable

    public init(_ value: some Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) { value = bool; return }
        if let int = try? container.decode(Int.self) { value = int; return }
        if let double = try? container.decode(Double.self) { value = double; return }
        if let string = try? container.decode(String.self) { value = string; return }
        if container.decodeNil() { value = NSNull(); return }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "AnyCodable only supports primitive JSON values (bool, int, double, string, null)"
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case is NSNull: try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, .init(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable cannot encode \(type(of: value))"
            ))
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }
}
