// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DailyBriefing",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "DailyBriefing", targets: ["DailyBriefing"]),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Choreography"),
    ],
    targets: [
        .target(
            name: "DailyBriefing",
            dependencies: ["DesignSystem", "Choreography"]
        ),
        .testTarget(
            name: "DailyBriefingTests",
            dependencies: ["DailyBriefing"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
