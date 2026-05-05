import Testing
@testable import ForRealKit

@Suite("ForRealKit smoke")
struct ForRealKitSmokeTests {
    @Test("version string is non-empty")
    func versionStringIsNonEmpty() {
        #expect(!ForRealKit.version.isEmpty)
    }
}
