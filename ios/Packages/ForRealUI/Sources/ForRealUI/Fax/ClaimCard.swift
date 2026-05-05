#if os(iOS)
import SwiftUI
import ForRealKit

struct ClaimCard: View {
    let position: Int
    let claim: Claim?
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CLAIM \(position) OF 3").forRealLabelStyle()
                .foregroundStyle(Color.oliveAnchor)
            if let claim {
                populatedBody(claim)
                    .transition(reducedMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity))
            } else {
                Rectangle().fill(Color.lemonSage.opacity(0.45)).frame(height: 56)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func populatedBody(_ claim: Claim) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(claim.verdict.glyph).font(.system(size: 18))
            Text(claim.claimText)
                .font(ForRealType.headline)
                .foregroundStyle(Color.lemonCharcoal)
        }
        Text(claim.commentary)
            .font(ForRealType.body)
            .foregroundStyle(Color.lemonCharcoal.opacity(0.85))
    }
}
#endif
