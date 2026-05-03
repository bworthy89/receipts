import SwiftUI
import DailyBriefing

#if DEBUG
import APIClient
import Models
import DesignSystem
import Choreography
#endif

struct ContentView: View {
    var body: some View {
        NavigationStack {
            DailyBriefingScreen()
                .toolbar(.hidden, for: .navigationBar)
        }
        #if DEBUG
        .overlay(alignment: .bottomTrailing) {
            DevToolsButton()
                .padding()
        }
        #endif
    }
}

#if DEBUG
private struct DevToolsButton: View {
    @State private var showing = false

    var body: some View {
        Button {
            showing = true
        } label: {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 16, weight: .medium))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showing) { DevToolsSheet() }
    }
}

private struct DevToolsSheet: View {
    @State private var showingDS = false
    @State private var showingChoreography = false
    @State private var probe: ProbeStatus = .idle

    enum ProbeStatus: Sendable, Equatable {
        case idle
        case loading
        case success(HealthResponse)
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Catalogs") {
                    Button("DesignSystem Catalog") { showingDS = true }
                    Button("Choreography Catalog") { showingChoreography = true }
                }
                Section("API probe") {
                    switch probe {
                    case .idle:
                        Text("Tap to probe")
                            .foregroundStyle(.secondary)
                    case .loading:
                        ProgressView()
                    case .success(let response):
                        Text("ok=\(response.ok ? "true" : "false") · service=\(response.service)")
                            .font(.body.monospaced())
                    case .failure(let message):
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Button("Probe /health (dev)") {
                        Task { await runProbe() }
                    }
                }
            }
            .navigationTitle("Dev Tools")
        }
        .sheet(isPresented: $showingDS) { DesignSystemCatalog() }
        .sheet(isPresented: $showingChoreography) { ChoreographyCatalog() }
    }

    private func runProbe() async {
        probe = .loading
        let client = APIClient(environment: .dev)
        do {
            let response = try await client.health()
            probe = .success(response)
        } catch {
            probe = .failure(String(describing: error))
        }
    }
}
#endif

#Preview {
    ContentView()
}
