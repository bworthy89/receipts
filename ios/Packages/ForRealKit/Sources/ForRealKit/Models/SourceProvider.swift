import Foundation

public enum SourceType: String, Codable, Sendable { case video, article }

public enum SourceProvider: String, Codable, Sendable {
    case tiktok, youtube, article
}
