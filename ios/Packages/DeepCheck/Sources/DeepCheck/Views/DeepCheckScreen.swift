// MARK: - DeepCheckScreen
//
// Immersive single-case investigation surface. Cork-board substrate, central
// torn-paper headline pin, 5 manila-folder source pins fanning out around it
// in a hub-and-spoke arrangement, 5 red strings drawn from each source back
// to the central pin, and a verdict stamp slammed across the headline. An
// evidence dossier of pulled quotes sits below the fold.
//
// Per the 2026-05-03 brief:
//   • Entry: fullScreenCover from a DailyBriefing pin tap. (§7)
//   • Replay decision: InvestigationLog keyed by caseID. First tap plays;
//     subsequent skip. (§7)
//   • Choreography: lights-up + headline PinDrop + 5 source PinDrops
//     staggered 80ms + 5 PolaroidDevelops in parallel + 5 RedStrings
//     staggered 80ms + verdict StampSlam. ~5.5s budget. (§6)
//   • Below the fold: PULLED QUOTES dossier with serif quotes + mono
//     attribution. (§5)
//   • Custom × CLOSE affordance top-left. (§7)
//
// Two render paths: `PlayingBoard` for first-investigation cinematic, and
// `SettledBoard` for revisits. Both share the same source positions
// computed from `SourceLayout.layout`.

import SwiftUI
import Models
import DesignSystem
import Choreography

public struct DeepCheckScreen: View {

    private let kase: Case
    private let provider: any DeepCheckProvider
    private let log: InvestigationLog
    private let clock: @Sendable () -> Date
    private let onDismiss: @MainActor () -> Void

    @State private var loadState: LoadState = .loading
    @State private var willPlay: Bool = false
    @State private var openDossier: OpenDossier? = nil

    public init(
        kase: Case,
        provider: any DeepCheckProvider = MockProvider(),
        log: InvestigationLog = .live(),
        clock: @escaping @Sendable () -> Date = { Date() },
        onDismiss: @escaping @MainActor () -> Void
    ) {
        self.kase = kase
        self.provider = provider
        self.log = log
        self.clock = clock
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            CorkBoard {
                content
            }
            CloseButton(action: onDismiss)
                .padding(.leading, Spacing.cardPadding)
                .padding(.top, 12)
        }
        .task { await load() }
        .sheet(item: $openDossier) { d in
            SourceDossierSheet(
                source: d.source,
                kase: d.kase,
                appearanceCount: d.appearanceCount,
                totalCases: d.totalCases,
                onDismiss: { openDossier = nil }
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            VStack {
                Spacer()
                Text("Pulling the file…")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.pencil)
                Spacer()
            }
        case .ready(let investigation):
            ScrollView {
                VStack(spacing: 0) {
                    BoardSection(
                        investigation: investigation,
                        isPlaying: willPlay,
                        onSourceTap: { source in openSource(source, in: investigation) }
                    )
                    EvidenceDossier(investigation.evidence)
                }
            }
        case .error(let message):
            VStack {
                Spacer()
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.boardMargin)
                Button {
                    // Reset to .loading immediately on tap so the user sees
                    // the retry actually start; otherwise the error view
                    // hangs visually until the load finishes.
                    loadState = .loading
                    Task { await load(force: true) }
                } label: {
                    Text("TAP TO RETRY")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(Color.ink)
                        .padding(.top, Spacing.snug)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
    }

    private func load(force: Bool = false) async {
        // Always reset to .loading at the start of a load so retries
        // (force=true) get the same visual treatment as the initial fetch.
        loadState = .loading
        // Decide replay vs skip BEFORE the load — log read is synchronous
        // and we want the play/skip path locked in by the time the screen
        // composes. The marking happens AFTER load with the full archive
        // entry (case + verdict + investigated date), per the 2026-05-03
        // archive-shape brief §4 schema upgrade.
        willPlay = log.shouldPlay(caseID: kase.caseID)
        do {
            let inv = try await provider.investigation(for: kase)
            log.markInvestigated(
                ArchiveEntry(
                    caseID: kase.caseID,
                    caseNumber: kase.caseNumber,
                    headline: kase.headline,
                    verdict: inv.verdict,
                    investigatedOn: clock()
                )
            )
            loadState = .ready(inv)

            #if DEBUG
            // Screenshot harness shortcut: pass `-AutoOpenSourceOutlet
            // Reuters` via `xcrun simctl launch` to auto-raise the dossier
            // sheet on the matching source. Wait for the playback budget
            // (~5.5s) so the sheet doesn't pop on top of an animating board.
            if let outlet = UserDefaults.standard.string(forKey: "AutoOpenSourceOutlet"),
               let match = inv.sources.first(where: { $0.outlet == outlet }) {
                if willPlay {
                    try? await Task.sleep(for: .milliseconds(5_700))
                }
                openSource(match, in: inv)
            }
            #endif
        } catch {
            loadState = .error("Couldn't pull this file. Wire's down.")
        }
    }

    private func openSource(_ source: Source, in investigation: Investigation) {
        // Routes through the injected provider so a future swap (real
        // backend, in-memory test fixture, etc.) flows through the same
        // protocol as the investigation fetch.
        let count = provider.outletAppearanceCount(source.outlet)
        let total = provider.caseCount
        openDossier = OpenDossier(
            source: source,
            kase: investigation.kase,
            appearanceCount: count,
            totalCases: total
        )
    }

    private struct OpenDossier: Identifiable {
        var id: String { source.id }
        let source: Source
        let kase: Case
        let appearanceCount: Int
        let totalCases: Int
    }

    private enum LoadState: Equatable {
        case loading
        case ready(Investigation)
        case error(String)
    }
}

// MARK: - BoardSection

private struct BoardSection: View {
    let investigation: Investigation
    let isPlaying: Bool
    let onSourceTap: (Source) -> Void

    var body: some View {
        GeometryReader { geo in
            // Layout is sized to the actual source count rather than a
            // hardcoded 5. The brief commits to 5 sources for v1 mock data,
            // but any real provider returning a different count must not
            // crash on `placements[i]`.
            let placements = SourceLayout.layout(
                sourceCount: investigation.sources.count,
                seed: SourceLayout.seed(forCaseID: investigation.kase.caseID)
            )
            let hub = CGPoint(x: geo.size.width / 2, y: SourceLayout.Metrics.headlineY)

            Group {
                if isPlaying {
                    PlayingBoard(
                        investigation: investigation,
                        placements: placements,
                        hub: hub,
                        onSourceTap: onSourceTap
                    )
                } else {
                    SettledBoard(
                        investigation: investigation,
                        placements: placements,
                        hub: hub,
                        onSourceTap: onSourceTap
                    )
                }
            }
            .frame(width: geo.size.width, height: SourceLayout.boardHeight)
        }
        .frame(height: SourceLayout.boardHeight)
    }
}

// MARK: - PlayingBoard
//
// First-investigation cinematic. Choreography motions wrap each pin and
// drive the entrance sequence; ChoreographyBoard resolves anchors and
// renders the RedStrings.
//
// Sequence offsets (ms from screen-mount):
//   0     — lights-up overlay starts fading
//   0     — headline PinDrop begins
//   530   — source #0 PinDrop begins
//   610   — source #1
//   690   — source #2
//   770   — source #3
//   850   — source #4   (last source pinned ~1.5s in)
//   1500  — all 5 PolaroidDevelops begin in parallel  (1.4s, ends ~2.9s)
//   3000  — RedString #0 begins drawing
//   3080  — RedString #1
//   3160  — RedString #2
//   3240  — RedString #3
//   3320  — RedString #4   (last string completes ~4.25s)
//   4500  — verdict StampSlam begins  (slam 460ms; full settle ~5.0s)

private struct PlayingBoard: View {
    let investigation: Investigation
    let placements: [SourcePlacement]
    let hub: CGPoint
    let onSourceTap: (Source) -> Void

    var body: some View {
        ChoreographyBoard {
            ZStack(alignment: .topLeading) {
                // Sources first so the headline sits on top of any overlap.
                ForEach(Array(investigation.sources.enumerated()), id: \.element.id) { (i, source) in
                    let place = placements[i]
                    Button { onSourceTap(source) } label: {
                        PinDrop(delay: .milliseconds(530 + 80 * i)) {
                            PolaroidDevelop {
                                SourcePin(source)
                                    .rotationEffect(place.rotation)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .choreographyAnchor("source-\(i)")
                    .position(x: hub.x + place.offsetFromHub.width, y: hub.y + place.offsetFromHub.height)
                }

                // 5 red strings drawn from each source to the hub.
                ForEach(0..<min(5, investigation.sources.count), id: \.self) { i in
                    RedString(
                        from: "source-\(i)",
                        to: "hub",
                        sag: 8,
                        delay: .milliseconds(3000 + 80 * i)
                    )
                }

                // Headline + centerpiece verdict stamp at the hub.
                // Choreography's StampSlam uses .fileTitle (~15pt) which
                // reads as inline metadata, not as the climax of a 5-second
                // investigation. The centerpiece stamp here is much larger
                // (28pt) so the verdict moment lands visually.
                PinDrop(delay: .zero) {
                    HeadlinePin(investigation.kase)
                        .overlay(alignment: .center) {
                            CenterpieceVerdictStamp(text: investigation.verdict.rawValue)
                                .modifier(VerdictSlam(delay: .milliseconds(4500), staged: true))
                                .rotationEffect(.degrees(-7))
                                .offset(x: 8, y: 12)
                                .allowsHitTesting(false)
                        }
                }
                .choreographyAnchor("hub")
                .position(x: hub.x, y: hub.y)
            }
        }
    }
}

// MARK: - SettledBoard
//
// Revisit: render everything in its final state with no animation. Sources
// and headline render statically; red strings are drawn as plain bezier
// paths between computed centers (bypassing ChoreographyBoard's anchor
// resolution since we already know where everything will end up).

private struct SettledBoard: View {
    let investigation: Investigation
    let placements: [SourcePlacement]
    let hub: CGPoint
    let onSourceTap: (Source) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Strings first so they sit behind the pins.
            Canvas { context, _ in
                for (i, place) in placements.enumerated() where i < investigation.sources.count {
                    let from = CGPoint(
                        x: hub.x + place.offsetFromHub.width,
                        y: hub.y + place.offsetFromHub.height
                    )
                    let to = hub
                    var path = Path()
                    path.move(to: from)
                    let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2 + 6)
                    path.addQuadCurve(to: to, control: mid)
                    context.stroke(
                        path,
                        with: .color(Color.evidence),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                }
            }
            .frame(height: SourceLayout.boardHeight)
            // The strings are decorative; the source pins themselves carry
            // the relationship semantically via their accessibility labels.
            // Hiding the canvas keeps VoiceOver focused on the pins.
            .accessibilityHidden(true)

            // Sources.
            ForEach(Array(investigation.sources.enumerated()), id: \.element.id) { (i, source) in
                let place = placements[i]
                Button { onSourceTap(source) } label: {
                    SourcePin(source)
                        .rotationEffect(place.rotation)
                }
                .buttonStyle(.plain)
                .position(x: hub.x + place.offsetFromHub.width, y: hub.y + place.offsetFromHub.height)
            }

            // Headline + static centerpiece verdict overlay (no slam motion).
            HeadlinePin(investigation.kase)
                .overlay(alignment: .center) {
                    CenterpieceVerdictStamp(text: investigation.verdict.rawValue)
                        .rotationEffect(.degrees(-7))
                        .offset(x: 8, y: 12)
                        .allowsHitTesting(false)
                }
                .position(x: hub.x, y: hub.y)
        }
    }
}

// MARK: - CenterpieceVerdictStamp
//
// Larger verdict stamp tuned for the Deep Check climax. The brief frames
// this as "the verdict slamming the conclusion" — Choreography's built-in
// StampGraphic is sized for inline catalog use (~15pt mono) and doesn't
// dominate a centerpiece. This one is 28pt + heavier border so the verdict
// reads as the climax of the 5-second sequence.

private struct CenterpieceVerdictStamp: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .heavy, design: .monospaced))
            .tracking(3.0)
            .foregroundStyle(Color.evidence)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.evidence, lineWidth: 2.4)
            )
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.evidence.opacity(0.06))
            )
    }
}

// MARK: - VerdictSlam
//
// Local slam-on-appear modifier mirroring DailyBriefing's `SlamOnAppear` for
// the date stamp: scale 1.7 → 1.0 + opacity 0 → 1, ease-out-expo.
// Hardcoded constants because Choreography's `Duration.seconds` bridge is
// package-internal; if the brief's stamp duration changes, retune here.
//
// Plays once on first appear when `staged: true`. Settled-board renders
// pass `staged: false` so the stamp shows immediately at scale 1.0.

private struct VerdictSlam: ViewModifier {
    let delay: Duration
    let staged: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let slamSeconds: Double = 0.460
    private static let easeOutExpo: Animation = .timingCurve(0.16, 1.0, 0.3, 1.0, duration: 0.460)

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: staged, initial: true) { _, newValue in
                guard newValue else { return }
                if reduceMotion {
                    // Reduce Motion: snap to settled state immediately, no
                    // 4.5s opaque-to-zero hold. AGENTS.md mandates a
                    // meaningful Reduce Motion fallback — the verdict
                    // appearing in place is the meaningful equivalent of
                    // the slam. The earlier pin-drops + string-draws have
                    // their own per-effect reduced variants.
                    scale = 1.0
                    opacity = 1.0
                    return
                }
                // Full-motion path: arm at scale 1.7 + opacity 0, sleep
                // through the delay, then animate scale-down + fade-in.
                scale = 1.7
                opacity = 0
                Task { @MainActor in
                    try? await Task.sleep(for: delay)
                    withAnimation(Self.easeOutExpo) { scale = 1.0 }
                    withAnimation(.linear(duration: Self.slamSeconds * 0.22)) {
                        opacity = 1.0
                    }
                }
            }
    }
}

// MARK: - CloseButton

private struct CloseButton: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("×")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                Text("CLOSE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(1.6)
            }
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.paper.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Close Deep Check"))
    }
}
