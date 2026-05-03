// MARK: - EvidenceDossier
//
// Below-the-fold section of the Deep Check screen. PRODUCT.md & DESIGN.md
// commit to a "BiasMeter dossier — evidence list with checkbox-marked
// findings, source attributions in mono, never a single bar-chart score.
// Multiple discrete pieces of evidence shown, not one number."
//
// Per the 2026-05-03 brief §5 Layout:
//   "PULLED QUOTES mono section heading, then 5 evidence rows — each a
//    serif quote with mono attribution ('— Reuters, May 3 2026')."
//
// And per the brief's open question on case-summary: "Optional: case-summary
// paragraph at the very bottom." Out of scope for v1; verdicts already
// summarise the conclusion via the stamp.

import SwiftUI
import DesignSystem

public struct EvidenceDossier: View {

    let evidence: [EvidenceQuote]

    public init(_ evidence: [EvidenceQuote]) {
        self.evidence = evidence
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            sectionHeader

            VStack(alignment: .leading, spacing: Spacing.section) {
                ForEach(evidence) { item in
                    EvidenceRow(item: item)
                }
            }
        }
        .padding(.horizontal, Spacing.section)
        .padding(.top, Spacing.section)
        .padding(.bottom, Spacing.stadium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sectionHeader: some View {
        HStack(alignment: .center, spacing: Spacing.tight) {
            // Mono section label.
            Text("PULLED QUOTES")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Color.ink)
            // Hairline divider extends the section heading across the page.
            Rectangle()
                .fill(Color.ink.opacity(0.4))
                .frame(height: 1)
        }
    }
}

// MARK: - EvidenceRow

private struct EvidenceRow: View {
    let item: EvidenceQuote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.snug) {
            // The quote — serif body, slightly emphasised line-height.
            Text(item.quote)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)

            // Attribution — mono, leading dash like print convention.
            Text("— \(item.attribution)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Color.pencil)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Quote: \(item.quote). Attribution: \(item.attribution)"))
    }
}
