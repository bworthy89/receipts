// MARK: - ArchiveScreen
//
// Cork-substrate vertical scroll of polaroid cards, day-grouped. Reached
// from the briefing's "ARCHIVE · N FILED" footer. Tap a polaroid → re-open
// the case in DeepCheck (skip-on-revisit handles the playback decision).
//
// Per the 2026-05-03 archive-shape brief.

import SwiftUI
import Models
import DesignSystem
import DeepCheck

public struct ArchiveScreen: View {

    private let log: InvestigationLog
    private let provider: any DeepCheckProvider
    private let clock: @Sendable () -> Date
    private let onDismiss: @MainActor () -> Void

    @State private var openCase: Case? = nil

    public init(
        log: InvestigationLog = .live(),
        provider: any DeepCheckProvider = MockProvider(),
        clock: @escaping @Sendable () -> Date = { Date() },
        onDismiss: @escaping @MainActor () -> Void
    ) {
        self.log = log
        self.provider = provider
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
        #if os(iOS)
        // iOS-only: macOS has no fullScreenCover. Package builds for macOS
        // host so tests can run; cover only ships on the real device target.
        .fullScreenCover(item: $openCase) { kase in
            DeepCheckScreen(
                kase: kase,
                provider: provider,
                log: log,
                clock: clock,
                onDismiss: { openCase = nil }
            )
        }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        let entries = log.allEntries()
        if entries.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    ForEach(ArchiveGrouping.groups(from: entries, now: clock())) { group in
                        groupView(group)
                    }
                }
                .padding(.horizontal, Spacing.cardPadding)
                .padding(.top, 64)
                .padding(.bottom, Spacing.stadium)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func groupView(_ group: ArchiveDayGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            sectionHeader(group.header)
            VStack(spacing: Spacing.section) {
                ForEach(group.entries) { entry in
                    Button {
                        openCase = Case(
                            caseID: entry.caseID,
                            caseNumber: entry.caseNumber,
                            headline: entry.headline,
                            verdict: entry.verdict
                        )
                    } label: {
                        ArchivePolaroid(entry)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack(alignment: .center, spacing: Spacing.tight) {
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Rectangle()
                .fill(Color.ink.opacity(0.4))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.paper)
                    .frame(width: 280, height: 110)
                    .pinnedCardShadow()
                Text("Nothing on file. Quiet beat.")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: 240)
            }
            Spacer()
        }
    }
}

// MARK: - CloseButton
//
// Mirrors the close affordance from DeepCheckScreen — a paper tab with
// "× CLOSE" in mono. Defined locally rather than sharing because the
// DeepCheck implementation is private to that package, and the visual is
// trivial enough that two copies don't outweigh the dependency overhead.

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
        .accessibilityLabel(Text("Close archive"))
    }
}
