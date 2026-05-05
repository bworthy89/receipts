import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Typography tokens")
struct TypographyTests {

    @Test("type scale is defined")
    func scaleDefined() {
        let _ = ForRealType.verdictDisplay
        let _ = ForRealType.headline
        let _ = ForRealType.body
        let _ = ForRealType.label
    }
}
