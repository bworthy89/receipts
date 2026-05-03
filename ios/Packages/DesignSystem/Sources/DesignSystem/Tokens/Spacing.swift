// MARK: - Spacing scale
//
// 4-pt base. Per the DesignSystem shape brief §10 open question: "Default
// suggestion: a 4pt-based scale (4, 8, 12, 16, 24, 32, 48). Confirm during
// craft." Confirmed at craft time — these are the values.
//
// Use as `Spacing.cardPadding` instead of literal `16` so spacing changes are
// system-wide, not scattered across feature code.

import SwiftUI

public enum Spacing {
    /// 4pt — hairline gap between adjacent labels.
    public static let hairline: CGFloat = 4

    /// 8pt — inline icon-to-text spacing, dense list rows.
    public static let tight: CGFloat = 8

    /// 12pt — vertical rhythm between paragraphs in a card.
    public static let snug: CGFloat = 12

    /// 16pt — default padding inside a paper card; default spacing between
    /// adjacent paper cards on the cork board.
    public static let cardPadding: CGFloat = 16

    /// 24pt — section breaks within a dossier; gap between unrelated card clusters.
    public static let section: CGFloat = 24

    /// 32pt — horizontal margin from the cork board edge.
    public static let boardMargin: CGFloat = 32

    /// 48pt — major vertical breathing room (top of board, dossier headers).
    public static let stadium: CGFloat = 48
}
