import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// A wrapper around Apple's Foundation Models framework.
/// Methods are added by feature plans as they need them — this package is intentionally
/// thin in v1; it exists so feature code can depend on a stable interface from day one.
///
/// Type-system constraint: implementations must not perform any network I/O. Foundation
/// Models runs entirely on-device; that's the privacy + speed value proposition.
public protocol OnDeviceAI: Sendable {
    /// True if the on-device model is available and ready to run inference on this device.
    /// On iOS 26+ devices with Apple Intelligence enabled this returns true; otherwise false.
    var isAvailable: Bool { get async }
}

/// Default implementation backed by Apple's Foundation Models framework (iOS 26+).
@available(iOS 26, macOS 26, *)
public struct FoundationModelsAI: OnDeviceAI {
    public init() {}

    public var isAvailable: Bool {
        get async {
            #if canImport(FoundationModels)
            return SystemLanguageModel.default.availability == .available
            #else
            return false
            #endif
        }
    }
}
