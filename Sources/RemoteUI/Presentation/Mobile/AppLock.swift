import LocalAuthentication
import SwiftUI

#if os(iOS)
/// Optional Face ID lock (Settings > General). Locks on launch and whenever the app returns to the
/// foreground; unlocks with Face ID / Touch ID, falling back to the device passcode.
struct AppLockModifier: ViewModifier {
    @AppStorage(AppLockModifier.key) private var enabled = false
    @Environment(\.scenePhase) private var phase
    @State private var locked = true
    @State private var failed = false

    static let key = "requireFaceID"

    func body(content: Content) -> some View {
        content
            .overlay {
                if enabled && locked {
                    LockScreen(failed: failed, unlock: unlock).transition(.opacity)
                }
            }
            .animation(.smooth, value: locked)
            .onChange(of: phase) { _, p in
                if p == .background { locked = true }
                if p == .active, enabled, locked { unlock() }
            }
            .onAppear { if enabled { unlock() } }
    }

    private func unlock() {
        let context = LAContext()
        var error: NSError?
        // No biometrics or passcode set up: nothing to protect with, so don't lock the user out.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { locked = false; return }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L10n.Lock.reason) { ok, _ in
            Task { @MainActor in
                locked = !ok
                failed = !ok
            }
        }
    }
}

private struct LockScreen: View {
    let failed: Bool
    let unlock: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "faceid").font(.system(size: 56, weight: .light)).foregroundStyle(Theme.accent)
            Text(L10n.Lock.title).font(.title2.weight(.bold))
            Text(failed ? L10n.Lock.failed : L10n.Lock.subtitle).font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: unlock) {
                Text(L10n.Lock.unlock).font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: 320).frame(height: 54)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(PressStyle(hoverScale: 1, pressScale: 0.97))
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
#endif
