// MARK: - Two Voices: story (serif) and file (mono)
//
// Per DESIGN.md §3 — The Two-Voices Rule.
//   • Editorial serif carries the *story*: headlines, dek, verdict copy.
//   • Monospace carries the *file*: case numbers, timestamps, source IDs,
//     stamp inscriptions, BiasMeter labels — the procedural metadata layer.
//
// v1 uses Apple's system serif and monospaced designs (per the shape brief Q2-b).
// They give story/file separation without licensing real fonts. Revisit at App
// Store launch.
//
// The Dynamic Type Honors The File Rule: mono labels scale with Dynamic Type
// the same as body. Procedural metadata is content, not chrome.

import SwiftUI

extension Font {

    // MARK: Story voice — serif

    /// Top-of-case headlines, daily-briefing reveal type. Sparse use — once per screen at most.
    public static let storyDisplay = Font.system(.largeTitle, design: .serif, weight: .regular)

    /// Story titles on the board.
    public static let storyHeadline = Font.system(.title, design: .serif, weight: .regular)

    /// Card titles, section headers inside dossiers.
    public static let storyTitle = Font.system(.title3, design: .serif, weight: .medium)

    /// Article body, source quotes, dek copy. ~1.5 line-height applied at the view level.
    public static let storyBody = Font.system(.body, design: .serif, weight: .regular)

    // MARK: File voice — monospaced

    /// Case numbers, stamp inscriptions, source IDs, timestamps, BiasMeter labels.
    /// Slight tracking + uppercase applied at the view level (MonoLabel takes care of it).
    public static let fileLabel = Font.system(.footnote, design: .monospaced, weight: .medium)

    /// Larger mono — stamp inscriptions when the stamp itself fills space.
    public static let fileTitle = Font.system(.subheadline, design: .monospaced, weight: .semibold)

    // MARK: Marker voice — overlay seasoning only

    /// "PERSON OF INTEREST" sticker overlays, post-it callouts, archive marginalia.
    /// NEVER used for body or anything readers must scan quickly.
    /// (The No-Costume-Type Rule.) Falls back to .rounded since iOS doesn't ship a marker face.
    public static let markerNote = Font.system(.callout, design: .rounded, weight: .heavy)
}
