import Testing
import Foundation
import SwiftData
@testable import ForRealKit

@Suite("FaxStore")
@MainActor
struct FaxStoreTests {

    private func makeStore() throws -> FaxStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PersistedFax.self, PersistedClaim.self,
            configurations: config
        )
        return FaxStore(container: container)
    }

    @Test("upsert + fetch round-trips a fax")
    func upsertFetch() throws {
        let store = try makeStore()
        let fax = sampleFax(id: "fax-x", verdict: .nope)
        try store.upsert(fax)

        let fetched = try store.fetch(id: "fax-x")
        #expect(fetched?.id == "fax-x")
        #expect(fetched?.finalVerdict == .nope)
        #expect(fetched?.claims.count == 3)
    }

    @Test("listMostRecent returns newest first")
    func listMostRecent() throws {
        let store = try makeStore()
        try store.upsert(sampleFax(id: "old", createdAt: 100))
        try store.upsert(sampleFax(id: "new", createdAt: 200))

        let list = try store.listMostRecent(limit: 10)
        #expect(list.map(\.id) == ["new", "old"])
    }

    @Test("upsert is idempotent on id")
    func upsertIdempotent() throws {
        let store = try makeStore()
        try store.upsert(sampleFax(id: "same", verdict: .nope))
        try store.upsert(sampleFax(id: "same", verdict: .yep))

        let list = try store.listMostRecent(limit: 10)
        #expect(list.count == 1)
        #expect(list.first?.finalVerdict == .yep)
    }

    private func sampleFax(id: String, verdict: Verdict = .nope, createdAt: Int = 1700000000) -> Fax {
        Fax(
            id: id,
            sourceURL: "https://yt/\(id)",
            sourceType: .video,
            sourceProvider: .youtube,
            title: nil,
            status: .done,
            finalVerdict: verdict,
            finalCommentary: "test",
            errorCode: nil,
            createdAt: createdAt,
            finishedAt: createdAt + 60,
            claims: (1...3).map {
                Claim(position: $0, claimText: "c\($0)", verdict: .nope, commentary: "no",
                      sources: [], resolvedAt: createdAt + $0)
            }
        )
    }
}
