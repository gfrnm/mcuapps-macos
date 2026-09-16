// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MCUApps",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "MCUApps",
            targets: ["MCUApps"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MCUApps",
            dependencies: [],
            path: "Sources/MCUApps"
        )
    ]
)
