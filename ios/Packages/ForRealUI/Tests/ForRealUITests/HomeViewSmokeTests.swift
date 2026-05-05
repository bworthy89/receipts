import Testing
import SwiftUI
@testable import ForRealUI

@Suite("HomeView smoke")
@MainActor
struct HomeViewSmokeTests {

    @Test("constructs without a clipboard URL")
    func defaultState() {
        #if os(iOS)
        let view = HomeView(
            clipboardURL: nil,
            onAnalyze: { _ in },
            onRecentTap: {}
        )
        let _: any View = view
        #endif
    }

    @Test("constructs with a clipboard URL (chip variant)")
    func clipboardState() {
        #if os(iOS)
        let view = HomeView(
            clipboardURL: "https://www.youtube.com/watch?v=abc",
            onAnalyze: { _ in },
            onRecentTap: {}
        )
        let _: any View = view
        #endif
    }
}
