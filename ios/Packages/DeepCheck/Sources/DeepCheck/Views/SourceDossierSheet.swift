// MARK: - SourceDossierSheet
//
// Full-viewport manila folder presented over Deep Check when the user taps
// a source pin. Frames the source as an outlet ("person of interest") with
// the full excerpt as the dominant block, the outlet name as masthead, and
// a small mono caption noting how often the outlet appears in the active
// briefing.
//
// Per the 2026-05-03 source-dossier brief, revised after two craft passes
// on the close animation. The current model:
//
//   • Two layers above the cork substrate: the paper-white body underneath
//     (masthead + excerpt + footer), and a tall manila cover on top.
//   • At rest, the cover is positioned so only the bottom 38pt — the tab —
//     pokes into the viewport. The body shows everywhere else.
//   • Drag down on the tab: the cover slides down, eating the body. The
//     manila/paper color contrast carries the "closing" metaphor.
//   • Past 40% threshold on release: cover auto-completes its descent and
//     the sheet dismisses. Below threshold: cover springs back up.
//   • Reduce Motion: skip the slide; opacity fade only.

import SwiftUI
import Models
import DesignSystem

public struct SourceDossierSheet: View {

    let source: Source
    let kase: Case
    let appearanceCount: Int
    let totalCases: Int
    let onDismiss: @MainActor () -> Void

    @State private var progress: CGFloat = 0
    @State private var isClosing: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Visible height of the manila tab when the cover is fully open
    /// (progress = 0). Matches the original tab-strip height.
    private static let tabHeight: CGFloat = 38

    public init(
        source: Source,
        kase: Case,
        appearanceCount: Int,
        totalCases: Int,
        onDismiss: @escaping @MainActor () -> Void
    ) {
        self.source = source
        self.kase = kase
        self.appearanceCount = appearanceCount
        self.totalCases = totalCases
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Substrate: warm cork peeking around the cover edges.
                Color.cork.ignoresSafeArea()

                // Body underneath the cover. Top padding leaves room for
                // the tab so masthead never sits behind it at rest.
                folderBody
                    .padding(.top, Self.tabHeight)
                    .background(Color.paper)
                    .opacity(bodyOpacity)

                // Manila cover that slides down on drag.
                cover(in: geo)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityLabel(Text(accessibilityDescription))
    }

    // MARK: - Body (paper-white, content)

    private var folderBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                masthead
                hairline
                excerpt
                hairline
                metadataFooter
            }
            .padding(.horizontal, Spacing.section)
            .padding(.top, Spacing.section)
            .padding(.bottom, Spacing.stadium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            Text(source.outlet)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(appearanceCaption)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.pencil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var excerpt: some View {
        Text(source.excerpt)
            .font(.system(size: 17, weight: .regular, design: .serif))
            .foregroundStyle(Color.ink)
            .lineSpacing(5)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metadataFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.hairline) {
            metadataRow(label: "CASE", value: kase.caseNumber)
            metadataRow(label: "SOURCE", value: source.id)
            metadataRow(label: "PUBLISHED", value: formattedPublishedDate)
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.snug) {
            Text(label)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(Color.pencil)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.ink.opacity(0.3))
            .frame(height: 1)
    }

    // MARK: - Cover (manila, slides down on drag)

    private func cover(in geo: GeometryProxy) -> some View {
        let coverHeight = geo.size.height + 200          // extra slack so the top stays off-screen
        let restingOffset = -(coverHeight - Self.tabHeight)  // only the tab pokes in
        let activeRange = coverHeight - Self.tabHeight
        let currentOffset = restingOffset + (progress * activeRange)
        let isFullyOpen = progress < 0.001

        return ZStack(alignment: .bottom) {
            // The manila plate. Sepia fill plus a soft shadow at its
            // bottom edge to suggest the cover is hovering above the body.
            Rectangle()
                .fill(Color.sepia)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 6)

            // Tab label sits at the cover's bottom edge — at rest, this
            // is the visible portion in the viewport.
            tabContent
                .frame(height: Self.tabHeight)

            // Hairline shadow at the very bottom of the cover for a touch
            // of physical separation between cover and body.
            Rectangle()
                .fill(Color.ink.opacity(0.18))
                .frame(height: 1)
                .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(height: coverHeight)
        .frame(maxWidth: .infinity)
        .offset(y: reduceMotion ? restingOffset : currentOffset)
        .opacity(reduceMotion ? max(1.0 - Double(progress), 0.0) : 1.0)
        // Tab-shape clip on the bottom edge so the cover reads as a real
        // file-folder tab and not a plain rectangle.
        .clipShape(CoverTabShape(tabHeight: Self.tabHeight))
        .gesture(coverDragGesture)
        .accessibilityHint(Text("Drag down to close"))
        .allowsHitTesting(isFullyOpen || progress > 0)
    }

    private var tabContent: some View {
        HStack(spacing: Spacing.tight) {
            Text(tabLabel)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .padding(.leading, Spacing.cardPadding)
            Spacer(minLength: 0)
        }
    }

    private var coverDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !reduceMotion else { return }
                guard !isClosing else { return }
                progress = FolderFold.progress(for: value.translation.height)
            }
            .onEnded { _ in
                guard !reduceMotion else { return }
                guard !isClosing else { return }
                if FolderFold.shouldDismiss(at: progress) {
                    isClosing = true
                    withAnimation(ChoreographyTimingMirror.easeOutQuart(duration: 0.32)) {
                        progress = 1.0
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(330))
                        onDismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        progress = 0
                    }
                }
            }
    }

    // MARK: - Computed

    /// Body opacity tracks the cover descent so as the cover slides down
    /// the body fades subtly behind it. Reads as "the contents are being
    /// hidden as the cover lands."
    private var bodyOpacity: Double {
        if reduceMotion { return 1.0 }
        return 1.0 - Double(progress) * 0.35
    }

    private var tabLabel: String {
        let outlet = source.outlet.uppercased()
        return "\(outlet) · \(formattedPublishedDate)"
    }

    private var appearanceCaption: String {
        "Appears in \(appearanceCount) of \(totalCases) active cases."
    }

    private var formattedPublishedDate: String {
        let comps = Calendar(identifier: .gregorian)
            .dateComponents([.month, .day, .year], from: source.publishedOn)
        let months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
        let m = months[max(1, min(12, comps.month ?? 1)) - 1]
        let d = String(format: "%02d", comps.day ?? 1)
        let y = String(comps.year ?? 2026)
        return "\(m) \(d) \(y)"
    }

    private var accessibilityDescription: String {
        "Source dossier: \(source.outlet). \(source.excerpt) From case \(kase.headline). Drag down to close."
    }
}

// MARK: - CoverTabShape
//
// Shape clip applied to the manila cover. The cover is a tall rectangle
// for most of its height; near the bottom, a small notch on the right
// side gives the manila edge a real folder-tab silhouette rather than a
// flat horizontal cut.

private struct CoverTabShape: Shape {
    let tabHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let notchStart = rect.maxX * 0.78
        let tabTop = rect.maxY - tabHeight
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: tabTop))
        p.addLine(to: CGPoint(x: notchStart, y: tabTop))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - ChoreographyTimingMirror
//
// Local mirror of `Choreography.ChoreographyTiming.easeOutQuart` because
// that module's `Duration.seconds` bridge is package-internal. If the
// canonical curve changes, retune here.

private enum ChoreographyTimingMirror {
    static func easeOutQuart(duration: Double) -> Animation {
        .timingCurve(0.25, 1.0, 0.5, 1.0, duration: duration)
    }
}
