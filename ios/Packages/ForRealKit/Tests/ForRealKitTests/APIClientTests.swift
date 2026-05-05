import Testing
import Foundation
@testable import ForRealKit

@Suite("APIClient — getFax (live network — requires deployed dev worker on :8787)")
struct APIClientGetFaxTests {

    @Test("404s for an unknown id")
    func unknownIdReturnsNotFound() async throws {
        let client = APIClient(environment: .dev, deviceID: "test-device-fr-iOS-1")
        do {
            _ = try await client.getFax(id: "00000000-0000-0000-0000-000000000000")
            Issue.record("expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        }
    }
}
