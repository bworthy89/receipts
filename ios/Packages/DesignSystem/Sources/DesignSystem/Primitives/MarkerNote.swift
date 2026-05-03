// MARK: - MarkerNote
//
// Marker overlay seasoning — post-it callouts, "PERSON OF INTEREST" stickers,
// archive marginalia.
//
// Per DESIGN.md §3 No-Costume-Type Rule: marker / handwritten faces are
// SEASONING, not structure. Appears on overlays, callouts, and stamp faces —
// NEVER on body, headlines, or controls.
//
// Per DESIGN.md §6 Don't: never ship the marker face inside body, headlines,
// controls, or anywhere a sighted user has to scan quickly. This component
// makes the right choice the easy choice — there's no `MarkerNote.body(...)`
// constructor on purpose.

import SwiftUI

public struct MarkerNote: View {
    private let text: String
    private let rotation: Angle

    /// `text`: the marker copy, typically short and uppercase ("PERSON OF INTEREST").
    /// `rotation`: small ±2-6° rotation creates the hand-stuck-on-with-tape feel.
    public init(_ text: String, rotation: Angle = .degrees(-3)) {
        self.text = text
        self.rotation = rotation
    }

    public var body: some View {
        Text(text)
            .font(.markerNote)
            .tracking(0.4)
            .foregroundStyle(Color.evidence)
            .padding(.horizontal, Spacing.tight)
            .padding(.vertical, 4)
            .background(
                Color.paper
                    .overlay(Color.evidence.opacity(0.06))
            )
            .rotationEffect(rotation)
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
    }
}
