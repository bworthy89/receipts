// MARK: - DesignSystemCatalog
//
// One scrollable screen showing every token + primitive in receipts-voice
// context. The visual contract for impeccable critique/polish passes — this is
// what reviewers look at to decide if the substrate is right.
//
// #if DEBUG so the catalog ships in development builds and is omitted from
// App Store builds. Per the shape brief Q6-a / §10 — chose #if DEBUG over a
// separate target to keep package overhead low.
//
// Per the brief §8 Content Requirements: receipts-voice copy throughout. No
// Lorem Ipsum. Sample headlines and case-numbers feel real.

#if DEBUG

import SwiftUI

public struct DesignSystemCatalog: View {

    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    header

                    section("Palette") {
                        paletteSection
                    }

                    section("Typography — story voice") {
                        storyVoiceSection
                    }

                    section("Typography — file voice") {
                        fileVoiceSection
                    }

                    section("Marker overlay") {
                        markerSection
                    }

                    section("Elevation") {
                        elevationSection
                    }

                    section("Primitives in context") {
                        inContextSection
                    }
                    .padding(.top, Spacing.section)  // breathing room — the marker overlay
                                                    // hangs OFF the card and was overlapping
                                                    // the section label above without this.

                    Spacer().frame(height: Spacing.stadium)
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

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.tight) {
            MonoLabel("DESIGN SYSTEM · CATALOG · v1")
            StoryText.display("The Working Desk")
            StoryText.body("Every token and primitive the rest of the app composes from. If it does not feel right here, it will not feel right anywhere.")
        }
    }

    private var paletteSection: some View {
        let entries: [(String, Color)] = [
            ("CORK", .cork),
            ("PAPER", .paper),
            ("INK", .ink),
            ("EVIDENCE", .evidence),
            ("SEPIA", .sepia),
            ("PENCIL", .pencil),
        ]
        return LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 140), spacing: Spacing.snug)],
            spacing: Spacing.snug
        ) {
            ForEach(entries, id: \.0) { (name, color) in
                VStack(spacing: Spacing.tight) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .overlay(
                            // Stroke so the swatch reads against ANY substrate —
                            // critical for cork-on-cork and paper-on-paper cases.
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.ink.opacity(0.20), lineWidth: 0.5)
                        )
                        .frame(height: 80)
                        .pinnedCardShadow()
                    MonoLabel(name)
                }
            }
        }
    }

    private var storyVoiceSection: some View {
        PaperSurface {
            VStack(alignment: .leading, spacing: Spacing.snug) {
                StoryText.display("Display")
                StoryText.headline("Headline — Senate passes infrastructure bill")
                StoryText.title("Title — Cross-source verification")
                StoryText.body("Body — 23 outlets covered the Senate vote in the four hours after it was called. Eight from the political left, eleven from the center, four from the right. Their framings differ on three observable axes.")
            }
            .padding(Spacing.cardPadding)
        }
    }

    private var fileVoiceSection: some View {
        PaperSurface {
            VStack(alignment: .leading, spacing: Spacing.snug) {
                MonoLabel("CASE #4271 · 21:14 EDT", style: .standard, color: .pencil)
                MonoLabel("STAMP · CONFIRMED · 0.92", style: .prominent, color: .ink)
                HStack(spacing: Spacing.snug) {
                    MonoLabel("REUTERS · L 0.0", color: .pencil)
                    MonoLabel("AP · L 0.1", color: .pencil)
                    MonoLabel("FOX · R 5.4", color: .pencil)
                }
            }
            .padding(Spacing.cardPadding)
        }
    }

    private var markerSection: some View {
        HStack(spacing: Spacing.section) {
            MarkerNote("PERSON OF INTEREST")
            MarkerNote("FOLLOW THE MONEY", rotation: .degrees(2))
            MarkerNote("COLD CASE", rotation: .degrees(-5))
        }
    }

    private var elevationSection: some View {
        HStack(alignment: .top, spacing: Spacing.section) {
            elevationSwatch(label: "PINNED") { rect in
                rect.pinnedCardShadow()
            }
            elevationSwatch(label: "POLAROID") { rect in
                rect.polaroidShadow()
            }
            elevationSwatch(label: "LIFTED") { rect in
                rect.liftedShadow()
            }
        }
    }

    @ViewBuilder
    private func elevationSwatch(
        label: String,
        @ViewBuilder shadow: (AnyView) -> some View
    ) -> some View {
        VStack(spacing: Spacing.snug) {
            shadow(AnyView(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.paper)
                    .frame(width: 110, height: 110)
            ))
            MonoLabel(label, color: .pencil)
        }
    }

    private var inContextSection: some View {
        ZStack(alignment: .topLeading) {
            PaperSurface {
                VStack(alignment: .leading, spacing: Spacing.snug) {
                    MonoLabel("CASE #4271 · 21:14 EDT")
                    StoryText.headline("Senate passes infrastructure bill after weeks of negotiation")
                    StoryText.body("23 outlets · 8 left, 11 center, 4 right. Cross-source verification reveals three points of disagreement on the package's energy-grid provisions; everything else is aligned.")
                }
                .padding(Spacing.cardPadding)
            }
            .frame(maxWidth: 360)

            MarkerNote("FOLLOW THE MONEY", rotation: .degrees(-4))
                .offset(x: -8, y: -14)
        }
    }

    // MARK: Section header helper

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.snug) {
            MonoLabel(title, color: .pencil)
            content()
        }
    }
}

#Preview("Light") {
    DesignSystemCatalog()
}

#Preview("Dark") {
    DesignSystemCatalog()
        .preferredColorScheme(.dark)
}

#endif
