import Network
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Calls back when it's a good moment to reconnect: the device (re)joined a network, the Mac woke from
/// sleep, or the iOS app came back to the foreground.
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

        #if os(macOS)
        let center = NSWorkspace.shared.notificationCenter, event = NSWorkspace.didWakeNotification
        #else
        let center = NotificationCenter.default, event = UIApplication.willEnterForegroundNotification
        #endif
        wakeObserver = center.addObserver(forName: event, object: nil, queue: .main) { _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2)) // let Wi-Fi come back first
                onOpportunity()
            }
        }
    }

    deinit {
        path.cancel()
        #if os(macOS)
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
        #else
        if let wakeObserver { NotificationCenter.default.removeObserver(wakeObserver) }
        #endif
    }
}
