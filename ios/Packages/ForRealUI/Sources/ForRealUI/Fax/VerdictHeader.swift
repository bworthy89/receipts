#if os(iOS)
import SwiftUI
import ForRealKit

struct VerdictHeader: View {
    let verdict: Verdict?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VERDICT").forRealLabelStyle().foregroundStyle(Color.oliveAnchor)
            if let verdict {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(verdict.rawValue.uppercased())
                        .font(ForRealType.verdictDisplay)
                        .foregroundStyle(Color.lemonCharcoal)
                    Text(verdict.glyph).font(.system(size: 44))
                }
            } else {
                Text("…")
                    .font(ForRealType.verdictDisplay)
                    .foregroundStyle(Color.lemonCharcoal.opacity(0.25))
            }
        }
    }
}
#endif
