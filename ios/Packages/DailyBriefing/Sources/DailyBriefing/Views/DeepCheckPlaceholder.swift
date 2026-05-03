// MARK: - DeepCheckPlaceholder
//
// Stub destination for tap-into-Deep-Check. The real Deep Check screen is the
// next PR. Per the 2026-05-03 brief §4 Scope:
//   "Deep Check is a stub destination (NavigationLink to a placeholder)."
//
// Renders the case-id and headline only — that's all the navigation surface
// needs to confirm the right pin opened. No styling theatrics; this view is
// deliberately plain so reviewers don't mistake it for designed.

import SwiftUI
import DesignSystem

public struct DeepCheckPlaceholder: View {
    let kase: Case

    public init(_ kase: Case) {
        self.kase = kase
    }

    public var body: some View {
        ZStack {
            Color.cork.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.section) {
                MonoLabel(kase.caseNumber)
                StoryText.headline(kase.headline)
                MonoLabel("DEEP CHECK · STUB", color: .pencil)
                Spacer()
            }
            .padding(Spacing.section)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
