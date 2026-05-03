// MARK: - On-The-Board elevation
//
// Per DESIGN.md §4 — depth comes from things being physically *on top of*
// other things, not from generic blue-tinted drop shadows. Most surfaces sit
// flat against the board; shadows belong only to objects that physically would
// cast them.
//
// Two named rules these modifiers enforce:
//   • The On-The-Board Rule — resting elements are pinned, not floating.
//     Default elevation is low and warm-tinted, not generic Material elevation 4.
//   • The Lift-On-Touch Rule — heavy shadows are reserved for elements actively
//     being manipulated. Never on idle UI.
//
// Dim Room dark mode bumps shadow opacity automatically — under low light the
// cork-substrate luminance is only ~0.30, so a "shadow" with light-mode opacity
// would barely register. The ShadowScheme view modifier reads the current
// color scheme and picks scheme-appropriate opacities.

import SwiftUI

extension View {

    /// Pinned-card shadow — small, soft, slightly-offset shadow under a paper
    /// card pinned to cork. Tight blur, low offset. The card is *on* the
    /// board, not floating above it.
    public func pinnedCardShadow() -> some View {
        modifier(PinnedCardShadowModifier())
    }

    /// Polaroid shadow — heavier than pinned-card, with clear asymmetry as if
    /// the polaroid is curling at one corner. Two-layer shadow for depth.
    public func polaroidShadow() -> some View {
        modifier(PolaroidShadowModifier())
    }

    /// Lifted-while-dragging shadow — appears ONLY during direct manipulation
    /// (the user is moving a pin, dragging a card to the archive). Significantly
    /// larger blur and offset; the card is "in your hand right now". Should
    /// never appear on idle UI — that's the Lift-On-Touch Rule.
    public func liftedShadow() -> some View {
        modifier(LiftedShadowModifier())
    }
}

private struct PinnedCardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.shadow(
            color: Color.shadowTint.opacity(scheme == .dark ? 0.55 : 0.30),
            radius: 4, x: 0, y: 2
        )
    }
}

private struct PolaroidShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.shadowTint.opacity(scheme == .dark ? 0.65 : 0.42),
                radius: 8, x: 3, y: 6
            )
            .shadow(
                color: Color.shadowTint.opacity(scheme == .dark ? 0.30 : 0.18),
                radius: 2, x: -2, y: 0
            )
    }
}

private struct LiftedShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.shadow(
            color: Color.shadowTint.opacity(scheme == .dark ? 0.80 : 0.55),
            radius: 18, x: 0, y: 12
        )
    }
}
