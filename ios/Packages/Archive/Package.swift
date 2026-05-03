// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Archive",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "Archive", targets: ["Archive"]),
    ],
    dependencies: [
        .package(path: "../Models"),
        .package(path: "../DesignSystem"),
        .package(path: "../DeepCheck"),
    ],
    targets: [
        .target(
            name: "Archive",
            dependencies: ["Models", "DesignSystem", "DeepCheck"]
        ),
        .testTarget(
            name: "ArchiveTests",
            dependencies: ["Archive", "Models", "DeepCheck"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
