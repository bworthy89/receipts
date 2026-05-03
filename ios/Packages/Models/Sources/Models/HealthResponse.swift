import Foundation

public struct HealthResponse: Codable, Sendable, Equatable {
    public let ok: Bool
    public let service: String

    public init(ok: Bool, service: String) {
        self.ok = ok
        self.service = service
    }
}
