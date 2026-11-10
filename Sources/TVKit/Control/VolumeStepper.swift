import Foundation

/// Android TV Remote v2 has no "set volume" command, so a target level is reached with single
/// volume up/down presses. Retargeting while a walk is in flight just changes where it stops.
@MainActor
public final class VolumeStepper {
    public private(set) var isActive = false
    public private(set) var target: Int?
    private var sent = 0
    private let stepDelay: Duration
    private let press: (Key) async throws -> Void

    public init(stepDelay: Duration = .milliseconds(35), press: @escaping (Key) async throws -> Void) {
        self.stepDelay = stepDelay
        self.press = press
    }

    public func move(from current: Int, to newTarget: Int) {
        if !isActive { sent = current }
        target = newTarget
        guard !isActive else { return }
        isActive = true
        Task {
            while let t = target, t != sent {
                let up = t > sent
                try? await press(up ? .volUp : .volDown)
                sent += up ? 1 : -1
                try? await Task.sleep(for: stepDelay)
            }
            isActive = false
            target = nil
        }
    }
}
