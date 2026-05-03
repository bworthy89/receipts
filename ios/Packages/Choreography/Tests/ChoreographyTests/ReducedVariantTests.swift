import Testing
import SwiftUI
@testable import Choreography

/// Smoke tests for the Reduce Motion surface: every effect view can be
/// constructed with the default natural duration AND with a per-call delay /
/// duration override, the internal `\.choreographyReducedMotion` env key
/// exists with the expected default, and the `.pinDrop()` convenience modifier
/// is reachable.
///
/// True visual equivalence between full and reduced variants is a runtime
/// concern (it depends on the SwiftUI render path on a real device) and lives
/// in the simulator test plan in PR #5. These tests guard against silent API
/// regressions that would let a future commit drop a parameter or remove the
/// env key without anyone noticing.
@Suite("Reduced variant API surface")
@MainActor
struct ReducedVariantTests {

    /// `\.choreographyReducedMotion` defaults to nil — meaning "follow the
    /// system `accessibilityReduceMotion` setting". Internal env key, set
    /// only by the catalog cell's per-cell override.
    @Test("choreographyReducedMotion defaults to nil")
    func envDefaultsToNil() {
        let env = EnvironmentValues()
        #expect(env.choreographyReducedMotion == nil)
    }

    /// Round-trip: an explicit override sets and reads back through the env.
    @Test("choreographyReducedMotion is read/write")
    func envRoundTrip() {
        var env = EnvironmentValues()
        env.choreographyReducedMotion = true
        #expect(env.choreographyReducedMotion == true)
        env.choreographyReducedMotion = false
        #expect(env.choreographyReducedMotion == false)
        env.choreographyReducedMotion = nil
        #expect(env.choreographyReducedMotion == nil)
    }

    // MARK: Effect-view smoke
    //
    // Each effect must accept default params, a per-call delay, and a per-call
    // duration override — the on-mount stagger pattern depends on every effect
    // exposing `delay:`, and Daily Briefing / Deep Check sequencer code will
    // depend on `duration:` being available everywhere.
    //
    // We only verify the constructors compile and produce a SwiftUI View. The
    // motion behavior itself is exercised in the simulator test plan.

    @Test("PinDrop accepts default, delay, and duration")
    func pinDropConstructors() {
        let _: any View = PinDrop { Text("x") }
        let _: any View = PinDrop(delay: .milliseconds(80)) { Text("x") }
        let _: any View = PinDrop(
            delay: .milliseconds(80),
            duration: .milliseconds(400)
        ) { Text("x") }
    }

    @Test(".pinDrop() modifier is reachable")
    func pinDropModifier() {
        let _: any View = Text("x").pinDrop()
        let _: any View = Text("x").pinDrop(delay: .milliseconds(80))
        let _: any View = Text("x").pinDrop(
            delay: .milliseconds(80),
            duration: .milliseconds(400)
        )
    }

    @Test("RedString accepts delay (the regression fix in 6df838f → next)")
    func redStringConstructors() {
        let _: any View = RedString(from: "a", to: "b")
        let _: any View = RedString(from: "a", to: "b", sag: 12)
        let _: any View = RedString(from: "a", to: "b", delay: .milliseconds(80))
        let _: any View = RedString(
            from: "a",
            to: "b",
            sag: 4,
            delay: .milliseconds(80),
            duration: .milliseconds(600)
        )
    }

    @Test("PolaroidDevelop accepts default, delay, and duration")
    func polaroidConstructors() {
        let _: any View = PolaroidDevelop { Color.gray }
        let _: any View = PolaroidDevelop(delay: .milliseconds(80)) { Color.gray }
        let _: any View = PolaroidDevelop(
            delay: .milliseconds(80),
            duration: .milliseconds(1200)
        ) { Color.gray }
    }

    @Test("StampSlam accepts default, delay, and duration")
    func stampSlamConstructors() {
        let _: any View = StampSlam(inscription: "CONFIRMED") { Text("x") }
        let _: any View = StampSlam(
            inscription: "CONFIRMED",
            angle: .degrees(8)
        ) { Text("x") }
        let _: any View = StampSlam(
            inscription: "CONFIRMED",
            angle: .degrees(8),
            delay: .milliseconds(80)
        ) { Text("x") }
        let _: any View = StampSlam(
            inscription: "CONFIRMED",
            angle: .degrees(8),
            delay: .milliseconds(80),
            duration: .milliseconds(400)
        ) { Text("x") }
    }

    /// `ChoreographyBoard` is the public container that resolves anchors and
    /// renders RedString overlays. Smoke that it composes around arbitrary
    /// content.
    @Test("ChoreographyBoard wraps content")
    func boardWrapsContent() {
        let _: any View = ChoreographyBoard {
            VStack {
                Text("a").choreographyAnchor("a")
                Text("b").choreographyAnchor("b")
                RedString(from: "a", to: "b")
            }
        }
    }
}
