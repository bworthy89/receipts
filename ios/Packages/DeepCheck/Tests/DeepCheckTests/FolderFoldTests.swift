import Testing
import CoreGraphics
@testable import DeepCheck

@Suite("FolderFold gesture math")
struct FolderFoldTests {

    @Test("progress(for:) clamps below zero to zero")
    func clampsNegative() {
        #expect(FolderFold.progress(for: -50) == 0)
    }

    @Test("progress(for:) clamps above foldHeight to one")
    func clampsAboveCeiling() {
        #expect(FolderFold.progress(for: FolderFold.foldHeight * 2) == 1)
    }

    @Test("progress(for:) is linear in the open range")
    func linearInRange() {
        let halfDrag = FolderFold.foldHeight / 2
        let p = FolderFold.progress(for: halfDrag)
        #expect(p == 0.5)
    }

    /// Past the dismiss threshold on release commits to dismiss; below it,
    /// the host view snaps progress back to 0. The threshold is the only
    /// load-bearing constant for the dismiss decision.
    @Test("shouldDismiss is false below threshold, true above")
    func thresholdBoundary() {
        #expect(!FolderFold.shouldDismiss(at: FolderFold.dismissThreshold - 0.01))
        #expect(FolderFold.shouldDismiss(at: FolderFold.dismissThreshold))
        #expect(FolderFold.shouldDismiss(at: FolderFold.dismissThreshold + 0.01))
    }

    /// Threshold sits inside the (0, 1) interval — sanity check, not a
    /// design constraint, but a regression test against accidentally
    /// pushing it outside the valid range.
    @Test("Threshold is strictly inside (0, 1)")
    func thresholdInRange() {
        #expect(FolderFold.dismissThreshold > 0)
        #expect(FolderFold.dismissThreshold < 1)
    }
}
