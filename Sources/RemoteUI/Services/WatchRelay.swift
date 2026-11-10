#if os(iOS)
import Combine
import TVKit
import WatchConnectivity

/// Bridges the Apple Watch app to this iPhone's TV connection. watchOS doesn't allow the TLS sockets
/// Google TV needs, so the watch sends keys and app launches here and gets back the current TV,
/// connection status, volume and apps.
@MainActor
final class WatchRelay: NSObject, WCSessionDelegate {
    private weak var store: Store?
    private var changes: AnyCancellable?

    init(store: Store) {
        self.store = store
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        changes = store.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.push() }
    }

    /// What the watch shows. Plain property-list types only.
    var state: [String: Any] {
        guard let s = store else { return [:] }
        var out: [String: Any] = ["link": WatchRelay.linkName(s.link), "name": s.displayName]
        if let tv = s.tv { out["kind"] = tv.kind.rawValue; out["host"] = tv.host }
        if let v = s.volume { out["volume"] = v.level; out["volumeMax"] = v.max; out["muted"] = v.muted }
        out["apps"] = s.displayedApps.prefix(12).map { ["id": $0.id, "name": $0.name] }
        return out
    }

    private func push() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        try? session.updateApplicationContext(state)
    }

    private func handle(_ message: [String: Any]) {
        guard let s = store else { return }
        if let raw = message["key"] as? String, let key = Key(rawValue: raw) { s.press(key) }
        if let id = message["launch"] as? String, let name = message["name"] as? String { s.launch(TVApp(id: id, name: name)) }
    }

    static func linkName(_ link: Store.Link) -> String {
        switch link {
        case .idle: "idle"
        case .connecting: "connecting"
        case .connected: "connected"
        case .needsPairing: "pairing"
        case .failed: "offline"
        }
    }

    // MARK: WCSessionDelegate (called off the main actor)

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.push() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handle(message)
            replyHandler(self.state)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.handle(message) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
#endif
