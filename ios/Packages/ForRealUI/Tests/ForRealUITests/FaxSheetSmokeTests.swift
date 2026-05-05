import Testing
import SwiftUI
@testable import ForRealUI
@testable import ForRealKit

@Suite("FaxSheet shell smoke")
@MainActor
struct FaxSheetSmokeTests {

    @Test("renders empty pre-allocated shell")
    func emptyShell() {
        #if os(iOS)
        let view = FaxSheet(state: .initial)
        let _: any View = view
        #endif
    }

    @Test("renders streaming with one claim")
    func partialStreaming() {
        #if os(iOS)
        let claim = Claim(position: 1, claimText: "x", verdict: .nope, commentary: "no", sources: [], resolvedAt: 0)
        let view = FaxSheet(state: .streaming(partial: [claim], finalVerdict: nil, finalCommentary: nil))
        let _: any View = view
        #endif
    }

    @Test("renders final state with three claims")
    func finalState() {
        #if os(iOS)
        let claims = (1...3).map {
            Claim(position: $0, claimText: "c\($0)", verdict: .nope, commentary: "no", sources: [], resolvedAt: 0)
        }
        let view = FaxSheet(state: .final(verdict: .nope, commentary: "bestie no", claims: claims))
        let _: any View = view
        #endif
    }
}
