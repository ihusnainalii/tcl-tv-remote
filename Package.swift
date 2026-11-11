// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TCLRemote",
    defaultLocalization: "en",
    platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v11)],
    products: [
        .library(name: "TVKit", targets: ["TVKit"]),
        .library(name: "RemoteUI", targets: ["RemoteUI"]),
        .executable(name: "TCLRemote", targets: ["TCLRemote"]),
    ],
    targets: [
        // Core: TV protocols, discovery, models, persistence. No UI.
        .target(name: "TVKit"),
        // Menu bar app: SwiftUI presentation + app state.
        // Shared SwiftUI screens, app state and strings for the Mac and iOS/iPadOS apps.
        .target(name: "RemoteUI", dependencies: ["TVKit"], resources: [.process("Resources")]),
        // Mac menu bar shell. The iOS/iPadOS app lives in iOS/ (Xcode project from XcodeGen).
        .executableTarget(name: "TCLRemote", dependencies: ["RemoteUI", "TVKit"]),
        .testTarget(name: "TVKitTests", dependencies: ["TVKit"]),
    ],
    swiftLanguageModes: [.v5]
)
