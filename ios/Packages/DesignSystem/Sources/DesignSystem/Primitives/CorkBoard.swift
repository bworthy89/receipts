// MARK: - CorkBoard
//
// The substrate of the entire app. Every screen starts from cork and adds paper.
//
// Per DESIGN.md §6 Do: "treat Cork Tan as the substrate of the entire app. New
// screens start from cork and add paper, not from paper and add cork as a
// decoration."
//
// v1: solid Cork Tan fill. Cork-grain texture is deferred (per the shape brief
// §10) — landing in a refinement PR via SwiftUI ShaderLibrary noise composited
// on Cork Tan. The texture decision lives inside this component, not at the
// token layer (per The Cork-Texture-Never-Decorative Rule — texture only on
// surfaces that ARE the board, never as chrome).

import SwiftUI

public struct CorkBoard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Color.cork.ignoresSafeArea()
            content
        }
    }
}
