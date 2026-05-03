import Testing
import Foundation
import CoreGraphics
@testable import DailyBriefing

@Suite("PinLayout")
struct PinLayoutTests {

    /// Layout returns exactly the number of placements requested.
    @Test("Layout returns count placements")
    func placementsCountMatches() {
        let placements = PinLayout.layout(count: 10, boardWidth: 390, seed: 42)
        #expect(placements.count == 10)
    }

    /// Empty layout for count=0 — defensively handled.
    @Test("Layout handles count=0")
    func emptyCount() {
        let placements = PinLayout.layout(count: 0, boardWidth: 390, seed: 42)
        #expect(placements.isEmpty)
    }

    /// Same seed → identical placements. The screen relies on this for
    /// stable-per-day positioning across re-renders within a session.
    @Test("Layout is deterministic for the same seed")
    func deterministic() {
        let a = PinLayout.layout(count: 10, boardWidth: 390, seed: 42)
        let b = PinLayout.layout(count: 10, boardWidth: 390, seed: 42)
        #expect(a == b)
    }

    /// Different seeds → different placements, so the per-day rotation is
    /// not a no-op.
    @Test("Different seeds produce different layouts")
    func differentSeedsDiffer() {
        let a = PinLayout.layout(count: 10, boardWidth: 390, seed: 42)
        let b = PinLayout.layout(count: 10, boardWidth: 390, seed: 99)
        #expect(a != b)
    }

    /// Pins distribute across both columns — the brief asks for "loose 2-
    /// column rhythm". With 10 pins and column centerlines at 30%/70%, both
    /// halves of the board should be hit. Threshold of "≥3 in each half"
    /// allows for jitter without false positives.
    @Test("Pins distribute across both columns")
    func bothColumnsUsed() {
        let boardWidth: CGFloat = 390
        let placements = PinLayout.layout(count: 10, boardWidth: boardWidth, seed: 42)
        let leftHalf = placements.filter { $0.x < boardWidth / 2 }
        let rightHalf = placements.filter { $0.x >= boardWidth / 2 }
        #expect(leftHalf.count >= 3)
        #expect(rightHalf.count >= 3)
    }

    /// Per-pin rotation stays within ±4° (the brief commits to ±2–4°). A
    /// rotation outside the window means the jitter range drifted.
    @Test("Per-pin rotation stays within ±4°")
    func rotationBounded() {
        let placements = PinLayout.layout(count: 50, boardWidth: 390, seed: 7)
        for placement in placements {
            #expect(abs(placement.rotation.degrees) <= 4.0)
        }
    }

    /// y-positions advance monotonically per row pair. Pins 0+1 share row 0,
    /// pins 2+3 share row 1, etc. The center-of-row for pin 2 should sit
    /// below the center-of-row for pin 0. Per-pin y-jitter can break strict
    /// per-pin monotonicity, but per-row averages must increase.
    @Test("Rows advance vertically")
    func rowsAdvance() {
        let placements = PinLayout.layout(count: 10, boardWidth: 390, seed: 42)
        let rowAverages: [CGFloat] = stride(from: 0, to: placements.count, by: 2).map { i in
            let pair = placements[i..<min(i + 2, placements.count)]
            let sum = pair.reduce(CGFloat(0)) { $0 + $1.y }
            return sum / CGFloat(pair.count)
        }
        for i in 1..<rowAverages.count {
            #expect(rowAverages[i] > rowAverages[i - 1])
        }
    }

    /// contentHeight scales with row count and includes top + bottom margins.
    @Test("contentHeight reflects row count")
    func contentHeightShape() {
        let h10 = PinLayout.contentHeight(forCount: 10)  // 5 rows
        let h2 = PinLayout.contentHeight(forCount: 2)    // 1 row
        #expect(h10 > h2)

        let metricsTop = PinLayout.Metrics.topMargin
        let metricsBottom = PinLayout.Metrics.bottomMargin
        let metricsRow = PinLayout.Metrics.rowHeight
        // 1 row of content = topMargin + 1*rowHeight + bottomMargin
        #expect(h2 == metricsTop + metricsRow + metricsBottom)
    }

    /// `seed(for:)` produces stable seeds for the same day and different
    /// seeds for different days. Verifies the day-of-year folding doesn't
    /// hash-collide across nearby dates.
    @Test("seed(for:) is stable per day, distinct across days")
    func seedShape() {
        let cal = Calendar(identifier: .gregorian)
        let mayThird = makeDate(year: 2026, month: 5, day: 3, calendar: cal)
        let mayFourth = makeDate(year: 2026, month: 5, day: 4, calendar: cal)

        #expect(PinLayout.seed(for: mayThird, calendar: cal) == PinLayout.seed(for: mayThird, calendar: cal))
        #expect(PinLayout.seed(for: mayThird, calendar: cal) != PinLayout.seed(for: mayFourth, calendar: cal))
    }

    private func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps) ?? Date()
    }
}
