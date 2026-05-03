// MARK: - MotionMode
//
// Project-wide Reduce Motion convention. DesignSystem itself doesn't animate,
// but Choreography and feature packages reach for `MotionMode` (read from the
// SwiftUI environment) and `MotionVariant` to provide the per-animation static
// fallback PRODUCT.md mandates.
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

    /// Map a raw `accessibilityReduceMotion` boolean to this enum.
    public static func from(reduceMotion: Bool) -> MotionMode {
        reduceMotion ? .reduced : .full
    }
}

/// Render one of two view variants based on the SwiftUI
/// `accessibilityReduceMotion` environment value. The `full` and `reduced`
/// branches must convey the same information — different presentation, same
/// case-state outcome.
///
/// ```swift
/// MotionVariant(
///     full:    { PinDrop(target: card) },
///     reduced: { card.overlay(PinHighlight()) }
/// )
/// ```
///
/// This is a `View`, not a `ViewModifier`, on purpose: a modifier API like
/// `.motionVariant(full:reduced:)` reads as decorating the receiver, but the
/// implementation must throw the receiver away and pick one of the two
/// branches. Making the variant explicit at the call site keeps the
/// semantics honest.
public struct MotionVariant<Full: View, Reduced: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let full: () -> Full
    private let reduced: () -> Reduced

    public init(
        @ViewBuilder full: @escaping () -> Full,
        @ViewBuilder reduced: @escaping () -> Reduced
    ) {
        self.full = full
        self.reduced = reduced
    }

    public var body: some View {
        if reduceMotion {
            reduced()
        } else {
            full()
        }
    }
}
