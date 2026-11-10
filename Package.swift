// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TCLRemote",
    platforms: [.macOS(.v15)],
    targets: [
        // Core: TV protocols, discovery, models, persistence. No UI.
        .target(name: "TVKit"),
        // Menu bar app: SwiftUI presentation + app state.
        .executableTarget(name: "TCLRemote", dependencies: ["TVKit"]),
        .testTarget(name: "TVKitTests", dependencies: ["TVKit"]),
    ],
    swiftLanguageModes: [.v5]
)
