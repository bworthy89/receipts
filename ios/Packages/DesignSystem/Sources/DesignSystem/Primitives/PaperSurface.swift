// MARK: - PaperSurface
//
// Paper-white evidence card surface. Pinned to cork with the small, warm-tinted
// On-The-Board shadow (per DESIGN.md §4 — The On-The-Board Rule).
//
// PaperSurface is a substrate primitive — it gives a paper-on-cork rectangle.
// Feature packages compose it into PinnedCard, Polaroid, Source Dossier, etc.,
// adding their own pin graphic, rotation, and content.
//
// Per DESIGN.md §6 Don't: "use generic blue-gray Material drop shadows" —
// this primitive uses the warm-tinted pinnedCardShadow modifier.

import SwiftUI

public struct PaperSurface<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content

    public init(
        cornerRadius: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.paper)
            )
            .pinnedCardShadow()
    }
}
