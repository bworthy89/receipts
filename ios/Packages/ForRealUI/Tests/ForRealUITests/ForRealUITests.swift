import Testing
@testable import ForRealUI

@Suite("ForRealUI smoke")
struct ForRealUISmokeTests {
    @Test("version string is non-empty")
    func versionStringIsNonEmpty() {
        #expect(!ForRealUI.version.isEmpty)
    }
}
