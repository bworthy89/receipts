// MARK: - PinLayout
//
// Organic-chaos placement for pins on the daily-briefing cork board.
//
// Per the 2026-05-03 brief §5 Layout Strategy:
//   "Vertical-scrolling cork board. Pins are arranged in organic chaos within
//    a loose 2-column rhythm — staggered y-offsets, ±2–4° per-pin rotation,
//    asymmetric horizontal nudge, occasional corner overlap (decorative,
//    never on body text). Date stamp sits slammed into the top-right corner."
//
// And §10 open question:
//   "Pin layout algorithm. Random within constraints (with seeded RNG so it's
//    stable per day) vs hand-tuned positions. Lean seeded-random."
//
// The shape: two column centerlines at 30% and 70% of board width. Each row
// holds two pins, alternating which side leads. Per-pin x-nudge and y-jitter
// give the asymmetric corkboard feel; per-pin rotation supplies the small
// physical-tilt cue. Same seed → same layout, so the morning briefing is the
// same across re-renders within a day.

import Foundation
import CoreGraphics
import SwiftUI

public struct PinPlacement: Sendable, Equatable {
    public let x: CGFloat
    public let y: CGFloat
    public let rotation: Angle

    public init(x: CGFloat, y: CGFloat, rotation: Angle) {
        self.x = x
        self.y = y
        self.rotation = rotation
    }
}

public enum PinLayout {

    /// Layout constants exposed for the screen so the cork height can size to
    /// the placement output rather than being computed independently.
    public enum Metrics {
        /// Width of a torn note in the layout. The visual torn-edge can spill
        /// outside this slightly via the irregular path; the slot itself is
        /// fixed so columns line up loosely.
        public static let pinSlotWidth: CGFloat = 165
        /// Per-row vertical advance.
        public static let rowHeight: CGFloat = 175
        /// Where the first row starts under the date-stamp band. Note centers
        /// sit at `topMargin`, so the note's top edge is at
        /// `topMargin - nominalHeight/2` ≈ `topMargin - 73`. Keep this >= 175
        /// so the right-column first row doesn't overlap the date stamp at
        /// y=84 (which extends down to ~99 at scale 1.0).
        public static let topMargin: CGFloat = 180
        /// Trailing breathing room past the last row.
        public static let bottomMargin: CGFloat = 80
    }

    /// Produce N placements for a board of `boardWidth` width, deterministic
    /// for the given seed.
    public static func layout(
        count: Int,
        boardWidth: CGFloat,
        seed: UInt64
    ) -> [PinPlacement] {
        guard count > 0 else { return [] }

        var rng = SeededRNG(seed: seed)

        let leftCenter = boardWidth * 0.25
        let rightCenter = boardWidth * 0.75
        let xJitter: CGFloat = 12
        let yJitter: CGFloat = 14
        let rotationRange: Double = 3.0

        var placements: [PinPlacement] = []
        placements.reserveCapacity(count)

        for index in 0..<count {
            let row = index / 2
            let isLeftSlot = (index % 2 == 0)
            // Alternate "lead side" every other row so the visual path zig-zags
            // — first pin of row 0 sits left, first pin of row 1 sits right.
            let columnIsLeft = (row % 2 == 0) ? isLeftSlot : !isLeftSlot

            let columnCenter = columnIsLeft ? leftCenter : rightCenter

            let xNudge = CGFloat.random(in: -xJitter...xJitter, using: &rng)
            let yNudge = CGFloat.random(in: -yJitter...yJitter, using: &rng)
            let rotationDegrees = Double.random(in: -rotationRange...rotationRange, using: &rng)

            let baseY = Metrics.topMargin + CGFloat(row) * Metrics.rowHeight
            placements.append(
                PinPlacement(
                    x: columnCenter + xNudge,
                    y: baseY + yNudge,
                    rotation: .degrees(rotationDegrees)
                )
            )
        }

        return placements
    }

    /// Total scroll-content height the screen should reserve for `count`
    /// placements. Independent of boardWidth — the rows advance vertically
    /// regardless of horizontal jitter.
    public static func contentHeight(forCount count: Int) -> CGFloat {
        guard count > 0 else { return Metrics.topMargin + Metrics.bottomMargin }
        let rowCount = (count + 1) / 2  // 2-per-row, last row may be 1
        return Metrics.topMargin
            + CGFloat(rowCount) * Metrics.rowHeight
            + Metrics.bottomMargin
    }

    /// Day-of-year seed so the layout is stable within a day and rotates at
    /// midnight. Year is folded in too so a Jan 1 layout doesn't collide with
    /// a Dec 31 of the previous year.
    public static func seed(for day: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> UInt64 {
        let comps = calendar.dateComponents([.year, .dayOfYear], from: day)
        let year = UInt64(comps.year ?? 2026)
        let doy = UInt64(comps.dayOfYear ?? 1)
        return year &* 1000 &+ doy
    }
}
