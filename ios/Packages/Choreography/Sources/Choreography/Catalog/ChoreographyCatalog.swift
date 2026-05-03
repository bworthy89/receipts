// MARK: - ChoreographyCatalog
//
// Cork-board test bench for the four signature motions. The catalog IS a
// corner of the cork board — paper-cell stacks pinned with uneven rotation,
// the cork visible between them, never broken character.
//
// Per the 2026-05-03 shape brief §5: "Vertical scroll, four pinned cells
// stacked with deliberate uneven rotation (±2–4°) and deliberate uneven gaps
// (28 / 36 / 32 pt) — the cork is visible between cards, never covered edge-
// to-edge. Each cell is a Paper White card with: a real push-pin top-center
// holding it to cork, a small REPLAY pin in the bottom-right corner (mono
// inscription), and a Reduce Motion sticker-pin in the top-right (mono "RM"
// / "rm"). Below the artifact area runs a thin mono caption strip — duration
// + easing in file voice."
//
// #if DEBUG so the catalog ships in development builds and is omitted from
// App Store builds — same convention as `DesignSystemCatalog`.
//
// On-mount stagger: each cell's motion plays once on appear, with an 80ms
// per-cell delay so the four motions cascade rather than firing simultaneously.
// Replay-pin tap re-plays a single cell. Reduce-Motion sticker-pin overrides
// `accessibilityReduceMotion` for that cell only — the motion views themselves
// always read environment with no escape hatch; the override lives in the
// catalog cell, not in the motion API.

#if DEBUG

import SwiftUI
import DesignSystem

public struct ChoreographyCatalog: View {

    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, Spacing.section)

                    PinDropCell(cellIndex: 0)
                        .padding(.bottom, 28)

                    RedStringCell(cellIndex: 1)
                        .padding(.bottom, 36)

                    PolaroidDevelopCell(cellIndex: 2)
                        .padding(.bottom, 32)

                    StampSlamCell(cellIndex: 3)
                        .padding(.bottom, Spacing.stadium)
                }
                .padding(.horizontal, Spacing.boardMargin)
                .padding(.top, Spacing.section)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.cork.ignoresSafeArea())
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
            }
            .toolbarBackground(Color.cork, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            MonoLabel("INDEX · 01–04")
            StoryText.display("The Choreography.")
        }
    }
}

// MARK: - Cell wrappers
//
// Each cell composes the same chrome (paper card, pins in corners, mono labels)
// but holds a different motion. Per the brief — no shared cell generic. The
// four cells are bespoke because the artifact each holds has a different
// footprint (red-string is widest, stamp is narrowest, etc.).

private struct PinDropCell: View {
    let cellIndex: Int
    @State private var replayToken = UUID()
    @State private var rmOverride: Bool? = nil   // nil = follow system

    var body: some View {
        CellChrome(
            label: "PIN-DROP / 01",
            caption: "628ms · ease-out-quart",
            rotation: .degrees(-2.5),
            replayVoiceOver: "Replay pin-drop motion.",
            replayAction: { replayToken = UUID() },
            rmOverride: $rmOverride
        ) {
            ZStack {
                Color.clear.frame(height: 220)

                PinDrop(delay: stagger(cellIndex)) {
                    PinDropDemoCard()
                }
                .id(replayToken)
            }
            .environment(\.choreographyReducedMotion, rmOverride)
        }
    }
}

private struct RedStringCell: View {
    let cellIndex: Int
    @State private var replayToken = UUID()
    @State private var rmOverride: Bool? = nil

    var body: some View {
        CellChrome(
            label: "RED-STRING / 02",
            caption: "920ms · ease-out-expo",
            rotation: .degrees(2.0),
            replayVoiceOver: "Replay red-string draw.",
            replayAction: { replayToken = UUID() },
            rmOverride: $rmOverride
        ) {
            ChoreographyBoard {
                ZStack {
                    Color.clear.frame(height: 220)

                    HStack(spacing: 24) {
                        SourceCard(
                            outlet: "REUTERS",
                            timestamp: "2026-04-29 11:14 ET",
                            rotation: .degrees(-3)
                        )
                        .choreographyAnchor("rs-reuters")

                        SourceCard(
                            outlet: "ASSOCIATED PRESS",
                            timestamp: "2026-04-29 11:31 ET",
                            rotation: .degrees(2.5)
                        )
                        .choreographyAnchor("rs-ap")
                    }
                    .padding(.horizontal, 12)

                    RedString(from: "rs-reuters", to: "rs-ap")
                }
            }
            .id(replayToken)
            .environment(\.choreographyReducedMotion, rmOverride)
        }
    }
}

private struct PolaroidDevelopCell: View {
    let cellIndex: Int
    @State private var replayToken = UUID()
    @State private var rmOverride: Bool? = nil

    var body: some View {
        CellChrome(
            label: "POLAROID / 03",
            caption: "1380ms · custom develop curve",
            rotation: .degrees(-1.0),
            replayVoiceOver: "Replay polaroid develop.",
            replayAction: { replayToken = UUID() },
            rmOverride: $rmOverride
        ) {
            ZStack {
                Color.clear.frame(height: 280)

                PolaroidShell {
                    PolaroidDevelop(delay: stagger(cellIndex)) {
                        WirePhotoPlaceholder()
                    }
                }
                .id(replayToken)
            }
            .environment(\.choreographyReducedMotion, rmOverride)
        }
    }
}

private struct StampSlamCell: View {
    let cellIndex: Int
    @State private var replayToken = UUID()
    @State private var rmOverride: Bool? = nil

    var body: some View {
        CellChrome(
            label: "STAMP-SLAM / 04",
            caption: "460ms + 120ms kick",
            rotation: .degrees(2.5),
            replayVoiceOver: "Replay stamp slam.",
            replayAction: { replayToken = UUID() },
            rmOverride: $rmOverride
        ) {
            ZStack {
                Color.clear.frame(height: 220)

                StampSlam(
                    inscription: "CONFIRMED",
                    angle: .degrees(6),
                    delay: stagger(cellIndex)
                ) {
                    PaperSurface {
                        VStack(alignment: .leading, spacing: Spacing.snug) {
                            MonoLabel("CASE-2026-0428 · CLOSED", color: .ink)
                            StoryText.title("Senate vote cleared 51-49 after late objections from FL delegation.")
                        }
                        .padding(Spacing.cardPadding)
                    }
                    .frame(maxWidth: 280)
                }
                .id(replayToken)
            }
            .environment(\.choreographyReducedMotion, rmOverride)
        }
    }
}

// MARK: - CellChrome
//
// Shared paper-card frame with the three corner pins (top-center holding pin,
// top-right RM toggle, bottom-right replay) and the mono label/caption strip.
// Content is the motion stage.

private struct CellChrome<Content: View>: View {
    let label: String
    let caption: String
    let rotation: Angle
    let replayVoiceOver: String
    let replayAction: () -> Void
    @Binding var rmOverride: Bool?
    let content: Content

    init(
        label: String,
        caption: String,
        rotation: Angle,
        replayVoiceOver: String,
        replayAction: @escaping () -> Void,
        rmOverride: Binding<Bool?>,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.caption = caption
        self.rotation = rotation
        self.replayVoiceOver = replayVoiceOver
        self.replayAction = replayAction
        self._rmOverride = rmOverride
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            // The paper card itself.
            VStack(alignment: .leading, spacing: 14) {
                // Title gets `.ink` so it reads as the cell's primary header
                // even in Dim-Room dark mode where pencil-on-paper drops to
                // low contrast. Caption stays `.pencil` (secondary metadata).
                MonoLabel(label, color: .ink)
                content
                MonoLabel(caption, color: .pencil)
            }
            .padding(.horizontal, Spacing.cardPadding)
            .padding(.top, 22)         // room above for the holding pin
            .padding(.bottom, 14)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.paper)
            )
            .pinnedCardShadow()

            // Top-center holding push-pin — anchors the cell to cork.
            PushPin()
                .offset(y: -6)

            // Top-right RM toggle — overrides accessibilityReduceMotion for
            // this cell only.
            HStack {
                Spacer()
                ReduceMotionTogglePin(state: $rmOverride)
                    .padding(.trailing, 10)
                    .padding(.top, 6)
            }

            // Bottom-right replay pin.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ReplayPin(action: replayAction)
                        .accessibilityLabel(Text(replayVoiceOver))
                        .padding(.trailing, 10)
                        .padding(.bottom, 8)
                }
            }
        }
        .rotationEffect(rotation)
    }
}

// MARK: - Push pins

private struct PushPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.pencil)
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color.ink.opacity(0.45))
                .frame(width: 4, height: 4)
        }
        .shadow(color: Color.ink.opacity(0.35), radius: 1.5, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}

private struct ReplayPin: View {
    let action: () -> Void
    @State private var depressed: Bool = false

    var body: some View {
        Button {
            withAnimation(.linear(duration: 0.04)) { depressed = true }
            action()
            Task {
                try? await Task.sleep(for: .milliseconds(40))
                withAnimation(.linear(duration: 0.04)) { depressed = false }
            }
        } label: {
            VStack(spacing: 2) {
                PushPin()
                MonoLabel("REPLAY", color: .pencil)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.paper)
            )
            .pinnedCardShadow()
            .scaleEffect(depressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

private struct ReduceMotionTogglePin: View {
    @Binding var state: Bool?     // nil = follow system, true = forced reduced, false = forced full
    @Environment(\.accessibilityReduceMotion) private var systemRM

    var body: some View {
        Button {
            // Two-state cycle: nil (follow system) ↔ override (opposite of system).
            // Keeps the toggle simple to reason about; the sticker either says
            // "this cell defies the system" or "this cell follows the system."
            state = (state == nil) ? !systemRM : nil
        } label: {
            VStack(spacing: 2) {
                PushPin()
                MonoLabel(label, color: isReduced ? .ink : .pencil)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.paper.opacity(state == nil ? 1.0 : 0.92))
            )
            .pinnedCardShadow()
            // The one place in the catalog allowed to defy Reduce Motion —
            // its job is to BE the toggle. 8° tilt on activation.
            .rotationEffect(.degrees(state == nil ? 0 : 8))
            .animation(.easeOut(duration: 0.15), value: state)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(voiceOverLabel))
    }

    private var isReduced: Bool {
        state ?? systemRM
    }

    private var label: String {
        isReduced ? "RM" : "rm"
    }

    private var voiceOverLabel: String {
        if state == nil {
            return "Reduce motion follows system. Tap to override for this card."
        }
        if state == true {
            return "Reduce motion: on for this card. Tap to follow system."
        }
        return "Reduce motion: off for this card. Tap to follow system."
    }
}

// MARK: - Demo content

private struct PinDropDemoCard: View {
    var body: some View {
        ZStack(alignment: .top) {
            PaperSurface {
                VStack(alignment: .leading, spacing: Spacing.snug) {
                    MonoLabel("CASE-2026-0428", color: .ink)
                    StoryText.title("Senate vote cleared 51-49 after late objections from FL delegation.")
                }
                .padding(Spacing.cardPadding)
            }
            .frame(maxWidth: 280)

            PushPin()
                .offset(y: -6)
        }
        .rotationEffect(.degrees(-1.5))
    }
}

private struct SourceCard: View {
    let outlet: String
    let timestamp: String
    let rotation: Angle

    var body: some View {
        ZStack(alignment: .top) {
            PaperSurface {
                VStack(alignment: .leading, spacing: 6) {
                    MonoLabel("SOURCE", color: .pencil)
                    MonoLabel(outlet, color: .ink)
                    MonoLabel(timestamp, color: .pencil)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .frame(width: 140)

            PushPin().offset(y: -5)
        }
        .rotationEffect(rotation)
    }
}

/// Polaroid shell — white-bordered frame around developing image content.
/// Named `PolaroidShell` not `PolaroidFrame` to avoid colliding with the
/// internal `PolaroidFrame` keyframe value type in `PolaroidDevelop.swift`.
private struct PolaroidShell<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(width: 200, height: 200)
                .clipShape(Rectangle())

            MonoLabel("WIRE / 2026-04-29", color: .pencil)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
        }
        .padding(8)                  // the white polaroid border
        .background(Color.paper)
        .polaroidShadow()
        .rotationEffect(.degrees(-2.5))
    }
}

private struct WirePhotoPlaceholder: View {
    // Stylized stand-in for a wire photo. A warm-toned linear gradient with
    // muted figure shapes reads as "press photo, not yet specific" — honest
    // about being a placeholder without breaking the working-desk aesthetic.
    // The PolaroidDevelop wrapper provides the develop motion; this is just
    // the subject the chemistry acts on.
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 0.42, green: 0.40, blue: 0.36),
                    Color(.sRGB, red: 0.62, green: 0.58, blue: 0.50),
                    Color(.sRGB, red: 0.78, green: 0.72, blue: 0.62),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Two implied figures (rounded rects, off-center).
            VStack(spacing: 0) {
                Spacer()
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.ink.opacity(0.32))
                        .frame(width: 50, height: 80)
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.ink.opacity(0.28))
                        .frame(width: 50, height: 70)
                }
                .padding(.bottom, 18)
            }
        }
    }
}

// MARK: - Helpers

/// Per-cell entrance stagger — 80ms × cell index. Per the brief: "cells
/// auto-run their motion once on first appearance, staggered ~80ms."
private func stagger(_ index: Int) -> Duration {
    .milliseconds(80 * index)
}

#Preview("Light") {
    ChoreographyCatalog()
}

#Preview("Dark") {
    ChoreographyCatalog()
        .preferredColorScheme(.dark)
}

#endif
