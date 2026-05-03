// MARK: - TornNote
//
// The pin: paper-white torn-edge note pinned to cork with a single push-pin,
// serial mono case-ID in the top-left corner, serif headline as the body,
// optional verdict stamp slammed across the page.
//
// Per the 2026-05-03 brief §3 anchor reference: "torn-paper note actually
// pinned on a real desk — gravity, weight, hand-torn edge."
//
// And §6 Already-investigated: "Pin shows post-Deep-Check verdict stamp
// slammed across the torn note (CONFIRMED / BUSTED / COLD CASE), slightly
// off-axis, ink-bleed edges. Headline still readable, paper still white. (No
// graying out — sovereignty rule: the user's work is more visible after
// they've done it, not less.)"
//
// Construction:
//   • TornPaperShape — Path with a clean top edge (notepad tear-off line),
//     irregular jagged bottom edge, and lightly-perturbed sides. Seeded per
//     pin so each note tears differently but stably.
//   • PushPin — small circular head with a soft inner highlight, no SF Symbol.
//   • Verdict overlay — static StampGraphic render for already-investigated.
//     The animated slam lives in Deep Check; on the briefing the stamp is
//     already there.

import SwiftUI
import DesignSystem

public struct TornNote: View {

    let kase: Case
    let position: Int
    let total: Int

    public init(_ kase: Case, position: Int, total: Int) {
        self.kase = kase
        self.position = position
        self.total = total
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            TornPaperShape(seed: paperSeed)
                .fill(Color.paper)
                .pinnedCardShadow()

            VStack(alignment: .leading, spacing: Spacing.hairline) {
                // Case-ID at 10pt per the brief §8 ("~10pt"). MonoLabel uses
                // .fileLabel (13pt) which is too wide for the 165pt note.
                Text(kase.caseNumber)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.pencil)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(kase.headline)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 22)
            .padding(.horizontal, 14)
            .padding(.bottom, 20)

            // Push pin at the top-center of the clean tear-off line.
            PushPin()
                .frame(width: 14, height: 14)
                .offset(x: TornPaperShape.nominalWidth / 2 - 7, y: -3)

            // Verdict stamp — static, slightly off-axis, slammed across the
            // bottom-right of the note where it intersects the headline edge
            // without obscuring the case-ID or the body. Rotation kept off-
            // axis enough to read as "stamped" without overwriting the text.
            if let verdict = kase.verdict {
                VerdictStamp(text: verdict.rawValue)
                    .rotationEffect(.degrees(-7))
                    .offset(x: TornPaperShape.nominalWidth - 100, y: TornPaperShape.nominalHeight - 50)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: TornPaperShape.nominalWidth, height: TornPaperShape.nominalHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityDescription))
    }

    /// Stable per-pin tear pattern — derived from the case ID via
    /// `SeededRNG.seed(from:)` rather than Swift's `Hasher` (which is
    /// process-randomized and would change the tear shape on every cold
    /// launch, breaking the stable-pattern guarantee).
    private var paperSeed: UInt64 {
        SeededRNG.seed(from: kase.caseID)
    }

    /// Per the 2026-05-03 brief §8 VoiceOver:
    ///   "Case [N] of 10. [Headline]. [state]. Double-tap to open."
    /// `position` and `total` are wired in by `DailyBriefingScreen` so
    /// VoiceOver users know how far through the board they are.
    private var accessibilityDescription: String {
        let stateClause: String
        switch kase.verdict {
        case .confirmed: stateClause = "Investigated, confirmed."
        case .busted:    stateClause = "Investigated, busted."
        case .coldCase:  stateClause = "Investigated, cold case."
        case nil:        stateClause = "Untouched."
        }
        return "Case \(position) of \(total). \(kase.headline). \(stateClause) Double-tap to open."
    }
}

// MARK: - TornPaperShape
//
// Hand-torn paper outline. Top edge is clean (notepad tear-off); bottom edge
// has small irregular spikes; sides have subtle inward/outward perturbations.
//
// Deterministic per seed so a given pin tears the same way across re-renders.

struct TornPaperShape: Shape {
    let seed: UInt64

    static let nominalWidth: CGFloat = 165
    static let nominalHeight: CGFloat = 145

    func path(in rect: CGRect) -> Path {
        var rng = SeededRNG(seed: seed)
        var path = Path()

        // Top: clean line.
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right side: 4 segments with small inward/outward jitter.
        let rightSegments = 4
        for segment in 1...rightSegments {
            let t = CGFloat(segment) / CGFloat(rightSegments)
            let baseY = rect.minY + (rect.maxY - rect.minY) * t * 0.85
            let jitter = CGFloat.random(in: -1.5...1.5, using: &rng)
            path.addLine(to: CGPoint(x: rect.maxX + jitter, y: baseY))
        }

        // Bottom: jagged tear. 7 spikes with varying x-step and small y-rise.
        let spikes = 7
        var x = rect.maxX
        let bottomY = rect.maxY - 6
        path.addLine(to: CGPoint(x: x, y: bottomY))
        for spike in 0..<spikes {
            let stepWidth = (rect.width / CGFloat(spikes)) + CGFloat.random(in: -3...3, using: &rng)
            x -= stepWidth
            let isPeak = spike % 2 == 0
            let y = isPeak
                ? bottomY + CGFloat.random(in: 4...8, using: &rng)
                : bottomY - CGFloat.random(in: 1...3, using: &rng)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        // Close to bottom-left.
        path.addLine(to: CGPoint(x: rect.minX, y: bottomY))

        // Left side: 4 segments back up to top-left.
        let leftSegments = 4
        for segment in stride(from: leftSegments - 1, through: 0, by: -1) {
            let t = CGFloat(segment) / CGFloat(leftSegments)
            let baseY = rect.minY + (rect.maxY - rect.minY) * t * 0.85
            let jitter = CGFloat.random(in: -1.5...1.5, using: &rng)
            path.addLine(to: CGPoint(x: rect.minX + jitter, y: baseY))
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - PushPin
//
// Small circular pin head. Two concentric circles + a soft highlight.
// Evidence Red is reserved for connection / verdict, so pins use Ink Black —
// the head looks like a black tack, not a red one.

struct PushPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.ink)
                .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.55), Color.clear],
                        center: UnitPoint(x: 0.35, y: 0.30),
                        startRadius: 0.5,
                        endRadius: 5
                    )
                )
        }
    }
}

// MARK: - VerdictStamp
//
// Static stamp render — the slam itself is owned by Choreography.StampSlam in
// Deep Check. On the briefing, investigated cases are already stamped, so we
// render the resting visual without re-animating it.
//
// Mirrors the StampGraphic visual contract from
// `Choreography/Effects/StampSlam.swift` (mono Evidence-Red inscription, thin
// Evidence-Red border, light fill suggesting absorbed ink). Kept inline here
// rather than depended on because the Choreography one is `private`.

struct VerdictStamp: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.fileTitle)
            .tracking(2.0)
            .foregroundStyle(Color.evidence)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.evidence, lineWidth: 1.4)
            )
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.evidence.opacity(0.05))
            )
    }
}
