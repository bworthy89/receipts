// MARK: - ArchivePolaroid
//
// Sepia-bordered polaroid card for one archived case. Per the 2026-05-03
// archive-shape brief §5:
//   • Sepia border, paper-white face, ±2° per-card rotation, polaroidShadow.
//   • Mono case-number top-right inside the polaroid border.
//   • Serif headline as the dominant face content.
//   • Verdict stamp slammed across the lower portion (-7°).
//   • Sepia bottom border with mono "INVESTIGATED · MAY 02 2026" caption.
//
// The verdict stamp render mirrors the centerpiece used in DeepCheck —
// red ink, evidence color, slight tilt — so the visual contract stays
// consistent across the briefing → check → archive flow.

import SwiftUI
import Models
import DesignSystem
import DeepCheck

public struct ArchivePolaroid: View {

    public let entry: ArchiveEntry

    public init(_ entry: ArchiveEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(spacing: 0) {
            faceHeader
            face
            captionStrip
        }
        .frame(width: Self.cardWidth)
        .background(Color.sepia)
        .polaroidShadow()
        .rotationEffect(rotation)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityDescription))
    }

    // MARK: - Subviews

    /// Top sepia strip with the case number aligned right. The polaroid's
    /// natural top border becomes the home of the procedural metadata.
    private var faceHeader: some View {
        HStack {
            Spacer(minLength: 0)
            Text(entry.caseNumber)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(Color.ink.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    /// Paper-white face holding the headline + the slammed verdict stamp.
    private var face: some View {
        ZStack(alignment: .center) {
            Color.paper

            VStack(alignment: .leading, spacing: Spacing.snug) {
                Text(entry.headline)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Verdict stamp slammed across the lower-right of the face.
            VerdictStamp(text: entry.verdict.rawValue)
                .rotationEffect(.degrees(-7))
                .offset(x: 26, y: 28)
        }
        .frame(height: Self.faceHeight)
    }

    /// Bottom sepia strip with the investigated date in mono.
    private var captionStrip: some View {
        HStack {
            Text(captionText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.ink.opacity(0.7))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }

    // MARK: - Computed

    private var rotation: Angle {
        // Stable per-card rotation seeded from the caseID. Same recipe
        // DailyBriefing's PinLayout uses for stable per-pin rotation, so
        // an archived case keeps its visual "tilt" across re-renders.
        var rng = SplitMix64(seed: SplitMix64.seed(from: entry.caseID))
        let degrees = Double.random(in: -2.4...2.4, using: &rng)
        return .degrees(degrees)
    }

    private var captionText: String {
        let comps = Calendar(identifier: .gregorian).dateComponents([.month, .day, .year], from: entry.investigatedOn)
        let months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        let m = months[max(1, min(12, comps.month ?? 1)) - 1]
        let d = String(format: "%02d", comps.day ?? 1)
        let y = String(comps.year ?? 2026)
        return "Investigated · \(m) \(d) \(y)"
    }

    private var accessibilityDescription: String {
        let dayString = captionText
            .replacingOccurrences(of: "Investigated · ", with: "")
        return "Archived case: \(entry.headline). Verdict: \(entry.verdict.rawValue). Investigated \(dayString). Double-tap to re-read."
    }

    // MARK: - Metrics

    static let cardWidth: CGFloat = 280
    static let faceHeight: CGFloat = 170
}

// MARK: - VerdictStamp
//
// Local stamp render — same visual contract as the centerpiece stamps in
// DeepCheck and the corner stamps on briefing pins. Defined locally because
// no shared "VerdictStamp" surface yet exists; if a third caller appears,
// lift to DesignSystem.

private struct VerdictStamp: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .tracking(2.4)
            .foregroundStyle(Color.evidence)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .stroke(Color.evidence, lineWidth: 1.4)
            )
            .background(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Color.evidence.opacity(0.05))
            )
    }
}

// MARK: - SplitMix64
//
// Local copy of the seeded RNG used by other feature packages (DailyBriefing,
// DeepCheck). Per memory: when a third caller appears, lift to a shared
// utility — that's now (Archive is the third). Deferred to a follow-up so
// this PR stays scoped to the Archive surface.

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    static func seed(from string: String) -> UInt64 {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        for byte in string.utf8 {
            state = state &+ UInt64(byte)
            state = (state ^ (state >> 30)) &* 0xBF58_476D_1CE4_E5B9
            state = (state ^ (state >> 27)) &* 0x94D0_49BB_1331_11EB
            state = state ^ (state >> 31)
        }
        return state
    }
}
