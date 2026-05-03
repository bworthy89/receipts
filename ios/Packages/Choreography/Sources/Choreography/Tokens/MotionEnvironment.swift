// MARK: - choreographyReducedMotion environment override
//
// SwiftUI's `accessibilityReduceMotion` environment value is read-only — it
// reflects the system setting and cannot be overridden via `.environment()`.
// The catalog needs to override Reduce-Motion *per cell* to demonstrate both
// the full and reduced variants on a single device, so we publish an internal
// override env value that motion views consult alongside the system setting.
//
// `choreographyReducedMotion` is **internal**, not public:
//   • External consumers (feature packages, app code) can't reach the key,
//     so they always pick up the system Reduce-Motion setting unchanged. The
//     "no escape hatch" contract of the motion views is preserved at the
//     public API surface.
//   • The catalog (same module, so `internal` is reachable) sets it per cell.
//
// Each Choreography motion view reads both values and resolves:
//
//     reduceMotion = motionOverride ?? systemReduceMotion
//
// per the 2026-05-03 brief §6 "the override lives in the catalog cell, not in
// the motion API."

import SwiftUI

extension EnvironmentValues {
    /// Catalog-only override for the Reduce-Motion variant. `nil` (default)
    /// defers to the system setting; non-nil forces the value for descendants.
    /// Internal so only `ChoreographyCatalog` and the motion views can touch it.
    @Entry var choreographyReducedMotion: Bool? = nil
}
