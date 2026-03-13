// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipFormat",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipFormat",
            path: "Sources/ClipFormat"
        )
    ]
)
