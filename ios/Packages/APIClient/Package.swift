// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "APIClient",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "APIClient", targets: ["APIClient"]),
    ],
    dependencies: [
        .package(path: "../Models"),
    ],
    targets: [
        .target(
            name: "APIClient",
            dependencies: ["Models"]
        ),
        .testTarget(
            name: "APIClientTests",
            dependencies: ["APIClient", "Models"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
