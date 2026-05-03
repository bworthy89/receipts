// MARK: - SourceDossierSheet
//
// Full-viewport manila folder presented over Deep Check when the user taps
// a source pin. Frames the source as an outlet ("person of interest") with
// the full excerpt as the dominant block, the outlet name as masthead, and
// a small mono caption noting how often the outlet appears in the active
// briefing.
//
// Per the 2026-05-03 source-dossier brief §5 Layout:
//   • Manila tab strip at the top with mono outlet label.
//   • Folder body fills the rest: outlet masthead (serif large), mono
//     caption "APPEARS IN N OF 10 ACTIVE CASES.", divider, full excerpt
//     (body serif), divider, mono metadata footer.
//
// Closes via FolderFoldDismiss — drag-driven 3D rotation around the bottom
// edge. Standard sheet drag-dismiss remains as an iOS-default backstop.

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
        ZStack(alignment: .top) {
            // The substrate: warm sepia/cork peeking around the folder edges.
            Color.cork.ignoresSafeArea()

            folder
                .modifier(FolderFoldRender(progress: progress, reduceMotion: reduceMotion))
        }
        .accessibilityLabel(Text(accessibilityDescription))
    }

    // MARK: - Folder

    private var folder: some View {
        VStack(spacing: 0) {
            tabStrip
            folderBody
        }
        .background(Color.paper)
    }

    private var tabStrip: some View {
        HStack(spacing: Spacing.tight) {
            Text(tabLabel)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .padding(.leading, Spacing.cardPadding)
            Spacer(minLength: 0)
        }
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .background(
            ManilaTabBackground()
                .fill(Color.sepia)
        )
        // Drag gesture lives ONLY on the tab. The body's ScrollView gets
        // its full gesture surface back so users can scroll the excerpt
        // without folding the sheet by accident.
        .contentShape(Rectangle())
        .gesture(tabDragGesture)
        .accessibilityHint(Text("Drag down to close"))
    }

    private var tabDragGesture: some Gesture {
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
                    withAnimation(.easeIn(duration: 0.28)) {
                        progress = 1.0
                        isClosing = true
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(290))
                        onDismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        progress = 0
                    }
                }
            }
    }

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

    // MARK: - Computed

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

// MARK: - ManilaTabBackground
//
// Top-aligned manila tab silhouette: the entire bar is sepia, with a small
// notch on the right side suggesting where the tab edges into the next file.

private struct ManilaTabBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let notchStart = rect.maxX * 0.78
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: notchStart, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
