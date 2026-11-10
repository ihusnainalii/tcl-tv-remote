import AppKit
import Combine
import SwiftUI
import TVKit

@main
struct TCLRemoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() } // settings live inside the panel
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
    private var appearanceObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: AppearanceMode.changed, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.popover.appearance = AppearanceMode.current.nsAppearance }
        }
        AppearanceMode.apply()
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
            self?.statusItem.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: L10n.App.name)
        }

        // Testing and screenshot aid: open the panel at launch, optionally on a given screen.
        let args = CommandLine.arguments
        if args.contains("--settings") { store.showSettings() }
        if args.contains("--devices") { store.showDevices() }
        if !Set(args).isDisjoint(with: ["--open", "--settings", "--devices"]) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.toggle() }
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
