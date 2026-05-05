#if os(iOS)
import SwiftUI

struct ClipboardChip: View {
    let url: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text("Check this link?")
                    .font(ForRealType.body.weight(.semibold))
                Text(truncated(url))
                    .forRealLabelStyle()
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(Color.lemonCharcoal)
        }
        .accessibilityLabel("Check this link in the clipboard")
        .accessibilityValue(url)
    }

    private func truncated(_ s: String) -> String {
        // The Label-style font already truncates; pass-through here keeps alignment consistent.
        s
    }
}
#endif
