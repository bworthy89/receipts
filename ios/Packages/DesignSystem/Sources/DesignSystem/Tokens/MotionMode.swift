// MARK: - MotionMode
//
// Project-wide Reduce Motion convention. DesignSystem itself doesn't animate,
// but Choreography and feature packages reach for `MotionMode` (read from the
// SwiftUI environment) and `motionVariant(full:reduced:)` to provide the
// per-animation static fallback PRODUCT.md mandates.
//
// Per the shape brief Q8-b: typed enum + helper, reads SwiftUI's native
// `accessibilityReduceMotion` value. No custom env state to maintain.
//
// The bar from PRODUCT.md: "a screen-reader user, a Reduce Motion user, and a
// sighted user with motion enabled all describe the same case state in the same
// detective language at the end of the same Deep Check."

import SwiftUI

public enum MotionMode: Sendable {
    /// Full theatrical motion — pin-drops with ricochet, red-string strokes,
    /// polaroid develops, stamp slams with shake.
    case full

    /// Reduce Motion variant — instant placement with subtle highlight, fade-in
    /// solid lines, immediate image reveals, labeled stamp without shake.
    /// Information conveyed is identical; vestibular cost is removed.
    case reduced

    /// Read the mode from a SwiftUI environment (the standard
    /// `accessibilityReduceMotion` value, mapped to this enum for ergonomics).
    public static func from(reduceMotion: Bool) -> MotionMode {
        reduceMotion ? .reduced : .full
    }
}

extension View {

    /// Pick between two view variants based on the current SwiftUI
    /// `accessibilityReduceMotion` environment value. The `full` and `reduced`
    /// closures must convey the same information — different presentation, same
    /// case-state outcome.
    ///
    /// ```swift
    /// content.motionVariant(
    ///     full:    { PinDrop(target: card) },
    ///     reduced: { card.overlay(PinHighlight()) }
    /// )
    /// ```
    public func motionVariant<Full: View, Reduced: View>(
        @ViewBuilder full: () -> Full,
        @ViewBuilder reduced: () -> Reduced
    ) -> some View {
        modifier(MotionVariantModifier(full: full(), reduced: reduced()))
    }
}

private struct MotionVariantModifier<Full: View, Reduced: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let full: Full
    let reduced: Reduced

    func body(content: Content) -> some View {
        // The `content` argument is ignored on purpose — `motionVariant` swaps
        // the WHOLE view, not decorates it. The two branches are the variants.
        if reduceMotion {
            reduced
        } else {
            full
        }
    }
}
