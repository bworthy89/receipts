import Testing
import SwiftUI
@testable import DesignSystem

@Suite("MotionMode")
struct MotionModeTests {

    @Test("from(reduceMotion: false) returns .full")
    func fromFull() {
        #expect(MotionMode.from(reduceMotion: false) == .full)
    }

    @Test("from(reduceMotion: true) returns .reduced")
    func fromReduced() {
        #expect(MotionMode.from(reduceMotion: true) == .reduced)
    }

    @Test("MotionMode is Sendable")
    func sendable() {
        // Compile-time check — the test passes as long as it compiles.
        let mode: any Sendable = MotionMode.full
        _ = mode
    }
}
