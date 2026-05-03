// MARK: - The Working-Desk Palette
//
// Four-role palette modeled on the physical artifacts of investigation. Each
// color is named for the object it's drawn from, not for its hue.
//
// Light mode: paper under a desk lamp at midday.
// Dark mode: same desk, dimmer lamp at 11pm. NOT system inverted dark — the
// cork is still cork, the paper is still paper, just lit differently. Per the
// "Dim Room" decision in the DesignSystem shape brief.
//
// Source values are OKLCH neighborhoods from DESIGN.md §2; concrete sRGB values
// were converted at craft time and are tuned via the DesignSystemCatalog screen.
//
// Named rules from DESIGN.md these colors enforce:
//   • The Red-String Rule — Color.evidence is for connection, verdict, flag only.
//   • The No-Pure-Black, No-Pure-White Rule — neutrals carry warm trace chroma.
//   • The Cork-Texture-Never-Decorative Rule — cork is a substrate color, not chrome.

import SwiftUI

extension Color {

    // MARK: Primary: substrate

    /// Cork Tan — the board itself. Substrate of the entire app.
    /// Light: warm mid-chroma tan (~OKLCH 70% L, 0.04 C, 80° H).
    /// Dark: dimmed warm-brown (~OKLCH 35% L, 0.04 C, 80° H), per the "Dim Room" mode.
    public static let cork = Color(
        light: Color(.sRGB, red: 0.756, green: 0.643, blue: 0.478),
        dark:  Color(.sRGB, red: 0.357, green: 0.290, blue: 0.196)
    )

    // MARK: Secondary: connection / verdict / flag

    /// Evidence Red — red string between sources, verdict stamps, flagged states.
    /// Restricted color — its rarity is the point. NEVER used for general UI accents.
    /// (The Red-String Rule.)
    /// Light: saturated red-yarn red (~OKLCH 55% L, 0.20 C, 25° H).
    /// Dark: a touch brighter for the subtle inner-glow Dim-Room treatment.
    public static let evidence = Color(
        light: Color(.sRGB, red: 0.784, green: 0.251, blue: 0.157),
        dark:  Color(.sRGB, red: 0.847, green: 0.345, blue: 0.220)
    )

    // MARK: Tertiary: archive / time-depth

    /// Polaroid Sepia — aged-paper for archived case files, polaroid borders,
    /// the developing-image animation midpoint. Signals time depth (older, stored, resolved).
    /// (~OKLCH 88% L, 0.04 C, 70° H light; ~OKLCH 70% L Dim-Room.)
    public static let sepia = Color(
        light: Color(.sRGB, red: 0.910, green: 0.847, blue: 0.710),
        dark:  Color(.sRGB, red: 0.722, green: 0.643, blue: 0.533)
    )

    // MARK: Neutrals: paper / ink / pencil

    /// Paper White — evidence cards, polaroid faces, source dossiers.
    /// Warm off-white (~OKLCH 96% L, 0.005 C, 75° H). Explicitly NOT #fff.
    /// Dim Room: a softer warm cream so paper still reads as paper under low light.
    public static let paper = Color(
        light: Color(.sRGB, red: 0.973, green: 0.957, blue: 0.929),
        dark:  Color(.sRGB, red: 0.847, green: 0.788, blue: 0.675)
    )

    /// Ink Black — body type, marker annotations, stamp ink.
    /// Soft warm near-black (~OKLCH 18% L, 0.01 C, 75° H). Explicitly NOT #000.
    /// Dim Room: stays near-black for legibility on the cream paper surface.
    public static let ink = Color(
        light: Color(.sRGB, red: 0.173, green: 0.149, blue: 0.114),
        dark:  Color(.sRGB, red: 0.149, green: 0.129, blue: 0.098)
    )

    /// Pencil Gray — secondary type, dividers, disabled states, undrawn map-string lines.
    /// Warm mid-gray (~OKLCH 55% L, 0.005 C, 75° H).
    public static let pencil = Color(
        light: Color(.sRGB, red: 0.569, green: 0.541, blue: 0.510),
        dark:  Color(.sRGB, red: 0.659, green: 0.624, blue: 0.580)
    )

    // MARK: Internal: shadow tint
    //
    // Internal — not part of the brand's named-roles vocabulary. Used by the
    // pinnedCardShadow / polaroidShadow / liftedShadow modifiers in Elevation.swift.
    //
    // Why this exists separately from `ink`: shadows must always be DARKER than
    // the substrate they fall on. Light mode = darken-toward-warm-near-black.
    // Dim Room dark mode = a deeper near-black than `ink` itself, because cork
    // in dark mode is already mid-luminance brown — using `ink` (which sits
    // near the dim-cork luminance) would make shadows invisible.
    static let shadowTint = Color(
        light: Color(.sRGB, red: 0.110, green: 0.090, blue: 0.060),
        dark:  Color(.sRGB, red: 0.020, green: 0.014, blue: 0.005)
    )
}

// MARK: - Color(light:dark:) helper
//
// SwiftUI doesn't ship a built-in light/dark literal initializer. Wrap UIColor's
// dynamic provider so consumers see a clean SwiftUI Color.

extension Color {
    fileprivate init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}
