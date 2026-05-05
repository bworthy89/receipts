import SwiftUI
import SwiftData
import ForRealKit

@main
struct ForRealApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [PersistedFax.self, PersistedClaim.self])
        }
    }
}
