import SwiftUI
import SwiftData
import UIKit
import ForRealKit
import ForRealUI

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var coordinator: ReceiptCoordinator
    @State private var presentingFax = false
    @State private var clipboardURL: String?

    init() {
        // Real coordinator wired up here. The container used here is replaced when
        // the @Environment modelContext arrives via .modelContainer modifier on the
        // app — but having an initial in-memory placeholder lets @State init.
        let container = try! ModelContainer(
            for: PersistedFax.self, PersistedClaim.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = FaxStore(container: container)
        let deviceID = DeviceID.resolve()
        let client = APIClient(environment: .dev, deviceID: deviceID)
        let consumer = SSEStreamConsumer(environment: .dev, deviceID: deviceID)
        _coordinator = State(initialValue: ReceiptCoordinator(client: client, consumer: consumer, store: store))
    }

    var body: some View {
        HomeView(
            clipboardURL: clipboardURL,
            onAnalyze: { url in
                presentingFax = true
                Task { try? await coordinator.analyze(url: url) }
            },
            onRecentTap: {
                // Plan 6 fills this in.
            }
        )
        .task { await refreshClipboard() }
        .sheet(isPresented: $presentingFax, onDismiss: { coordinator.reset() }) {
            FaxSheet(
                state: .from(coordinator.state),
                onRetry: { presentingFax = false }   // Plan 5: retry dismisses the sheet so the user re-pastes.
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .overlay(alignment: .bottomTrailing) { DevToolsButton().padding() }
        #endif
    }

    @MainActor
    private func refreshClipboard() async {
        // UIPasteboard read requires user permission; only check on app open / foreground.
        if UIPasteboard.general.hasURLs, let url = UIPasteboard.general.url {
            clipboardURL = url.absoluteString
        }
    }
}

#if DEBUG
private struct DevToolsButton: View {
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 16, weight: .medium))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .foregroundStyle(Color.lemonCharcoal)
        }
        .sheet(isPresented: $showing) { DevToolsSheet() }
    }
}

private struct DevToolsSheet: View {
    @State private var posting = false
    @State private var lastReceiptID: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Dev — POST /v1/receipts") {
                    Button("Post a fresh YouTube URL") {
                        Task { await postFresh() }
                    }
                    .disabled(posting)
                    if posting { ProgressView() }
                    if let lastReceiptID { Text("receipt_id: \(lastReceiptID)").font(.caption.monospaced()) }
                    if let error { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Dev tools")
        }
    }

    private func postFresh() async {
        posting = true; defer { posting = false }
        let device = DeviceID.resolve()
        let client = APIClient(environment: .dev, deviceID: device)
        do {
            let r = try await client.postFax(url: "https://www.youtube.com/watch?v=dev-\(UUID().uuidString)")
            lastReceiptID = r.receiptID
            error = nil
        } catch {
            self.error = String(describing: error)
        }
    }
}
#endif
