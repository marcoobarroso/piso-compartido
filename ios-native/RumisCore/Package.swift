// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RumisCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RumisCore", targets: ["RumisCore"])
    ],
    targets: [
        .target(name: "RumisCore"),
        .testTarget(name: "RumisCoreTests", dependencies: ["RumisCore"]),
    ]
)
