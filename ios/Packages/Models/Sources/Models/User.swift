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
/// Handles all JSON value kinds: null, bool, int, double, string, array, object.
public struct AnyCodable: Codable, Sendable, Equatable {
    public let value: any Sendable

    public init(_ value: some Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer() {
            if single.decodeNil() { value = NSNull(); return }
            if let bool = try? single.decode(Bool.self) { value = bool; return }
            if let int = try? single.decode(Int.self) { value = int; return }
            if let double = try? single.decode(Double.self) { value = double; return }
            if let string = try? single.decode(String.self) { value = string; return }
        }
        if var unkeyed = try? decoder.unkeyedContainer() {
            var array: [AnyCodable] = []
            while !unkeyed.isAtEnd {
                array.append(try unkeyed.decode(AnyCodable.self))
            }
            value = array
            return
        }
        if let keyed = try? decoder.container(keyedBy: AnyCodingKey.self) {
            var dict: [String: AnyCodable] = [:]
            for key in keyed.allKeys {
                dict[key.stringValue] = try keyed.decode(AnyCodable.self, forKey: key)
            }
            value = dict
            return
        }
        throw DecodingError.dataCorrupted(.init(
            codingPath: decoder.codingPath,
            debugDescription: "AnyCodable could not decode value as null/bool/int/double/string/array/object"
        ))
    }

    public func encode(to encoder: Encoder) throws {
        switch value {
        case is NSNull:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case let v as Bool:
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case let v as Int:
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case let v as Double:
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case let v as String:
            var container = encoder.singleValueContainer()
            try container.encode(v)
        case let v as [AnyCodable]:
            var container = encoder.unkeyedContainer()
            for element in v { try container.encode(element) }
        case let v as [String: AnyCodable]:
            var container = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, element) in v {
                try container.encode(element, forKey: AnyCodingKey(stringValue: key)!)
            }
        default:
            var container = encoder.singleValueContainer()
            throw EncodingError.invalidValue(value, .init(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable cannot encode \(type(of: value))"
            ))
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is NSNull, is NSNull): return true
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        case let (l as [AnyCodable], r as [AnyCodable]): return l == r
        case let (l as [String: AnyCodable], r as [String: AnyCodable]): return l == r
        default: return false
        }
    }
}

/// String-or-int CodingKey for decoding/encoding arbitrary keyed containers.
private struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
