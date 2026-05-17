// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mochi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Mochi", targets: ["MochiApp"]),
        .library(name: "MochiCore", targets: ["MochiCore"])
    ],
    targets: [
        .target(
            name: "MochiCore",
            path: "MochiCore"
        ),
        .executableTarget(
            name: "MochiApp",
            dependencies: ["MochiCore"],
            path: "Mochi",
            resources: [
                .process("Assets")
            ]
        ),
        .testTarget(
            name: "MochiTests",
            dependencies: ["MochiApp", "MochiCore"],
            path: "MochiTests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
