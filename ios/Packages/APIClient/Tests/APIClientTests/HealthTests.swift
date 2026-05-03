import Testing
import Foundation
@testable import APIClient

@Suite("Health endpoint (live network — requires deployed dev worker)")
struct HealthTests {

    @Test("dev /health returns ok=true and service=crimeboard-api")
    func devHealth() async throws {
        let client = APIClient(environment: .dev)
        let response = try await client.health()
        #expect(response.ok == true)
        #expect(response.service == "crimeboard-api")
    }

    @Test("staging /health returns ok=true and service=crimeboard-api")
    func stagingHealth() async throws {
        let client = APIClient(environment: .staging)
        let response = try await client.health()
        #expect(response.ok == true)
        #expect(response.service == "crimeboard-api")
    }
}
