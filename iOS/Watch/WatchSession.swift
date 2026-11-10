import Foundation
import TVKit
import WatchConnectivity
import WatchKit

/// The watch's view of the TV, kept in sync with the iPhone app over WatchConnectivity.
/// Google TV needs sockets watchOS doesn't allow, so keys go through the iPhone; Roku is plain HTTP,
/// so the watch can control it directly when the iPhone isn't reachable.
@MainActor
final class WatchSession: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var name = "TCL Remote"
    @Published private(set) var link = "idle"
    @Published private(set) var volume: Int?
    @Published private(set) var apps: [TVApp] = []
    @Published private(set) var message: String?
    private var rokuHost: String?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    var connected: Bool { link == "connected" }

    func press(_ key: Key) {
        WKInterfaceDevice.current().play(.click)
        send(["key": key.rawValue]) { [weak self] in
            guard let host = self?.rokuHost else { throw TVError.timeout }
            try await RokuRemote(host: host).press(key)
        }
    }

    func launch(_ app: TVApp) {
        WKInterfaceDevice.current().play(.success)
        send(["launch": app.id, "name": app.name]) { [weak self] in
            guard let host = self?.rokuHost else { throw TVError.timeout }
            try await RokuRemote(host: host).launch(app)
        }
    }

    /// Through the iPhone when it's reachable; otherwise directly for Roku; otherwise explain why not.
    private func send(_ msg: [String: Any], direct: @escaping () async throws -> Void) {
        let session = WCSession.default
        if session.activationState == .activated, session.isReachable {
            message = nil
            session.sendMessage(msg, replyHandler: { reply in
                Task { @MainActor in self.apply(reply) }
            }, errorHandler: { _ in
                Task { @MainActor in self.message = "Couldn't reach your iPhone. Open TCL Remote on it and try again." }
            })
        } else {
            Task {
                do { try await direct(); message = nil } catch {
                    message = rokuHost == nil
                        ? "Keep your iPhone nearby. Google TV is controlled through the iPhone app."
                        : "Can't reach the TV. Make sure it's on and on the same Wi-Fi."
                    WKInterfaceDevice.current().play(.failure)
                }
            }
        }
    }

    private func apply(_ state: [String: Any]) {
        name = state["name"] as? String ?? "TCL Remote"
        link = state["link"] as? String ?? "idle"
        volume = state["volume"] as? Int
        rokuHost = (state["kind"] as? String) == TV.Kind.roku.rawValue ? state["host"] as? String : nil
        apps = (state["apps"] as? [[String: String]] ?? []).compactMap { d in
            guard let id = d["id"], let name = d["name"] else { return nil }
            return TVApp(id: id, name: name)
        }
    }

    // MARK: WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.apply(context) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.apply(context) }
    }
}
