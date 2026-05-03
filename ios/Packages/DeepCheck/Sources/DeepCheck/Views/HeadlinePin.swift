// MARK: - HeadlinePin
//
// Central case pin in the Deep Check investigation board — the hub of the
// hub-and-spoke layout. Slightly larger than the briefing's TornNote
// (briefing pins are ~165pt; this one is ~210pt) so it reads as the
// dominant element on the board.
//
// Per the 2026-05-03 brief §10 open question:
//   "Central headline pin shape. Same torn-note as briefing (continuity) vs
//    upgraded form. Lean: same torn-note, slightly larger."
//
// We do not depend on `DailyBriefing.TornNote` directly because the briefing
// pin's torn-edge `Shape` is internal to that package; duplicating the
// shape and overall composition here keeps the dependency edge clean
// (DeepCheck → Models, not DeepCheck → DailyBriefing). The shape itself is
// the same recipe (clean top, jagged bottom, lightly perturbed sides).

import SwiftUI
import Models
import DesignSystem

public struct HeadlinePin: View {

    let kase: Case

    public init(_ kase: Case) {
        self.kase = kase
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            HeadlineTornPaperShape(seed: paperSeed)
                .fill(Color.paper)
                .pinnedCardShadow()

            VStack(alignment: .leading, spacing: Spacing.tight) {
                Text(kase.caseNumber)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.pencil)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(kase.headline)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 26)
            .padding(.horizontal, 16)
            .padding(.bottom, 22)

            // Push pin centered above the clean tear-off line.
            PushPin()
                .frame(width: 14, height: 14)
                .offset(x: HeadlineTornPaperShape.nominalWidth / 2 - 7, y: -3)
        }
        .frame(width: HeadlineTornPaperShape.nominalWidth, height: HeadlineTornPaperShape.nominalHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Case file: \(kase.headline)"))
    }

    private var paperSeed: UInt64 {
        SplitMix64.seed(from: "headline-\(kase.caseID)")
    }
}

// MARK: - HeadlineTornPaperShape
//
// Same recipe as DailyBriefing's TornPaperShape but sized for the
// investigation hub. Clean top edge (notepad tear-off), jagged bottom tear,
// lightly perturbed sides. Deterministic per seed.

struct HeadlineTornPaperShape: Shape {
    let seed: UInt64

    static let nominalWidth: CGFloat = 215
    static let nominalHeight: CGFloat = 165

    func path(in rect: CGRect) -> Path {
        var rng = SplitMix64(seed: seed)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right side — 4 segments down with subtle jitter.
        let rightSegments = 4
        for segment in 1...rightSegments {
            let t = CGFloat(segment) / CGFloat(rightSegments)
            let baseY = rect.minY + (rect.maxY - rect.minY) * t * 0.85
            let jitter = CGFloat.random(in: -2.0...2.0, using: &rng)
            path.addLine(to: CGPoint(x: rect.maxX + jitter, y: baseY))
        }

        // Bottom: jagged tear with 8 spikes.
        let spikes = 8
        var x = rect.maxX
        let bottomY = rect.maxY - 8
        path.addLine(to: CGPoint(x: x, y: bottomY))
        for spike in 0..<spikes {
            let stepWidth = (rect.width / CGFloat(spikes)) + CGFloat.random(in: -3...3, using: &rng)
            x -= stepWidth
            let isPeak = spike % 2 == 0
            let y = isPeak
                ? bottomY + CGFloat.random(in: 5...10, using: &rng)
                : bottomY - CGFloat.random(in: 1...3, using: &rng)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.minX, y: bottomY))

        // Left side back up.
        let leftSegments = 4
        for segment in stride(from: leftSegments - 1, through: 0, by: -1) {
            let t = CGFloat(segment) / CGFloat(leftSegments)
            let baseY = rect.minY + (rect.maxY - rect.minY) * t * 0.85
            let jitter = CGFloat.random(in: -2.0...2.0, using: &rng)
            path.addLine(to: CGPoint(x: rect.minX + jitter, y: baseY))
        }
        path.closeSubpath()

        return path
    }
}
