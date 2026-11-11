import RemoteUI
import SwiftUI

/// iPhone and iPad shell: the same remote as the Mac menu bar app, full screen.
@main
struct TCLRemoteiOSApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView(style: .fullScreen).environmentObject(store)
                .onAppear { store.startWatchRelay() }
                .onOpenURL { store.handle(url: $0) }
        }
    }
}
