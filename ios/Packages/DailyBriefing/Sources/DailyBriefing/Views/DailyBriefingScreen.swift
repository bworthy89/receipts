// MARK: - DailyBriefingScreen
//
// The home surface. Cork-board substrate, ten torn-paper pins arranged in
// organic chaos, a slammed date stamp in the top-right corner. Re-stages
// once per day on cold launch — lights-up + StampSlam + 10 PinDrops with
// 80ms stagger; static thereafter.
//
// Per the 2026-05-03 brief §6 Key States and §7 Interaction Model.
//
// State machine:
//   .loading → "Pinning today's cases…" mono caption.
//   .roster([Case]) → the board.
//   .empty → centered "Quiet day on the beat. Allegedly." torn note.
//   .error(message) → centered torn note with retry tap.
//
// Staging decision is made once on first appear via StagingGate; cached for
// the lifetime of the view so backgrounding/foregrounding within a session
// does not re-stage. Per the brief: "App background/foreground within the
// same day = no replay."

import SwiftUI
import DesignSystem
import Choreography

public struct DailyBriefingScreen: View {

    private let provider: any DailyBriefingProvider
    private let stagingGate: StagingGate
    private let clock: @Sendable () -> Date

    @State private var state: ScreenState = .loading
    @State private var didStage: Bool = false
    @State private var rosterDate: Date = Date()

    /// Initialise the screen.
    /// - Parameters:
    ///   - provider: Roster source. Defaults to `MockProvider` until the real
    ///     backend wire is added.
    ///   - stagingGate: First-per-day gate. Defaults to a UserDefaults-backed
    ///     live gate.
    ///   - clock: Read fresh on every roster load so a long foreground
    ///     session that crosses midnight doesn't show yesterday's briefing
    ///     while the staging gate is firing for today. Tests inject a fixed
    ///     clock for determinism.
    public init(
        provider: any DailyBriefingProvider = MockProvider(),
        stagingGate: StagingGate = .live(),
        clock: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.provider = provider
        self.stagingGate = stagingGate
        self.clock = clock
    }

    public var body: some View {
        ZStack {
            CorkBoard {
                content
            }
            // Lights-up reveal: cork starts dim and fades to neutral. The
            // overlay is always present at first frame so there's no
            // pre-decision flash; the decision in `.task` either ramps the
            // overlay down (staging) or snaps it (not staging).
            //
            // Color.black overlay on the entire cork because a brightness
            // modifier on Color.cork doesn't lift cleanly under dark mode
            // (already dim) — an overlay opacity ramp does.
            Color.black
                .opacity(lightsUpOpacity)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .task { await loadIfNeeded() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            VStack {
                Spacer()
                MonoLabel("Pinning today's cases…", color: .pencil)
                Spacer()
            }
        case .roster(let cases):
            board(cases: cases)
        case .empty:
            centeredTornNote(message: "Quiet day on the beat. Allegedly.")
        case .error(let message):
            VStack(spacing: Spacing.snug) {
                centeredTornNote(message: message)
                Button {
                    state = .loading
                    Task { await loadIfNeeded(force: true) }
                } label: {
                    MonoLabel("Tap to retry", color: .ink)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Board

    private func board(cases: [Case]) -> some View {
        GeometryReader { geo in
            let placements = PinLayout.layout(
                count: cases.count,
                boardWidth: geo.size.width,
                seed: PinLayout.seed(for: rosterDate)
            )
            let contentHeight = PinLayout.contentHeight(forCount: cases.count)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(width: geo.size.width, height: contentHeight)

                    // Pins first, date stamp last so the stamp sits on top in
                    // z-order. The brief explicitly puts the stamp "slammed
                    // into the top-right corner" — i.e. on top of whatever
                    // happens to be behind it.
                    ForEach(Array(cases.enumerated()), id: \.element.id) { (index, kase) in
                        let placement = placements[index]
                        pin(kase, placement: placement, index: index, total: cases.count)
                    }

                    dateStamp
                        .position(x: geo.size.width - 90, y: 84)
                }
            }
        }
    }

    @ViewBuilder
    private var dateStamp: some View {
        // The DateStamp IS the stamp — we want it to slam (scale 1.6 → 1.0 +
        // opacity 0 → 1) on first-per-day. The modifier is unconditional but
        // it self-skips when `staged: false`, so the static-day case renders
        // immediately without the slam state.
        DateStamp(date: rosterDate)
            .modifier(SlamOnAppear(delay: .milliseconds(250), staged: didStage))
    }

    @ViewBuilder
    private func pin(_ kase: Case, placement: PinPlacement, index: Int, total: Int) -> some View {
        let note = TornNote(kase, position: index + 1, total: total)
            .rotationEffect(placement.rotation)

        NavigationLink {
            DeepCheckPlaceholder(kase)
        } label: {
            Group {
                if didStage {
                    // 80ms stagger after the date-stamp slam (which begins at
                    // 250ms and visually peaks ~400ms). First pin lands ~530ms
                    // in; tenth pin ~1.25s — within the brief's "≤1.4s budget".
                    PinDrop(delay: .milliseconds(530 + 80 * index)) { note }
                } else {
                    note
                }
            }
        }
        .buttonStyle(.plain)
        .position(x: placement.x, y: placement.y)
    }

    private func centeredTornNote(message: String) -> some View {
        VStack {
            Spacer()
            ZStack {
                TornPaperShape(seed: 1)
                    .fill(Color.paper)
                    .pinnedCardShadow()
                    .frame(width: 240, height: 110)
                StoryText.title(message)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 220)
            }
            Spacer()
        }
    }

    // MARK: - Lights-up

    @State private var lightsUpOpacity: Double = 0.65

    // MARK: - Loading

    private func loadIfNeeded(force: Bool = false) async {
        // Read the clock fresh every load so a long foreground session that
        // crosses midnight loads the new day's roster + layout seed; the
        // staging gate uses its own live clock for the same reason.
        let liveNow = clock()
        rosterDate = liveNow

        if !force {
            // Decide staging once on first arrival. The view always renders a
            // dimmer overlay at first frame; the next step either ramps it
            // down (staging) or snaps it (no staging today).
            didStage = stagingGate.shouldStage()
            if didStage {
                stagingGate.markStaged()
                withAnimation(.easeOut(duration: 0.55)) { lightsUpOpacity = 0 }
            } else {
                lightsUpOpacity = 0
            }
        }

        do {
            let cases = try await provider.roster(for: liveNow)
            if cases.isEmpty {
                state = .empty
            } else {
                state = .roster(cases)
            }
        } catch {
            state = .error("Wire's down. Try again in a minute.")
        }
    }

    // MARK: - State machine

    private enum ScreenState: Equatable {
        case loading
        case roster([Case])
        case empty
        case error(String)
    }
}

// MARK: - SlamOnAppear
//
// Local view modifier: scale-from-1.6 + opacity-from-0 on appear, mirroring
// the visual contract of `Choreography.StampSlam` but applied to the target
// itself (the DateStamp IS the stamp; we don't want an overlay on top of it).
//
// No haptic here — that's owned by the 10 pin landings, which collectively
// give the staging its tactile signature. Adding a stamp haptic on top would
// muddy the per-pin ricochet feedback.

private struct SlamOnAppear: ViewModifier {
    let delay: Duration
    let staged: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Slam timing mirrors `Choreography.ChoreographyTiming.stampSlam` (460ms).
    // Hardcoded as Double-seconds because Choreography's `Duration.seconds`
    // bridge is package-internal. If Choreography changes the slam duration,
    // re-tune this constant by hand.
    private static let slamSeconds: Double = 0.460

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: staged, initial: true) { _, newValue in
                guard newValue else { return }
                // Reset to slam-armed state, then play.
                scale = 1.6
                opacity = 0
                Task { @MainActor in
                    try? await Task.sleep(for: delay)
                    if reduceMotion {
                        scale = 1.0
                        opacity = 1.0
                        return
                    }
                    withAnimation(ChoreographyTiming.easeOutExpo(duration: .seconds(Self.slamSeconds))) {
                        scale = 1.0
                    }
                    withAnimation(.linear(duration: Self.slamSeconds * 0.22)) {
                        opacity = 1.0
                    }
                }
            }
    }
}
