import Foundation
import Models

/// Async network client for the receipts backend. Stateless except for its environment
/// configuration and a session-token provider. Safe to share across the app.
public final class APIClient: Sendable {
    public let environment: APIEnvironment
    private let session: URLSession
    private let tokenProvider: any SessionTokenProvider

    public init(
        environment: APIEnvironment,
        tokenProvider: any SessionTokenProvider = NullSessionTokenProvider(),
        session: URLSession = .shared
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.session = session
    }

    // MARK: - Endpoints

    public func health() async throws -> HealthResponse {
        try await get("/health")
    }

    public func signInWithApple(identityToken: String) async throws -> AuthAppleResponse {
        try await post("/auth/apple", body: AuthAppleRequest(identityToken: identityToken))
    }

    public func getMe() async throws -> User {
        try await get("/me")
    }

    public func patchMe(_ patch: PatchMeRequest) async throws -> User {
        try await self.patch("/me", body: patch)
    }

    // MARK: - Internals

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await send(method: "GET", path: path, body: Optional<EmptyBody>.none)
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await send(method: "POST", path: path, body: body)
    }

    private func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await send(method: "PATCH", path: path, body: body)
    }

    private struct EmptyBody: Encodable {}

    private func send<B: Encodable, T: Decodable>(
        method: String,
        path: String,
        body: B?
    ) async throws -> T {
        var request = URLRequest(url: environment.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = await tokenProvider.currentToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(message: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(message: "Non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.http(status: http.statusCode, body: bodyString)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(message: error.localizedDescription)
        }
    }
}
