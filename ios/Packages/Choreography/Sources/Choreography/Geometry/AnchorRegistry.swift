// MARK: - ChoreographyBoard
//
// "draws connections between them in front of the reader" — PRODUCT.md Product
// Purpose. The connection is the trust mechanic; the geometry has to be
// declarative enough that feature code never reaches for raw CGPoints.
//
// Reads `ChoreographyStateKey` from `content` — a single bundled preference
// holding both anchors (where pinnable views are) and requests (which pairs
// the developer wants connected). Renders one `AnimatingRedString` overlay
// per request, resolving anchors to CGPoints via `geo[anchor]`.
//
// Why a board, not a modifier on CorkBoard:
//   - `CorkBoard` lives in DesignSystem and owns visual decoration (texture,
//     color, shadow). Geometry-resolution belongs to the motion package.
//   - Apps that want to use Choreography inside a custom container (archive
//     search results, a popover, etc.) wrap their content in
//     `ChoreographyBoard` independently.

import SwiftUI

public struct ChoreographyBoard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .overlayPreferenceValue(ChoreographyStateKey.self) { state in
                GeometryReader { geo in
                    ZStack {
                        ForEach(state.requests) { req in
                            if let fromAnchor = state.anchors[req.from],
                               let toAnchor = state.anchors[req.to] {
                                AnimatingRedString(
                                    start: geo[fromAnchor],
                                    end: geo[toAnchor],
                                    sag: req.sag,
                                    duration: req.duration
                                )
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - Internal: RedString request

/// One declared connection between two anchors. `RedString(from:to:)` views
/// emit these as part of the bundled `ChoreographyState` preference; the
/// board's overlay renders one `AnimatingRedString` per request.
struct RedStringRequest: Identifiable, Equatable {
    let id: String     // "from→to" — unique per pair
    let from: String
    let to: String
    let sag: CGFloat
    let duration: Duration
}
