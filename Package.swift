// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mochi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MochiCLI", targets: ["Mochi"])
    ],
    targets: [
        .executableTarget(
            name: "Mochi",
            path: "Mochi"
        ),
        .testTarget(
            name: "MochiTests",
            dependencies: ["Mochi"],
            path: "MochiTests"
        )
    ]
)
