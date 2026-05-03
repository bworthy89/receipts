// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PersistenceKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
    ],
    dependencies: [
        .package(path: "../APIClient"),
    ],
    targets: [
        .target(
            name: "PersistenceKit",
            dependencies: ["APIClient"]
        ),
        .testTarget(
            name: "PersistenceKitTests",
            dependencies: ["PersistenceKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
