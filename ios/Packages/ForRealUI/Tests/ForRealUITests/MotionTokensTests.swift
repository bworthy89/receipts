import Testing
import SwiftUI
@testable import ForRealUI

@Suite("Motion tokens")
struct MotionTokensTests {

    @Test("durations are within the brief's 200–400ms range")
    func durationsInRange() {
        #expect(ForRealMotion.sheetUp.duration >= 0.2)
        #expect(ForRealMotion.sheetUp.duration <= 0.4)
        #expect(ForRealMotion.claimArrival.duration >= 0.2)
        #expect(ForRealMotion.claimArrival.duration <= 0.4)
        #expect(ForRealMotion.verdictPushIn.duration >= 0.2)
        #expect(ForRealMotion.verdictPushIn.duration <= 0.4)
    }

    @Test("reduce motion duration is short")
    func reduceMotionShort() {
        #expect(ForRealMotion.reduceMotionHighlight.duration <= 0.15)
    }
}
