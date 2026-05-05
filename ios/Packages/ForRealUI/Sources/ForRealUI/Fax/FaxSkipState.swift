#if os(iOS)
import SwiftUI
import ForRealKit

struct FaxSkipState: View {
    let commentary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VerdictHeader(verdict: .skip)
            Text(commentary)
                .font(ForRealType.headline.weight(.regular))
                .foregroundStyle(Color.lemonCharcoal)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
