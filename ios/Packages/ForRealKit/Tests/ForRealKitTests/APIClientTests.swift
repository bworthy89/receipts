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

@Suite("APIClient — postFax (live network)")
struct APIClientPostFaxTests {

    @Test("creates a fresh pending fax for a YouTube URL")
    func freshURL() async throws {
        let device = "test-device-fr-post-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        let result = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-fresh-\(UUID().uuidString)")

        #expect(!result.receiptID.isEmpty)
        #expect(result.status == "pending")
        #expect(result.cached == false)
    }

    @Test("returns cached for a re-paste of a known URL")
    func cachedURL() async throws {
        let url = "https://www.youtube.com/watch?v=fr-cache-\(UUID().uuidString)"
        let deviceA = "test-device-fr-post-A-\(Int.random(in: 100_000...999_999))"
        let deviceB = "test-device-fr-post-B-\(Int.random(in: 100_000...999_999))"

        let first = try await APIClient(environment: .dev, deviceID: deviceA).postFax(url: url)
        let second = try await APIClient(environment: .dev, deviceID: deviceB).postFax(url: url)

        #expect(first.receiptID == second.receiptID)
        #expect(second.cached == true)
    }

    @Test("422s on Instagram (unsupported provider)")
    func unsupportedProvider() async throws {
        let client = APIClient(environment: .dev, deviceID: "test-device-fr-instagram")
        do {
            _ = try await client.postFax(url: "https://www.instagram.com/reel/abc/")
            Issue.record("expected APIError.unsupportedProvider")
        } catch APIError.unsupportedProvider {
            // expected
        }
    }
}

@Suite("APIClient — list + delete (live network)")
struct APIClientListDeleteTests {

    @Test("list returns the calling device's faxes")
    func listForDevice() async throws {
        let device = "test-device-fr-list-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        _ = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-list-\(UUID().uuidString)")

        let summaries = try await client.listFaxes(limit: 10, before: nil)
        #expect(!summaries.isEmpty)
    }

    @Test("delete unlinks a fax owned by the device")
    func deleteOwnFax() async throws {
        let device = "test-device-fr-delete-\(Int.random(in: 100_000...999_999))"
        let client = APIClient(environment: .dev, deviceID: device)
        let result = try await client.postFax(url: "https://www.youtube.com/watch?v=fr-delete-\(UUID().uuidString)")

        try await client.deleteFax(id: result.receiptID)

        // After delete, listing should not show it.
        let summaries = try await client.listFaxes(limit: 10, before: nil)
        #expect(!summaries.contains { $0.id == result.receiptID })
    }

    @Test("delete on missing id throws notFound")
    func deleteMissingID() async throws {
        let client = APIClient(environment: .dev, deviceID: "test-device-fr-delete-missing")
        do {
            try await client.deleteFax(id: "00000000-0000-0000-0000-000000000000")
            Issue.record("expected APIError.notFound")
        } catch APIError.notFound {
            // expected
        }
    }
}
