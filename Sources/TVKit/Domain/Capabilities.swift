import Foundation

/// Live volume as reported by the TV.
public struct TVVolume: Equatable, Sendable {
    public var level: Int
    public var max: Int
    public var muted: Bool
    public init(level: Int, max: Int, muted: Bool) { self.level = level; self.max = max; self.muted = muted }
}

/// A remote that must pair with the TV before it can be used (Google / Android TV).
@MainActor
public protocol PairingCapable: AnyObject {
    func startPairing() async throws
    func finishPairing(code: String) async throws
    func cancelPairing()
}

/// A remote that pushes live TV state instead of being polled.
@MainActor
public protocol StateReporting: AnyObject {
    var onPower: ((Bool) -> Void)? { get set }
    var onVolume: ((TVVolume) -> Void)? { get set }
    var onDisconnect: (() -> Void)? { get set }
}
