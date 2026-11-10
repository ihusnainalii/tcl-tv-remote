import AppKit
import Combine
import SwiftUI
import TVKit

@main
struct TCLRemoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { SettingsView().environmentObject(appDelegate.store) }
    }
}

/// Status bar item + popover. Unlike MenuBarExtra, a popover stays anchored to the icon and
/// resizes itself (animated) to the SwiftUI content's ideal size.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let store = Store()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var linkObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let host = NSHostingController(rootView: RootView().environmentObject(store))
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.action = #selector(toggle)
        statusItem.button?.target = self

        linkObserver = store.$link.sink { [weak self] link in
            let name = link == .connected ? "appletvremote.gen4.fill" : "appletvremote.gen4"
            self?.statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "TCL Remote")
        }
    }

    @objc private func toggle() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate() // so arrow keys reach the remote right away
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.highlight(true)
        }
    }

    func popoverDidClose(_ notification: Notification) { statusItem.button?.highlight(false) }
}
