// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DeepCheck",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "DeepCheck", targets: ["DeepCheck"]),
    ],
    dependencies: [
        .package(path: "../Models"),
        .package(path: "../DesignSystem"),
        .package(path: "../Choreography"),
    ],
    targets: [
        .target(
            name: "DeepCheck",
            dependencies: ["Models", "DesignSystem", "Choreography"]
        ),
        .testTarget(
            name: "DeepCheckTests",
            dependencies: ["DeepCheck", "Models"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
