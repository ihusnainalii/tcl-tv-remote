import SwiftUI
import TVKit

@main
struct TCLRemoteApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        MenuBarExtra {
            RootView().environmentObject(store)
        } label: {
            Image(systemName: store.link == .connected ? "appletvremote.gen4.fill" : "appletvremote.gen4")
        }
        .menuBarExtraStyle(.window)

        Settings { SettingsView().environmentObject(store) }
    }
}
