// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "tairu",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "tairu", targets: ["TairuCLI"]),
        .library(name: "TairuCore", targets: ["TairuCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "TairuCLI",
            dependencies: [
                "TairuCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "TairuCore",
            dependencies: []
        ),
        .testTarget(
            name: "TairuCoreTests",
            dependencies: ["TairuCore"]
        ),
    ]
)
