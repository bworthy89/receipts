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

    public func postFax(url: String) async throws -> PostFaxResult {
        struct Body: Encodable { let url: String }
        return try await send(method: "POST", path: "/v1/receipts", body: Body(url: url))
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

    public struct PostFaxResult: Decodable, Sendable, Equatable {
        public let receiptID: String
        public let status: String
        public let cached: Bool

        enum CodingKeys: String, CodingKey {
            case receiptID = "receipt_id"
            case status
            case cached
        }
    }

    private struct EmptyBody: Encodable {}
}

// MARK: - FaxSummary

public struct FaxSummary: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sourceURL: String
    public let sourceType: SourceType
    public let sourceProvider: SourceProvider
    public let title: String?
    public let status: Fax.Status
    public let finalVerdict: Verdict?
    public let finalCommentary: String?
    public let createdAt: Int
    public let finishedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceURL = "source_url"
        case sourceType = "source_type"
        case sourceProvider = "source_provider"
        case title, status
        case finalVerdict = "final_verdict"
        case finalCommentary = "final_commentary"
        case createdAt = "created_at"
        case finishedAt = "finished_at"
    }
}

// MARK: - List + Delete

extension APIClient {

    public func listFaxes(limit: Int?, before: Int?) async throws -> [FaxSummary] {
        var components = URLComponents(url: environment.baseURL, resolvingAgainstBaseURL: false)!
        components.path = "/v1/receipts"
        var queryItems: [URLQueryItem] = []
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let before { queryItems.append(URLQueryItem(name: "before", value: "\(before)")) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else {
            throw APIError.transport(message: "failed to build list URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

        let (data, response): (Data, URLResponse)
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
                struct Wrapper: Decodable { let receipts: [FaxSummary] }
                let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
                return wrapper.receipts
            } catch {
                throw APIError.decoding(message: String(describing: error))
            }
        case 404: throw APIError.notFound
        case 403: throw APIError.forbidden
        default:  throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }

    public func deleteFax(id: String) async throws {
        var request = URLRequest(url: environment.baseURL.appendingPathComponent("/v1/receipts/\(id)"))
        request.httpMethod = "DELETE"
        request.setValue(deviceID, forHTTPHeaderField: "X-Receipts-Device")

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(message: String(describing: error))
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(message: "non-HTTP response")
        }
        switch http.statusCode {
        case 204: return
        case 404: throw APIError.notFound
        case 403: throw APIError.forbidden
        default:  throw APIError.http(status: http.statusCode, body: nil)
        }
    }
}
