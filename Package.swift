// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BetterGreenButton",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "BetterGreenButton",
            path: "Sources/BetterGreenButton"
        )
    ]
)
