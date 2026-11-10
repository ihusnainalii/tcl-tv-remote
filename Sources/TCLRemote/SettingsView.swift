import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label("General", systemImage: "gearshape") }
            DeviceSettings().tabItem { Label("TVs", systemImage: "tv") }
            AboutView().tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 480, height: 380)
    }
}

private struct GeneralSettings: View {
    @EnvironmentObject var s: Store
    @AppStorage("autoConnect") private var autoConnect = true
    @AppStorage("notify") private var notify = true
    @AppStorage("retrySeconds") private var retry = 10.0

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(get: { s.launchAtLogin }, set: { s.setLaunchAtLogin($0) }))
                Toggle("Connect to my TV automatically", isOn: $autoConnect)
                Text("Connects to your favorite TV, or the one you used last.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Connection") {
                Picker("When a TV goes offline, retry every", selection: $retry) {
                    Text("5 seconds").tag(5.0); Text("10 seconds").tag(10.0)
                    Text("30 seconds").tag(30.0); Text("1 minute").tag(60.0)
                }
            }
            Section("Notifications") {
                Toggle("Notify when a TV connects, disconnects or needs pairing", isOn: $notify)
            }
            Section("Keyboard (while the remote is open)") {
                LabeledContent("Navigate", value: "Arrow keys")
                LabeledContent("OK / Back", value: "Return / Esc")
                LabeledContent("Backspace", value: "Delete")
                LabeledContent("Play/Pause · Mute · Home", value: "Space · M · H")
                LabeledContent("Volume", value: "+ / −")
            }
        }
        .formStyle(.grouped)
    }
}

private struct DeviceSettings: View {
    @EnvironmentObject var s: Store
    @State private var confirmReset = false
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 0) {
            if s.known.isEmpty {
                ContentUnavailableView("No saved TVs", systemImage: "tv.slash",
                                       description: Text("TVs appear here after you connect to them."))
            } else {
                List {
                    ForEach(s.sortedKnown) { k in
                        HStack(spacing: 10) {
                            Button { s.toggleFavorite(k) } label: {
                                Image(systemName: k.favorite == true ? "star.fill" : "star")
                                    .foregroundStyle(k.favorite == true ? .yellow : .secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain).help("Favorite (auto-connects first)")
                            VStack(alignment: .leading, spacing: 2) {
                                TextField("Name", text: Binding(get: { k.name }, set: { s.rename(k, $0) }))
                                    .textFieldStyle(.plain).font(.body.weight(.medium))
                                Text("\(k.tv.kind.rawValue) · \(k.tv.host) · last used ")
                                    .font(.caption).foregroundStyle(.secondary)
                                + Text(k.lastUsed, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { s.forget(k) } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless).help("Forget this TV")
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            Divider()
            HStack {
                Button("Clear History…") { confirmClear = true }.disabled(s.known.count < 2)
                Spacer()
                Button("Reset Google TV Pairing…") { confirmReset = true }
            }
            .padding(12)
        }
        .confirmationDialog("Forget all TVs except the current one?", isPresented: $confirmClear) {
            Button("Clear History", role: .destructive) { s.clearHistory() }
        }
        .confirmationDialog("Reset pairing?", isPresented: $confirmReset) {
            Button("Reset Pairing", role: .destructive) { s.resetPairing() }
        } message: {
            Text("Deletes the pairing certificate from your Keychain. Every Google TV will show a new code to pair again.")
        }
    }
}

private struct AboutView: View {
    var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Theme.accent).frame(width: 72, height: 72)
                Image(systemName: "appletvremote.gen4.fill").font(.system(size: 32)).foregroundStyle(.white)
            }
            .shadow(color: .purple.opacity(0.35), radius: 12, y: 4)
            Text("TCL Remote").font(.title2.weight(.semibold))
            Text("Version \(version)").font(.callout).foregroundStyle(.secondary)
            Text("Controls TCL Google TV, Android TV and Roku TV over your local network.\nNo account, no cloud: everything stays on your Wi-Fi.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
