#if os(iOS)
import SwiftUI
import ForRealKit

struct VerdictHeader: View {
    let verdict: Verdict?
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VERDICT").forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
            if let verdict {
                populated(verdict)
                    .transition(reducedMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity))
            } else {
                Text("…")
                    .font(ForRealType.verdictDisplay)
                    .foregroundStyle(Color.lemonCharcoal.opacity(0.25))
            }
        }
        // Override the parent FaxSheet's claimArrival curve with the brief's verdict push-in
        // curve (~280ms ease-out-quint) when the verdict transitions from nil to a value.
        .animation(
            reducedMotion ? ForRealMotion.reduceMotionHighlight.curve : ForRealMotion.verdictPushIn.curve,
            value: verdict
        )
    }

    @ViewBuilder
    private func populated(_ verdict: Verdict) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(verdict.rawValue.uppercased())
                .font(ForRealType.verdictDisplay)
                .foregroundStyle(Color.lemonCharcoal)
            Text(verdict.glyph).font(.system(size: 44))
        }
    }
}
#endif
