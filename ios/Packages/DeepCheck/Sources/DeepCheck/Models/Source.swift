// MARK: - Source
//
// One of the five sources interrogated during a Deep Check. UI-driving model
// for now; will map to a backend wire format when a real provider replaces
// `MockProvider`.
//
// Per the 2026-05-03 deep-check brief §5: each source pin is a manila-folder-
// tab card with the outlet name in mono on the tab and a ~25-word excerpt in
// the paper-white body.
//
// `Identifiable` via `id` so SwiftUI ForEach is stable across re-renders.

import Foundation

public struct Source: Sendable, Equatable, Identifiable {
    public let id: String
    public let outlet: String
    public let excerpt: String
    public let publishedOn: Date

    public init(
        id: String,
        outlet: String,
        excerpt: String,
        publishedOn: Date
    ) {
        self.id = id
        self.outlet = outlet
        self.excerpt = excerpt
        self.publishedOn = publishedOn
    }
}
