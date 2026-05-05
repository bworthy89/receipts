#if os(iOS)
import SwiftUI

public struct HomeView: View {
    public let clipboardURL: String?
    public let onAnalyze: (String) -> Void
    public let onRecentTap: () -> Void

    @State private var pasteText: String = ""
    @FocusState private var pasteFocused: Bool

    public init(
        clipboardURL: String?,
        onAnalyze: @escaping (String) -> Void,
        onRecentTap: @escaping () -> Void
    ) {
        self.clipboardURL = clipboardURL
        self.onAnalyze = onAnalyze
        self.onRecentTap = onRecentTap
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.zestyLemon.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                Text("Drop a link, bestie.")
                    .font(ForRealType.headline)
                    .foregroundStyle(Color.lemonCharcoal)
                    .accessibilityHeading(.h1)

                pasteBox
                    .padding(.horizontal, 24)

                if let clipboardURL {
                    ClipboardChip(url: clipboardURL) { onAnalyze(clipboardURL) }
                        .padding(.horizontal, 24)
                }

                Spacer()
                Spacer()
            }

            Button(action: onRecentTap) {
                Image(systemName: "tray.full")
                    .font(.system(size: 18, weight: .medium))
                    .padding(12)
                    .foregroundStyle(Color.lemonCharcoal)
            }
            .accessibilityLabel("Recent faxes")
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
    }

    private var pasteBox: some View {
        HStack(spacing: 12) {
            TextField("paste a link", text: $pasteText, axis: .vertical)
                .font(ForRealType.headline)
                .foregroundStyle(Color.lemonCharcoal)
                .focused($pasteFocused)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit(submitIfValid)

            if !pasteText.isEmpty {
                Button(action: submitIfValid) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                }
                .foregroundStyle(Color.oliveAnchor)
                .accessibilityLabel("Analyze")
            }
        }
        .padding(20)
        .background(Color.lemonCream, in: RoundedRectangle(cornerRadius: 8))
    }

    private func submitIfValid() {
        let trimmed = pasteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAnalyze(trimmed)
    }
}
#endif
