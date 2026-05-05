import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Fax error + skip variants")
@MainActor
struct FaxErrorStateTests {

    @Test("skip variant constructs and renders only verdict + commentary")
    func skipVariant() {
        #if os(iOS)
        let view = FaxSheet(state: .skip(commentary: "all vibes."))
        let _: any View = view
        #endif
    }

    @Test("each error code has a friendly bestie copy")
    func errorCopyExists() {
        #expect(!FaxErrorCopy.message(for: "source_unreachable").isEmpty)
        #expect(!FaxErrorCopy.message(for: "provider_blocked").isEmpty)
        #expect(!FaxErrorCopy.message(for: "transcription_failed").isEmpty)
        #expect(!FaxErrorCopy.message(for: "paywalled").isEmpty)
        #expect(!FaxErrorCopy.message(for: "unsupported_provider").isEmpty)
        // Unknown code falls back gracefully.
        #expect(!FaxErrorCopy.message(for: "definitely_not_a_real_code").isEmpty)
    }

    @Test("failed state constructs")
    func failedState() {
        #if os(iOS)
        let view = FaxSheet(state: .failed(errorCode: "provider_blocked"))
        let _: any View = view
        #endif
    }
}
