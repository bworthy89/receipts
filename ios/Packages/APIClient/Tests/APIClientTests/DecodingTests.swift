import Testing
import Foundation
@testable import APIClient

@Suite("API decoding (no network)")
struct DecodingTests {

    @Test("decodes /auth/apple response")
    func decodesAuthAppleResponse() throws {
        let json = """
        {
            "sessionToken": "abc.def.ghi",
            "user": {
                "id": "u1",
                "email": "u@example.com",
                "created_at": 1700000000,
                "pro_until": null,
                "feed_mode": "strict"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let result = try decoder.decode(AuthAppleResponse.self, from: json)

        #expect(result.sessionToken == "abc.def.ghi")
        #expect(result.user.id == "u1")
        #expect(result.user.feedMode == "strict")
    }

    @Test("encodes /me PATCH body using snake_case")
    func encodesPatchMeRequest() throws {
        let req = PatchMeRequest(feedMode: "balanced", selectedTopics: ["tech"])
        let data = try JSONEncoder().encode(req)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"feed_mode\":\"balanced\""))
        #expect(json.contains("\"selected_topics\":[\"tech\"]"))
        // Unset fields are dropped, not sent as null.
        #expect(!json.contains("excluded_outlets"))
    }

    @Test("baseURL points at the right host per environment")
    func environmentBaseURLs() {
        #expect(APIEnvironment.dev.baseURL.host() == "crimeboard-api.bworthy89.workers.dev")
        #expect(APIEnvironment.staging.baseURL.host() == "crimeboard-api-staging.bworthy89.workers.dev")
        #expect(APIEnvironment.production.baseURL.host() == "crimeboard-api-prod.bworthy89.workers.dev")
    }
}
