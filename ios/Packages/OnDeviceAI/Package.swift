// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OnDeviceAI",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "OnDeviceAI", targets: ["OnDeviceAI"]),
    ],
    targets: [
        .target(name: "OnDeviceAI"),
    ],
    swiftLanguageModes: [.v6]
)
