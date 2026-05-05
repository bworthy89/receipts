import Testing
import SwiftUI
@testable import ForRealUI
@testable import ForRealKit

@Suite("FaxShareButton")
@MainActor
struct FaxShareTests {

    @Test("constructs given a renderable fax")
    func constructs() {
        #if os(iOS)
        let claims = (1...3).map {
            Claim(position: $0, claimText: "x", verdict: .nope, commentary: "no", sources: [], resolvedAt: 0)
        }
        let view = FaxShareButton(verdict: .nope, commentary: "nope", claims: claims)
        let _: any View = view
        #endif
    }
}
