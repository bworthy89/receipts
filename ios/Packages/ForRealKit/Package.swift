// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ForRealKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "ForRealKit", targets: ["ForRealKit"]),
    ],
    targets: [
        .target(name: "ForRealKit"),
        .testTarget(name: "ForRealKitTests", dependencies: ["ForRealKit"]),
    ],
    swiftLanguageModes: [.v6]
)
