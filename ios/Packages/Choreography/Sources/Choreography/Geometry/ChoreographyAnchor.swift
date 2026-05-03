// MARK: - .choreographyAnchor("id")
//
// "PinDrops with weight, red-string draws between sources." — PRODUCT.md
// Brand Personality.
//
// Per the 2026-05-03 shape brief §5: anchors publish via SwiftUI's native
// `Anchor<CGPoint>` system, which `ChoreographyBoard` resolves against its
// own GeometryProxy at render time.
//
// Public surface is one modifier — `.choreographyAnchor(_:)` — and one
// container — `ChoreographyBoard { ... }` (in `AnchorRegistry.swift`).
// The bundled `ChoreographyStateKey` is internal so consumers can only
// interact with the system through the typed modifier and container.
//
// Why one bundled PreferenceKey instead of two (one for anchors, one for
// requests): SwiftUI's `overlayPreferenceValue` reads preferences from its
// receiver, and the receiver is the original `content`. Nesting two
// `overlayPreferenceValue` calls — outer for anchors, inner for requests —
// only reads requests from the inner closure's content (e.g. `Color.clear`),
// not from the original tree. Bundling the two halves into one
// `ChoreographyState` value lets a single `overlayPreferenceValue(...)` read
// both halves in one pass.

import SwiftUI

extension View {

    /// Mark this view as a named anchor that downstream `RedString` instances
    /// inside the same `ChoreographyBoard` can connect to.
    ///
    /// The anchor is taken at the view's center point. Pinned cards, source
    /// dossiers, and polaroids all use their geometric center — which matches
    /// where a real push-pin would visibly hold the artifact.
    ///
    /// ```swift
    /// ChoreographyBoard {
    ///     PaperSurface { ... }.choreographyAnchor("reuters")
    ///     PaperSurface { ... }.choreographyAnchor("ap")
    ///     RedString(from: "reuters", to: "ap")
    /// }
    /// ```
    public func choreographyAnchor(_ id: String) -> some View {
        anchorPreference(
            key: ChoreographyStateKey.self,
            value: .center
        ) { anchor in
            ChoreographyState(anchors: [id: anchor], requests: [])
        }
    }
}

// MARK: - Internal: bundled state preference

/// Bundle of anchors + RedString requests that flow up the view tree on a
/// single PreferenceKey. `.choreographyAnchor(_:)` contributes anchors; the
/// `RedString(from:to:)` marker view contributes requests.
struct ChoreographyState {
    var anchors: [String: Anchor<CGPoint>]
    var requests: [RedStringRequest]
}

struct ChoreographyStateKey: PreferenceKey {
    static let defaultValue = ChoreographyState(anchors: [:], requests: [])

    static func reduce(
        value: inout ChoreographyState,
        nextValue: () -> ChoreographyState
    ) {
        let next = nextValue()
        // Anchors: last-write-wins — two siblings sharing an id is a developer
        // error and merging is meaningless without a typed tiebreaker.
        value.anchors.merge(next.anchors, uniquingKeysWith: { _, new in new })
        // Requests: append. Each RedString call site is a distinct connection
        // and must survive into the rendered overlay.
        value.requests.append(contentsOf: next.requests)
    }
}
