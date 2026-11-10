// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TCLRemote",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "TCLRemote"),
        .testTarget(name: "TCLRemoteTests", dependencies: ["TCLRemote"]),
    ],
    swiftLanguageModes: [.v5]
)
