// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Choreography",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "Choreography", targets: ["Choreography"]),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "Choreography",
            dependencies: ["DesignSystem"]
        ),
        .testTarget(
            name: "ChoreographyTests",
            dependencies: ["Choreography"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
