// MARK: - MonoLabel
//
// The "file voice" — case numbers, timestamps, source IDs, stamp inscriptions,
// BiasMeter labels. The procedural metadata layer.
//
// Per DESIGN.md §3 Two-Voices Rule: monospace carries the *file*; ambiguous text
// (button labels, nav items) uses mono so the file voice anchors the chrome.
//
// Per DESIGN.md §3 Dynamic Type Honors The File Rule: mono labels scale with
// Dynamic Type the same as body. They're content, not chrome.

import SwiftUI

public struct MonoLabel: View {
    private let text: String
    private let style: Style
    private let color: Color

    public enum Style: Sendable {
        /// Default — `.fileLabel` (footnote, monospaced, medium).
        case standard
        /// Larger — `.fileTitle` (subheadline, monospaced, semibold). For stamp
        /// inscriptions when the stamp itself fills space.
        case prominent
    }

    public init(_ text: String, style: Style = .standard, color: Color = .pencil) {
        self.text = text
        self.style = style
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(font)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .lineLimit(2)
    }

    private var font: Font {
        switch style {
        case .standard: .fileLabel
        case .prominent: .fileTitle
        }
    }
}
