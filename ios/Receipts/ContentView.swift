import SwiftUI
import DailyBriefing

#if DEBUG
import APIClient
import Models
import DesignSystem
import Choreography
import DeepCheck
import Archive
#endif

struct ContentView: View {
    #if DEBUG
    @State private var debugDeepCheckCase: Models.Case? = nil
    @State private var debugShowArchive: Bool = false
    #endif

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
        // Launch-arg shortcut so the simulator screenshot harness can land
        // directly on Deep Check without needing to tap a pin. Pass
        // `-DeepCheckCaseID mock-headline-N` via `xcrun simctl launch`.
        .task {
            // Seed the archive with mock entries on first launch so the
            // ARCHIVE · N FILED footer appears non-empty during demo. Only
            // runs if the log is empty (never overwrites real investigations).
            ArchiveMockSeed.seedIfEmpty(.live())

            if let id = UserDefaults.standard.string(forKey: "DeepCheckCaseID") {
                let provider = DailyBriefing.MockProvider()
                if let cases = try? await provider.roster(for: Date()),
                   let match = cases.first(where: { $0.caseID == id }) {
                    debugDeepCheckCase = match
                }
            }
            if UserDefaults.standard.bool(forKey: "OpenArchive") {
                debugShowArchive = true
            }
        }
        .fullScreenCover(item: $debugDeepCheckCase) { kase in
            DeepCheckScreen(kase: kase) { debugDeepCheckCase = nil }
        }
        .fullScreenCover(isPresented: $debugShowArchive) {
            ArchiveScreen(onDismiss: { debugShowArchive = false })
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
