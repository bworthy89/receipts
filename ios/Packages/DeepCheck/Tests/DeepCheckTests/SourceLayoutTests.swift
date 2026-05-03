import Testing
import Foundation
import CoreGraphics
@testable import DeepCheck

@Suite("SourceLayout")
struct SourceLayoutTests {

    @Test("Layout returns 5 placements by default")
    func defaultCount() {
        let placements = SourceLayout.layout(seed: 42)
        #expect(placements.count == 5)
    }

    @Test("Layout returns N placements when overridden")
    func customCount() {
        let placements = SourceLayout.layout(sourceCount: 7, seed: 42)
        #expect(placements.count == 7)
    }

    @Test("Layout handles count=0")
    func zeroCount() {
        let placements = SourceLayout.layout(sourceCount: 0, seed: 42)
        #expect(placements.isEmpty)
    }

    @Test("Same seed → identical placements")
    func deterministic() {
        let a = SourceLayout.layout(seed: 42)
        let b = SourceLayout.layout(seed: 42)
        #expect(a == b)
    }

    @Test("Different seeds → different placements")
    func differentSeeds() {
        let a = SourceLayout.layout(seed: 42)
        let b = SourceLayout.layout(seed: 99)
        #expect(a != b)
    }

    /// All 5 source placements stay within the iPhone-portrait viewport
    /// when overlaid on a 393pt-wide screen with the hub at center. This is
    /// the constraint that drove the hand-tuned base offsets.
    @Test("Placements fit a 393pt-wide portrait viewport")
    func placementsFitNarrowViewport() {
        let placements = SourceLayout.layout(seed: 42)
        let pinHalfWidth = SourceLayout.Metrics.pinWidth / 2
        let viewportHalfWidth: CGFloat = 393 / 2
        for p in placements {
            let absX = abs(p.offsetFromHub.width)
            #expect(absX + pinHalfWidth <= viewportHalfWidth, "placement x \(p.offsetFromHub.width) clips viewport")
        }
    }

    @Test("Per-pin rotation stays within ±4°")
    func rotationBounded() {
        let placements = SourceLayout.layout(seed: 42)
        for p in placements {
            #expect(abs(p.rotation.degrees) <= SourceLayout.Metrics.rotationRange)
        }
    }

    /// `seed(forCaseID:)` is process-stable so the same case always renders
    /// the same source layout (mirroring the briefing's PinLayout pattern).
    @Test("seed(forCaseID:) is process-stable")
    func seedStable() {
        let a = SourceLayout.seed(forCaseID: "mock-headline-3")
        let b = SourceLayout.seed(forCaseID: "mock-headline-3")
        #expect(a == b)
    }

    @Test("seed(forCaseID:) varies across cases")
    func seedDistinct() {
        let a = SourceLayout.seed(forCaseID: "mock-headline-3")
        let b = SourceLayout.seed(forCaseID: "mock-headline-4")
        #expect(a != b)
    }

    @Test("boardHeight covers hub + furthest-down source + reserve")
    func boardHeightShape() {
        let h = SourceLayout.boardHeight
        let lowerBound = SourceLayout.Metrics.headlineY + SourceLayout.Metrics.bottomReserve
        #expect(h > lowerBound)
    }
}
