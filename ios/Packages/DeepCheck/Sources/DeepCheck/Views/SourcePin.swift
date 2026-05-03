// MARK: - SourcePin
//
// One of the five source pins on the Deep Check investigation board. Manila-
// folder-tab card: a small manila-tan tab at the top with the outlet name in
// mono, a paper-white body holding the ~25-word excerpt in serif, pinned to
// cork with a single push-pin.
//
// Per the 2026-05-03 brief §5 Layout Strategy:
//   "5 source pins (manila-folder-tab cards: small manila tab at top with
//    the outlet name in mono, paper-white body with a ~25-word excerpt)
//    fanning around the central pin..."
//
// This is the *static* visual; the `PolaroidDevelop` motion is applied by
// the screen's sequencer when the source pin enters during a fresh
// investigation.

import SwiftUI
import DesignSystem

public struct SourcePin: View {

    let source: Source

    public init(_ source: Source) {
        self.source = source
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Manila tab — outlet name in uppercase mono.
            tab
                .frame(height: 22)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Paper-white body with the excerpt and date footer.
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(source.excerpt)
                    .font(.system(size: 11.5, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Text(dateFooter)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.pencil)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.paper)
            )
        }
        .frame(width: SourceLayout.Metrics.pinWidth, height: SourceLayout.Metrics.pinHeight)
        .pinnedCardShadow()
        .overlay(alignment: .top) {
            // Push pin sits where the tab attaches to the board.
            PushPin()
                .frame(width: 12, height: 12)
                .offset(y: -3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Source: \(source.outlet). \(source.excerpt)"))
    }

    private var tab: some View {
        Text(source.outlet)
            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Color.ink)
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .background(
                ManilaTabShape()
                    .fill(Color.sepia)
            )
    }

    private var dateFooter: String {
        let comps = Calendar(identifier: .gregorian).dateComponents([.month, .day, .year], from: source.publishedOn)
        let months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        let m = months[max(1, min(12, comps.month ?? 1)) - 1]
        let d = String(format: "%02d", comps.day ?? 1)
        let y = String(comps.year ?? 2026)
        return "\(m) \(d) \(y)"
    }
}

// MARK: - ManilaTabShape
//
// File-folder tab silhouette: full rectangle on the leading 70% of the
// width, then a 45° slope down to the trailing edge so the tab reads as a
// real manila-folder tab and not a plain rectangle.

struct ManilaTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let slopeStart = rect.maxX * 0.7
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: slopeStart, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - PushPin
//
// Mirrors the briefing's push-pin in DailyBriefing.TornNote. Defined locally
// rather than depended on because the briefing's PushPin is internal to
// that package — and per project memory, this is intentional (it's a tiny
// visual primitive worth duplicating to keep the cross-package deps clean).

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
