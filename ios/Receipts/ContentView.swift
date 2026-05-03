import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Receipts")
                .font(.system(size: 28, weight: .semibold))
            Text("DEV PROBE — placeholder, not the real UI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
