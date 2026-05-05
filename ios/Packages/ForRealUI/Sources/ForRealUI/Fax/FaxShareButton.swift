#if os(iOS)
import SwiftUI
import UIKit
import ForRealKit

public struct FaxShareButton: View {
    let verdict: Verdict
    let commentary: String
    let claims: [Claim]

    public init(verdict: Verdict, commentary: String, claims: [Claim]) {
        self.verdict = verdict
        self.commentary = commentary
        self.claims = claims
    }

    public var body: some View {
        ShareLink(item: rendered(), preview: SharePreview("My fax says \(verdict.rawValue)", image: rendered())) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(ForRealType.body.weight(.semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .foregroundStyle(Color.zestyLemon)
            .background(Color.lemonCharcoal, in: RoundedRectangle(cornerRadius: 6))
        }
        .accessibilityLabel("Share fax")
    }

    private func rendered() -> Image {
        let renderable = FaxRenderableForSharing(verdict: verdict, commentary: commentary, claims: claims)
        let renderer = ImageRenderer(content: renderable)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "exclamationmark.circle")
    }
}

/// A self-contained, screenshot-shaped layout used only for the share image.
struct FaxRenderableForSharing: View {
    let verdict: Verdict
    let commentary: String
    let claims: [Claim]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 4) {
                Text("VERDICT")
                    .forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verdict.rawValue.uppercased())
                        .font(ForRealType.verdictDisplay)
                    Text(verdict.glyph).font(.system(size: 56))
                }
                .foregroundStyle(Color.lemonCharcoal)
            }

            Text(commentary)
                .font(ForRealType.headline.weight(.regular))
                .foregroundStyle(Color.lemonCharcoal)

            VStack(spacing: 12) {
                ForEach(claims) { claim in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CLAIM \(claim.position) OF 3")
                            .forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
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
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Text("From For Real??")
                .forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
        }
        .padding(28)
        .frame(width: 1080, alignment: .leading)
        .background(Color.zestyLemon)
    }
}
#endif
