import Foundation
import SwiftData

@Model
public final class PersistedFax {
    @Attribute(.unique) public var id: String
    public var sourceURL: String
    public var sourceTypeRaw: String
    public var sourceProviderRaw: String
    public var title: String?
    public var statusRaw: String
    public var finalVerdictRaw: String?
    public var finalCommentary: String?
    public var errorCode: String?
    public var createdAt: Int
    public var finishedAt: Int?

    @Relationship(deleteRule: .cascade, inverse: \PersistedClaim.fax)
    public var claims: [PersistedClaim] = []

    public init(
        id: String, sourceURL: String, sourceTypeRaw: String, sourceProviderRaw: String,
        title: String?, statusRaw: String, finalVerdictRaw: String?, finalCommentary: String?,
        errorCode: String?, createdAt: Int, finishedAt: Int?
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.sourceTypeRaw = sourceTypeRaw
        self.sourceProviderRaw = sourceProviderRaw
        self.title = title
        self.statusRaw = statusRaw
        self.finalVerdictRaw = finalVerdictRaw
        self.finalCommentary = finalCommentary
        self.errorCode = errorCode
        self.createdAt = createdAt
        self.finishedAt = finishedAt
    }
}

@Model
public final class PersistedClaim {
    public var position: Int
    public var claimText: String
    public var verdictRaw: String
    public var commentary: String
    /// JSON-encoded array of {url,title}.
    public var sourcesJSON: String
    public var resolvedAt: Int
    public var fax: PersistedFax?

    public init(position: Int, claimText: String, verdictRaw: String, commentary: String,
                sourcesJSON: String, resolvedAt: Int) {
        self.position = position
        self.claimText = claimText
        self.verdictRaw = verdictRaw
        self.commentary = commentary
        self.sourcesJSON = sourcesJSON
        self.resolvedAt = resolvedAt
    }
}

@MainActor
public final class FaxStore {

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    public init(container: ModelContainer) {
        self.container = container
    }

    public func upsert(_ fax: Fax) throws {
        // If exists, delete its claims and update; otherwise insert.
        let id = fax.id
        let descriptor = FetchDescriptor<PersistedFax>(predicate: #Predicate { $0.id == id })
        if let existing = try context.fetch(descriptor).first {
            // Cascade-delete existing claims via SwiftData.
            for c in existing.claims { context.delete(c) }
            existing.sourceURL = fax.sourceURL
            existing.sourceTypeRaw = fax.sourceType.rawValue
            existing.sourceProviderRaw = fax.sourceProvider.rawValue
            existing.title = fax.title
            existing.statusRaw = fax.status.rawValue
            existing.finalVerdictRaw = fax.finalVerdict?.rawValue
            existing.finalCommentary = fax.finalCommentary
            existing.errorCode = fax.errorCode
            existing.createdAt = fax.createdAt
            existing.finishedAt = fax.finishedAt
            existing.claims = try fax.claims.map { try Self.persisted(from: $0, context: context) }
        } else {
            let row = PersistedFax(
                id: fax.id, sourceURL: fax.sourceURL,
                sourceTypeRaw: fax.sourceType.rawValue,
                sourceProviderRaw: fax.sourceProvider.rawValue,
                title: fax.title, statusRaw: fax.status.rawValue,
                finalVerdictRaw: fax.finalVerdict?.rawValue,
                finalCommentary: fax.finalCommentary,
                errorCode: fax.errorCode,
                createdAt: fax.createdAt, finishedAt: fax.finishedAt
            )
            context.insert(row)
            row.claims = try fax.claims.map { try Self.persisted(from: $0, context: context) }
        }
        try context.save()
    }

    public func fetch(id: String) throws -> Fax? {
        let descriptor = FetchDescriptor<PersistedFax>(predicate: #Predicate { $0.id == id })
        guard let row = try context.fetch(descriptor).first else { return nil }
        return try Self.fax(from: row)
    }

    public func listMostRecent(limit: Int) throws -> [Fax] {
        var descriptor = FetchDescriptor<PersistedFax>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { try Self.fax(from: $0) }
    }

    // MARK: - Bridges

    private static func persisted(from claim: Claim, context: ModelContext) throws -> PersistedClaim {
        let json = try JSONEncoder().encode(claim.sources)
        let p = PersistedClaim(
            position: claim.position,
            claimText: claim.claimText,
            verdictRaw: claim.verdict.rawValue,
            commentary: claim.commentary,
            sourcesJSON: String(data: json, encoding: .utf8) ?? "[]",
            resolvedAt: claim.resolvedAt ?? 0  // Tolerate missing resolved_at from SSE events.
        )
        context.insert(p)
        return p
    }

    private static func fax(from row: PersistedFax) throws -> Fax {
        let claims: [Claim] = try row.claims
            .sorted { $0.position < $1.position }
            .map {
                let sources = try JSONDecoder().decode([Claim.Source].self, from: Data($0.sourcesJSON.utf8))
                guard let verdict = Verdict(rawValue: $0.verdictRaw) else {
                    throw APIError.decoding(message: "bad verdict in store: \($0.verdictRaw)")
                }
                return Claim(
                    position: $0.position, claimText: $0.claimText, verdict: verdict,
                    commentary: $0.commentary, sources: sources, resolvedAt: $0.resolvedAt
                )
            }

        guard let sourceType = SourceType(rawValue: row.sourceTypeRaw),
              let sourceProvider = SourceProvider(rawValue: row.sourceProviderRaw),
              let status = Fax.Status(rawValue: row.statusRaw)
        else {
            throw APIError.decoding(message: "bad enum in store")
        }
        let finalVerdict = row.finalVerdictRaw.flatMap(Verdict.init(rawValue:))
        return Fax(
            id: row.id, sourceURL: row.sourceURL,
            sourceType: sourceType, sourceProvider: sourceProvider,
            title: row.title, status: status,
            finalVerdict: finalVerdict, finalCommentary: row.finalCommentary,
            errorCode: row.errorCode,
            createdAt: row.createdAt, finishedAt: row.finishedAt,
            claims: claims
        )
    }
}
