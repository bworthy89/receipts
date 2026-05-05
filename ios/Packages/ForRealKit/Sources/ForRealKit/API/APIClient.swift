import Foundation

public final class APIClient: Sendable {
    public let environment: APIEnvironment
    public let deviceID: String
    private let session: URLSession

    public init(environment: APIEnvironment, deviceID: String, session: URLSession = .shared) {
        self.environment = environment
        self.deviceID = deviceID
        self.session = session
    }

    // MARK: - Endpoints

    public func getFax(id: String) async throws -> Fax {
        try await get("/v1/receipts/\(id)")
    }

    // MARK: - Internal

    func get<T: Decodable>(_ path: String) async throws -> T {
        try await send(method: "GET", path: path, body: Optional<EmptyBody>.none)
    }

    func send<B: Encodable, T: Decodable>(method: String, path: String, body: B?) async throws -> T {
        var request = URLRequest(url: environment.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(message: String(describing: error))
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(message: "non-HTTP response")
        }

        switch http.statusCode {
        case 200..<300:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }
        case 404:
            throw APIError.notFound
        case 403:
            throw APIError.forbidden
        case 422:
            throw APIError.unsupportedProvider
        case 429:
            let body = String(data: data, encoding: .utf8)
            throw APIError.dailyCapReached(message: body ?? "")
        default:
            throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }

    private struct EmptyBody: Encodable {}
}
