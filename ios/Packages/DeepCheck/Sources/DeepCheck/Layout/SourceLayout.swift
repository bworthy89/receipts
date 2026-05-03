// MARK: - SourceLayout
//
// Hub-and-spoke placement of 5 source pins around a central headline anchor.
//
// Per the 2026-05-03 brief §5 Layout Strategy:
//   "5 source pins ... fanning around the central pin in an organic radial
//    arrangement (not strict-circle — varies in distance and angle for
//    cork-board feel)."
//
// Approach: 5 base angles spaced 72° apart and offset slightly so the first
// source doesn't sit directly above or below the headline (avoids the
// "satellite-dish symmetry" trap). Each base angle is jittered ±12° and
// each base radius is jittered ±18pt via a seeded RNG so the layout is
// stable per case and varies between cases.
//
// Positions are returned as offsets from the hub. The screen adds them to
// the headline's screen position to render each source pin.

import Foundation
import CoreGraphics
import SwiftUI

public struct SourcePlacement: Sendable, Equatable {
    /// Vector from the hub (central headline) to this source's center.
    public let offsetFromHub: CGSize
    /// Per-pin tilt — small cork-board rotation.
    public let rotation: Angle

    public init(offsetFromHub: CGSize, rotation: Angle) {
        self.offsetFromHub = offsetFromHub
        self.rotation = rotation
    }
}

public enum SourceLayout {

    public enum Metrics {
        /// Per-pin tilt range, ±this in degrees.
        public static let rotationRange: Double = 4.0
        /// Per-pin x-offset jitter, ±this.
        public static let xJitter: CGFloat = 8
        /// Per-pin y-offset jitter, ±this.
        public static let yJitter: CGFloat = 10
        /// Source-pin nominal width (used by the screen for sizing).
        public static let pinWidth: CGFloat = 140
        /// Source-pin nominal height.
        public static let pinHeight: CGFloat = 130
        /// Where the headline sits inside the board's scroll content (y).
        public static let headlineY: CGFloat = 290
        /// Reserve below the last source pin before the dossier starts.
        public static let bottomReserve: CGFloat = 80
    }

    /// Hand-tuned base offsets for 5 sources around a central hub, chosen to
    /// fit a 393pt-wide portrait viewport without horizontal clipping and
    /// to keep body-text overlap with the headline minimal. Sources sit in
    /// "above-left, above-right, below-far-left, below-mid, below-far-right"
    /// positions — a vertical fan, not a strict circle, because the headline
    /// pin (215pt wide) makes a true horizontal hub-and-spoke impossible on
    /// a phone screen without cropping.
    private static let baseOffsets: [CGSize] = [
        CGSize(width: -70,  height: -160), // 0 — above-left
        CGSize(width:  62,  height: -170), // 1 — above-right
        CGSize(width: -110, height:  175), // 2 — below-far-left
        CGSize(width:   6,  height:  195), // 3 — below-mid
        CGSize(width:  108, height:  178), // 4 — below-far-right
    ]

    /// Produce N placements around a hub. Positions are vector offsets from
    /// the hub center. Same seed → same layout.
    public static func layout(
        sourceCount: Int = 5,
        seed: UInt64
    ) -> [SourcePlacement] {
        guard sourceCount > 0 else { return [] }

        var rng = SplitMix64(seed: seed)
        var placements: [SourcePlacement] = []
        placements.reserveCapacity(sourceCount)

        for i in 0..<sourceCount {
            // Wrap if a future provider returns more than 5 sources; the
            // base table is the design target, not a hard ceiling.
            let base = baseOffsets[i % baseOffsets.count]
            let dx = base.width + CGFloat.random(in: -Metrics.xJitter...Metrics.xJitter, using: &rng)
            let dy = base.height + CGFloat.random(in: -Metrics.yJitter...Metrics.yJitter, using: &rng)
            let rotation = Angle.degrees(
                Double.random(in: -Metrics.rotationRange...Metrics.rotationRange, using: &rng)
            )

            placements.append(
                SourcePlacement(offsetFromHub: CGSize(width: dx, height: dy), rotation: rotation)
            )
        }

        return placements
    }

    /// Stable per-case seed derived from the case ID, so the same case
    /// renders the same source layout every time.
    public static func seed(forCaseID caseID: String) -> UInt64 {
        SplitMix64.seed(from: caseID)
    }

    /// Investigation-board content height needed to hold the hub + sources
    /// without clipping. Sources extend down to roughly `headlineY + max(dy)
    /// + yJitter + pinHeight/2`; round up so the StampSlam verdict has room.
    public static var boardHeight: CGFloat {
        let maxDownward = (baseOffsets.map(\.height).max() ?? 0)
        return Metrics.headlineY
            + maxDownward
            + Metrics.yJitter
            + Metrics.pinHeight / 2
            + Metrics.bottomReserve
    }
}

// MARK: - SplitMix64
//
// Small PRNG mirroring the one in `DailyBriefing.SeededRNG`. Lives here too
// so DeepCheck doesn't need to depend on DailyBriefing for a four-line
// utility. If a third caller appears, the right move is to lift this into
// a shared utility module.

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Stable, process-independent hash of a string's UTF-8 bytes.
    static func seed(from string: String) -> UInt64 {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        for byte in string.utf8 {
            state = state &+ UInt64(byte)
            state = (state ^ (state >> 30)) &* 0xBF58_476D_1CE4_E5B9
            state = (state ^ (state >> 27)) &* 0x94D0_49BB_1331_11EB
            state = state ^ (state >> 31)
        }
        return state
    }
}
