import SwiftUI

/// One humanist sans family across the whole app. Weight + size do the hierarchy work.
/// Sizes are starting points; Dynamic Type scales them.
public enum ForRealType {
    /// 56pt heavy — the verdict word on the fax. Single largest type element on any screen.
    public static let verdictDisplay: Font = .system(size: 56, weight: .heavy, design: .default)
    /// 24pt semibold — claim text and primary copy.
    public static let headline: Font = .system(size: 24, weight: .semibold, design: .default)
    /// 16pt regular — bestie commentary, source titles.
    public static let body: Font = .system(size: 16, weight: .regular, design: .default)
    /// 12pt medium — metadata. Slight tracking via .tracking(...) at the call site.
    public static let label: Font = .system(size: 12, weight: .medium, design: .default)
}

public extension View {
    /// Convenience: apply ForRealType.label and the project's standard tracking + uppercase.
    func forRealLabelStyle() -> some View {
        self.font(ForRealType.label)
            .tracking(1.2)
            .textCase(.uppercase)
    }
}
