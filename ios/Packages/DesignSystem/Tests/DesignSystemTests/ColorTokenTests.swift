import Testing
import SwiftUI
@testable import DesignSystem

@Suite("Color tokens")
struct ColorTokenTests {

    /// Smoke test — every public color token resolves without crashing.
    /// Catches the "I removed cork from the public surface" regression instantly.
    @Test("all named tokens are reachable")
    func allTokensReachable() {
        _ = Color.cork
        _ = Color.paper
        _ = Color.ink
        _ = Color.evidence
        _ = Color.sepia
        _ = Color.pencil
    }

    /// The No-Pure-Black, No-Pure-White Rule (DESIGN.md §2).
    /// A test that compares `Color.paper` to literal #fff and `Color.ink` to
    /// literal #000 guards against accidental regression to the OS defaults.
    /// Approximation tolerance accounts for sRGB float precision.
    @Test("paper is not pure white")
    func paperIsNotWhite() throws {
        let paperRGB = try resolveSRGB(Color.paper, scheme: .light)
        // Pure white would be (1.0, 1.0, 1.0). Paper white sits well below 1.0
        // on at least one channel because of the warm trace chroma.
        #expect(paperRGB.red < 0.99)
        #expect(paperRGB.green < 0.97)  // green channel is more shifted toward warm
        #expect(paperRGB.blue < 0.95)
    }

    @Test("ink is not pure black")
    func inkIsNotBlack() throws {
        let inkRGB = try resolveSRGB(Color.ink, scheme: .light)
        // Pure black would be (0.0, 0.0, 0.0). Ink sits well above 0.0 because
        // of the warm trace chroma (tinted toward the cork hue).
        #expect(inkRGB.red > 0.10)
        #expect(inkRGB.green > 0.10)
        #expect(inkRGB.blue > 0.05)
    }

    /// Evidence Red is a saturated red-yarn red, not a UI alert red.
    /// Red channel must dominate; green and blue should be much lower.
    @Test("evidence red has dominant red channel")
    func evidenceIsRed() throws {
        let rgb = try resolveSRGB(Color.evidence, scheme: .light)
        #expect(rgb.red > 0.5)
        #expect(rgb.green < 0.4)
        #expect(rgb.blue < 0.3)
    }

    /// Cork tan is warm: red and green dominate, blue is low.
    @Test("cork is a warm tan")
    func corkIsWarm() throws {
        let rgb = try resolveSRGB(Color.cork, scheme: .light)
        #expect(rgb.red > 0.5)
        #expect(rgb.green > 0.4)
        #expect(rgb.blue < 0.6)
        #expect(rgb.red > rgb.blue)  // warmth: more red than blue
    }

    /// Light and dark variants resolve to different sRGB values.
    /// Cork in light should be brighter than cork in dark (Dim Room mode).
    /// Runs on both iOS (UITraitCollection-driven) and macOS (NSAppearance-driven).
    @Test("cork has distinct light and dark variants")
    func corkLightVsDark() throws {
        let lightRGB = try resolveSRGB(Color.cork, scheme: .light)
        let darkRGB = try resolveSRGB(Color.cork, scheme: .dark)
        // Brightness proxy: sum of channels.
        let lightSum = lightRGB.red + lightRGB.green + lightRGB.blue
        let darkSum = darkRGB.red + darkRGB.green + darkRGB.blue
        #expect(lightSum > darkSum)  // light mode is brighter than Dim Room dark
    }
}

// MARK: - Test helper: resolve a SwiftUI Color to sRGB under a specific color scheme

private struct RGBA: Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

private enum ColorResolveError: Error {
    case couldNotExtractComponents
}

#if canImport(UIKit)
import UIKit

private func resolveSRGB(_ color: Color, scheme: ColorScheme) throws -> RGBA {
    let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
    let resolved = UIColor(color).resolvedColor(with: traits)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
        throw ColorResolveError.couldNotExtractComponents
    }
    return RGBA(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
}
#else
// macOS host (the swift test runner builds for macOS host).
// Drives NSColor's dynamic provider via NSAppearance.performAsCurrentDrawingAppearance.
import AppKit

private func resolveSRGB(_ color: Color, scheme: ColorScheme) throws -> RGBA {
    let appearanceName: NSAppearance.Name = scheme == .dark ? .darkAqua : .aqua
    let appearance = NSAppearance(named: appearanceName)!
    var resolved: NSColor?
    appearance.performAsCurrentDrawingAppearance {
        resolved = NSColor(color).usingColorSpace(.sRGB)
    }
    guard let converted = resolved else {
        throw ColorResolveError.couldNotExtractComponents
    }
    return RGBA(
        red: Double(converted.redComponent),
        green: Double(converted.greenComponent),
        blue: Double(converted.blueComponent),
        alpha: Double(converted.alphaComponent)
    )
}
#endif
