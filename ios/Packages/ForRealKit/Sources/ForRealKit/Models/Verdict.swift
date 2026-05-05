import Foundation

public enum Verdict: String, Codable, Sendable, CaseIterable, Hashable {
    case nope, mixed, yep, skip

    public var glyph: String {
        switch self {
        case .nope:  "❌"
        case .mixed: "🤷"
        case .yep:   "✅"
        case .skip:  "🤔"
        }
    }
}
