import SwiftUI
import APIClient
import Models
import DesignSystem

struct ContentView: View {
    @State private var status: ProbeStatus = .idle
    @State private var showingCatalog = false

    enum ProbeStatus: Sendable, Equatable {
        case idle
        case loading
        case success(HealthResponse)
        case failure(String)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Receipts")
                .font(.system(size: 32, weight: .semibold))
            Text("DEV PROBE")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            Divider()

            switch status {
            case .idle:
                Text("Tap to probe").font(.body)
            case .loading:
                ProgressView()
            case .success(let response):
                VStack(spacing: 4) {
                    Text("ok: \(response.ok ? "true" : "false")")
                    Text("service: \(response.service)")
                }
                .font(.body.monospaced())
            case .failure(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button("Probe /health (dev)") {
                Task { await runProbe() }
            }
            .buttonStyle(.borderedProminent)

            #if DEBUG
            Button("View DesignSystem Catalog") {
                showingCatalog = true
            }
            .buttonStyle(.bordered)
            #endif
        }
        .padding()
        .task {
            await runProbe()
        }
        #if DEBUG
        .sheet(isPresented: $showingCatalog) {
            DesignSystemCatalog()
        }
        #endif
    }

    private func runProbe() async {
        status = .loading
        let client = APIClient(environment: .dev)
        do {
            let response = try await client.health()
            status = .success(response)
        } catch {
            status = .failure(String(describing: error))
        }
    }
}

#Preview {
    ContentView()
}
