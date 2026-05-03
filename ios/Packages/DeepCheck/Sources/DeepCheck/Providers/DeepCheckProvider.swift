// MARK: - DeepCheckProvider
//
// Source of the per-case investigation data. Protocol so the screen doesn't
// know whether the data came from a fixture, a backend, or an on-device
// model.
//
// `investigation(for:)` takes the briefing case and returns the matching
// investigation. Implementations must return the same investigation for the
// same case within a session — the screen relies on stable identity so the
// playback animation re-uses the same source pins on repeat.

import Foundation
import Models

public protocol DeepCheckProvider: Sendable {
    /// Returns the investigation for the given case. Throws if the case is
    /// unknown to the provider (e.g. a stale briefing pin pointing at a
    /// retired case).
    func investigation(for kase: Case) async throws -> Investigation
}

public enum DeepCheckProviderError: Error, Sendable {
    case unknownCase(String)
}
