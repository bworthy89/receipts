// MARK: - RedString · "red strings between connected sources" — PRODUCT.md
// Product Purpose · "Red string is reserved for connection, verdict, and
// flag." — DESIGN.md §2 The Red-String Rule.
//
// Per the 2026-05-03 brief §3 anchor reference: "drawing red yarn between two
// pinned receipts by hand — visible stroke, slight sag at midpoint, lays-on-
// cork shadow underneath."
//
// 920ms · ease-out-expo. Stroke draws from the `from` anchor to the `to` anchor
// over the full duration. The path is a quadratic Bezier curve with a
// perpendicular sag at the midpoint, so the string drapes naturally rather
// than running ruler-straight. Continuous-pattern haptic twang fires at stroke
// completion (~860ms in).
//
// Reduce Motion variant: solid line fades in over 200ms, no stroke animation.
// Haptic twang still fires.
//
// API shape:
//   • `RedString(from:to:)` is a marker view that emits a request preference.
//   • `ChoreographyBoard` reads the preference + corresponding anchors from
//     `.choreographyAnchor("id")` and draws the actual stroke as an overlay.
//
// Per shape brief §10 open question — confirmed: anchors publish via SwiftUI's
// native `Anchor<CGPoint>`, resolved against the board's GeometryProxy at
// render time. No named CoordinateSpace required.

import SwiftUI
import DesignSystem

public struct RedString: View {

    private let from: String
    private let to: String
    private let sag: CGFloat
    private let duration: Duration

    /// Connect two pinned views inside a `ChoreographyBoard`.
    ///
    /// - Parameters:
    ///   - from: The id of the `.choreographyAnchor("...")` to start the string at.
    ///   - to: The id of the `.choreographyAnchor("...")` to end the string at.
    ///   - sag: Perpendicular drop at the path midpoint, in pt. Default 8pt
    ///     gives a "draped yarn" feel without crossing into "loose cable."
    ///   - duration: Override the natural duration. `nil` uses
    ///     `ChoreographyTiming.redString` (920ms).
    public init(
        from: String,
        to: String,
        sag: CGFloat = 8,
        duration: Duration? = nil
    ) {
        self.from = from
        self.to = to
        self.sag = sag
        self.duration = duration ?? ChoreographyTiming.redString
    }

    public var body: some View {
        // Marker view — takes no space, just emits the request half of the
        // bundled ChoreographyState preference. ChoreographyBoard's overlay
        // reads anchors + requests in one pass and draws the actual string.
        Color.clear
            .frame(width: 0, height: 0)
            .preference(
                key: ChoreographyStateKey.self,
                value: ChoreographyState(
                    anchors: [:],
                    requests: [
                        RedStringRequest(
                            id: "\(from)→\(to)",
                            from: from,
                            to: to,
                            sag: sag,
                            duration: duration
                        )
                    ]
                )
            )
    }
}

// MARK: - AnimatingRedString
//
// The actual stroke renderer, instantiated once per RedStringRequest by
// ChoreographyBoard's overlay. Owns its own progress state so each request
// animates independently and persists its settled state when geometry changes
// (e.g. parent layout shifts the anchored views).

struct AnimatingRedString: View {
    let start: CGPoint
    let end: CGPoint
    let sag: CGFloat
    let duration: Duration

    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.choreographyReducedMotion) private var motionOverride

    private var reduceMotion: Bool { motionOverride ?? systemReduceMotion }

    var body: some View {
        RedStringCurve(start: start, end: end, sag: sag)
            .trim(from: 0, to: progress)
            .stroke(
                Color.evidence,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
            // Warm-tinted on-cork shadow. DesignSystem's `shadowTint` is
            // package-internal, so reach for `ink` (which carries the same
            // warm trace chroma) at low opacity. Tight blur, small offset —
            // the string lays *on* the cork, not floating above it.
            .shadow(
                color: Color.ink.opacity(0.30),
                radius: 1.5, x: 0, y: 1.5
            )
            .task {
                // Single structured task — when the parent view disappears
                // mid-draw, `try await` propagates cancellation and the
                // twang haptic is NOT scheduled on a removed view.
                try? await play()
            }
    }

    private func play() async throws {
        if reduceMotion {
            withAnimation(.easeOut(duration: ChoreographyTiming.reducedDuration.seconds)) {
                progress = 1
            }
            try await Task.sleep(for: ChoreographyTiming.reducedDuration)
            await ReceiptsHaptic.redStringConnect()
            return
        }

        withAnimation(ChoreographyTiming.easeOutExpo(duration: duration)) {
            progress = 1
        }
        // Twang at ~93% through the stroke — late enough that it lands when
        // the eye sees the string snap taut, but not so late that it misses
        // the visual completion.
        try await Task.sleep(for: .seconds(duration.seconds * 0.93))
        await ReceiptsHaptic.redStringConnect()
    }
}

// MARK: - RedStringCurve
//
// A quadratic-Bezier path between two points with a perpendicular sag at the
// midpoint. Sag is computed perpendicular to the start-end line so the curve
// looks like draped string regardless of orientation (works for horizontal,
// diagonal, or vertical pairs).

struct RedStringCurve: Shape {
    var start: CGPoint
    var end: CGPoint
    var sag: CGFloat

    func path(in _: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: midpointWithSag)
        return path
    }

    private var midpointWithSag: CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return start }
        // Perpendicular unit vector. The naive 90° counter-clockwise rotation
        // (`perpX = -dy/length, perpY = dx/length`) sags downward only when
        // dx > 0 — for right-to-left connections it would flip the sag *up*,
        // visually defying gravity. Goal here is gravity simulation, not
        // pure perpendicular geometry, so flip the perpendicular when it
        // would point upward in screen space (+y is down on iOS).
        var perpX = -dy / length
        var perpY = dx / length
        if perpY < 0 {
            perpX = -perpX
            perpY = -perpY
        }
        let midX = (start.x + end.x) / 2 + perpX * sag
        let midY = (start.y + end.y) / 2 + perpY * sag
        return CGPoint(x: midX, y: midY)
    }
}
