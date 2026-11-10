import AppKit
import Network

/// Calls back when it's a good moment to reconnect: the Mac (re)joined a network or woke from sleep.
@MainActor
final class ConnectivityMonitor {
    private let path = NWPathMonitor()
    private var wakeObserver: NSObjectProtocol?

    init(onOpportunity: @escaping @MainActor () -> Void) {
        path.pathUpdateHandler = { p in
            guard p.status == .satisfied else { return }
            Task { @MainActor in onOpportunity() }
        }
        path.start(queue: .main)

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2)) // let Wi-Fi come back first
                onOpportunity()
            }
        }
    }

    deinit {
        path.cancel()
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
}
