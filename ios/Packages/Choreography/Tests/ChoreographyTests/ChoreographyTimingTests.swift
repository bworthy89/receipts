import Testing
import SwiftUI
@testable import Choreography

@Suite("ChoreographyTiming")
struct ChoreographyTimingTests {

    /// Per-motion natural durations match the 2026-05-03 brief §8 cell labels.
    /// Hardcoded values; the brief is the source of truth.

    @Test("PinDrop natural duration is 628ms")
    func pinDropDuration() {
        #expect(ChoreographyTiming.pinDrop == .milliseconds(628))
    }

    @Test("RedString natural duration is 920ms")
    func redStringDuration() {
        #expect(ChoreographyTiming.redString == .milliseconds(920))
    }

    @Test("PolaroidDevelop natural duration is 1380ms")
    func polaroidDevelopDuration() {
        #expect(ChoreographyTiming.polaroidDevelop == .milliseconds(1380))
    }

    @Test("StampSlam natural duration is 460ms")
    func stampSlamDuration() {
        #expect(ChoreographyTiming.stampSlam == .milliseconds(460))
    }

    @Test("StampSlam kick duration is 120ms")
    func stampSlamKickDuration() {
        #expect(ChoreographyTiming.stampSlamKick == .milliseconds(120))
    }

    /// Reduce-Motion crossfade is 200ms — the carry-over from the
    /// 2026-05-02 brief Q5: "Reduce Motion variants pick `.snap` for
    /// everything." This is the snap value.
    @Test("Reduced variant duration is 200ms")
    func reducedDuration() {
        #expect(ChoreographyTiming.reducedDuration == .milliseconds(200))
    }

    /// Brief budget constraint: every full-motion duration is ≤1.4s, per the
    /// "Full theatrical (≤ 1.4s per motion)" timing posture chosen in shape.
    @Test("All natural durations fit the ≤1.4s theatrical budget")
    func budgetBound() {
        let budget: Duration = .milliseconds(1400)
        #expect(ChoreographyTiming.pinDrop <= budget)
        #expect(ChoreographyTiming.redString <= budget)
        #expect(ChoreographyTiming.polaroidDevelop <= budget)
        #expect(ChoreographyTiming.stampSlam + ChoreographyTiming.stampSlamKick <= budget)
    }

    /// Easing curves construct without crashing. Animation isn't Equatable,
    /// so we can't compare to an expected value — we just verify the factory
    /// returns something.
    @Test("Easing curve factories return Animation")
    func easingFactories() {
        let dur: Duration = .milliseconds(500)
        let _: Animation = ChoreographyTiming.easeOutQuart(duration: dur)
        let _: Animation = ChoreographyTiming.easeOutExpo(duration: dur)
        let _: Animation = ChoreographyTiming.easeInOut(duration: dur)
    }

    /// Duration → seconds conversion is what `Animation.timingCurve(...)`
    /// expects (Double).
    @Test("Duration.seconds converts whole and fractional seconds")
    func durationSecondsConversion() {
        #expect(Duration.seconds(1).seconds == 1.0)
        #expect(Duration.milliseconds(500).seconds == 0.5)
        #expect(Duration.milliseconds(1380).seconds == 1.380)
    }
}
