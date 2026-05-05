import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Color tokens")
struct ColorTokensTests {

    @Test("zesty lemon palette is defined")
    func paletteDefined() {
        let lemon = Color.zestyLemon
        let cream = Color.lemonCream
        let sage = Color.lemonSage
        let olive = Color.oliveAnchor
        let charcoal = Color.lemonCharcoal
        // Compile-time check is enough.
        _ = (lemon, cream, sage, olive, charcoal)
    }
}
