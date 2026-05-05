// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ForRealUI",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "ForRealUI", targets: ["ForRealUI"]),
    ],
    dependencies: [
        .package(path: "../ForRealKit"),
    ],
    targets: [
        .target(name: "ForRealUI", dependencies: ["ForRealKit"]),
        .testTarget(name: "ForRealUITests", dependencies: ["ForRealUI"]),
    ],
    swiftLanguageModes: [.v6]
)
