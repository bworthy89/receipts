// MARK: - StoryText
//
// The "story voice" — headlines, dek, verdict copy on stamps, article body.
// Editorial serif, hierarchy through scale + weight contrast.
//
// Per DESIGN.md §3 Two-Voices Rule: editorial serif carries the *story*.
//
// Hierarchy levels mirror DESIGN.md §3:
//   • display  — top-of-case headlines, daily-briefing reveal type. Sparse.
//   • headline — story titles on the board.
//   • title    — card titles, section headers inside dossiers.
//   • body     — article body, source quotes, dek copy. ~1.5 line-height.
//
// Body text capped at 65–75ch via the `bodyMaxWidth` parameter (default 600pt
// ~75ch at body size). The shared design law: cap body line length at 65–75ch.

import SwiftUI

public struct StoryText: View {
    private let text: String
    private let level: Level
    private let color: Color
    private let maxBodyWidth: CGFloat

    public enum Level: Sendable {
        case display
        case headline
        case title
        case body
    }

    private init(
        _ text: String,
        level: Level,
        color: Color = .ink,
        maxBodyWidth: CGFloat = 600
    ) {
        self.text = text
        self.level = level
        self.color = color
        self.maxBodyWidth = maxBodyWidth
    }

    public static func display(_ text: String, color: Color = .ink) -> StoryText {
        StoryText(text, level: .display, color: color)
    }

    public static func headline(_ text: String, color: Color = .ink) -> StoryText {
        StoryText(text, level: .headline, color: color)
    }

    public static func title(_ text: String, color: Color = .ink) -> StoryText {
        StoryText(text, level: .title, color: color)
    }

    public static func body(_ text: String, color: Color = .ink, maxWidth: CGFloat = 600) -> StoryText {
        StoryText(text, level: .body, color: color, maxBodyWidth: maxWidth)
    }

    public var body: some View {
        Text(text)
            .font(font)
            .lineSpacing(level == .body ? 4 : 0)  // ~1.5 line-height for body
            .foregroundStyle(color)
            .frame(maxWidth: level == .body ? maxBodyWidth : nil, alignment: .leading)
    }

    private var font: Font {
        switch level {
        case .display: .storyDisplay
        case .headline: .storyHeadline
        case .title: .storyTitle
        case .body: .storyBody
        }
    }
}
