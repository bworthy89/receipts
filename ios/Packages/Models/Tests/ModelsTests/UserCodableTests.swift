import Testing
import Foundation
@testable import Models

@Suite("User Codable")
struct UserCodableTests {

    @Test("decodes a /me response with all fields populated")
    func decodesFullMeResponse() throws {
        let json = """
        {
            "id": "user-1",
            "email": "user@example.com",
            "created_at": 1700000000,
            "pro_until": null,
            "feed_mode": "strict",
            "selected_topics": ["politics", "tech"],
            "selected_outlets": ["nytimes"],
            "excluded_outlets": [],
            "notification_prefs": {"breaking": true}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: json)

        #expect(user.id == "user-1")
        #expect(user.email == "user@example.com")
        #expect(user.feedMode == .strict)
        #expect(user.selectedTopics == ["politics", "tech"])
        #expect(user.selectedOutlets == ["nytimes"])
        #expect(user.excludedOutlets.isEmpty)
        #expect(user.proUntil == nil)
        #expect(user.notificationPrefs["breaking"] == AnyCodable(true))
    }

    @Test("round-trips a User through encode/decode")
    func roundTrips() throws {
        let original = User(
            id: "user-2",
            email: "u2@example.com",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            feedMode: .balanced,
            selectedTopics: ["world"],
            selectedOutlets: ["bbc", "reuters"]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(User.self, from: data)

        #expect(decoded == original)
    }

    @Test("decodes nested arrays and objects inside notification_prefs")
    func decodesNestedNotificationPrefs() throws {
        let json = """
        {
            "id": "user-nested",
            "email": null,
            "created_at": 1700000000,
            "pro_until": null,
            "feed_mode": "balanced",
            "selected_topics": [],
            "selected_outlets": [],
            "excluded_outlets": [],
            "notification_prefs": {
                "breaking": true,
                "quiet_hours": [22, 7],
                "topics": {"politics": true, "sports": false}
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: json)

        #expect(user.notificationPrefs["breaking"] == AnyCodable(true))
        let quietArr = try #require(user.notificationPrefs["quiet_hours"]?.value as? [AnyCodable])
        #expect(quietArr.count == 2)
        #expect(quietArr[0] == AnyCodable(22))
        let topicsDict = try #require(user.notificationPrefs["topics"]?.value as? [String: AnyCodable])
        #expect(topicsDict["politics"] == AnyCodable(true))
    }

    @Test("accepts a minimal /auth/apple user payload (no prefs fields)")
    func decodesMinimalAuthUser() throws {
        // /auth/apple returns a subset; we model defaults for the missing fields.
        let json = """
        {
            "id": "user-3",
            "email": null,
            "created_at": 1700000000,
            "pro_until": null,
            "feed_mode": "strict",
            "selected_topics": [],
            "selected_outlets": [],
            "excluded_outlets": [],
            "notification_prefs": {}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: json)

        #expect(user.id == "user-3")
        #expect(user.email == nil)
    }
}
