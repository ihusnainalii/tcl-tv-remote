import SwiftUI
import TVKit

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label("General", systemImage: "gearshape") }
            AppearanceSettings().tabItem { Label("Appearance", systemImage: "paintpalette") }
            DeviceSettings().tabItem { Label("TVs", systemImage: "tv") }
            AboutView().tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 480, height: 420)
        .themed()
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
    @State private var update: UpdateCheck.Result?
    @State private var checking = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Theme.accent).frame(width: 72, height: 72)
                Image(systemName: "appletvremote.gen4.fill").font(.system(size: 32)).foregroundStyle(.white)
            }
            .shadow(color: Theme.glow.opacity(0.35), radius: 12, y: 4)
            Text("TCL Remote").font(.title2.weight(.semibold))
            Text("Version \(version)").font(.callout).foregroundStyle(.secondary)
            Text("Controls TCL Google TV, Android TV and Roku TV over your local network.\nNo account, no cloud: everything stays on your Wi-Fi.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)

            Group {
                switch update {
                case .available(let v, let url)?:
                    HStack {
                        Text("Version \(v) is available").font(.callout.weight(.medium))
                        Button("Download") { NSWorkspace.shared.open(url) }.buttonStyle(.borderedProminent)
                    }
                case .upToDate?: Label("You're up to date", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                case .failed(let msg)?: Text(msg).font(.caption).foregroundStyle(.secondary)
                case nil:
                    Button(checking ? "Checking…" : "Check for Updates") {
                        checking = true
                        Task { update = await UpdateCheck.run(current: version); checking = false }
                    }
                    .disabled(checking)
                }
            }
            .padding(.top, 6)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.spring, value: update)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppearanceSettings: View {
    @AppStorage(AccentStyle.key) private var style = AccentStyle.violet.rawValue
    @AppStorage(AccentStyle.customKey) private var customHex = ""
    @AppStorage(AppearanceMode.key) private var mode = AppearanceMode.system.rawValue

    private var customColor: Binding<Color> {
        Binding(get: { Color(nsColor: AccentStyle.customColor) },
                set: { customHex = NSColor($0).hex; style = AccentStyle.custom.rawValue })
    }

    var body: some View {
        Form {
            Section("Color theme") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(AccentStyle.allCases) { s in swatch(s) }
                }
                .padding(.vertical, 6)
                ColorPicker("Custom color", selection: customColor, supportsOpacity: false)
            }
            Section("Appearance") {
                Picker("Mode", selection: $mode) {
                    ForEach(AppearanceMode.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .onChange(of: mode) { AppearanceMode.apply() }
            }
            Section("Preview") { ThemePreview().frame(maxWidth: .infinity).padding(.vertical, 8) }
        }
        .formStyle(.grouped)
    }

    func swatch(_ s: AccentStyle) -> some View {
        let selected = style == s.rawValue
        let c = s.colors
        return Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { style = s.rawValue } } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(LinearGradient(colors: [c.0, c.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                    .overlay {
                        if selected { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white) }
                    }
                    .padding(3)
                    .overlay(Circle().stroke(selected ? c.0 : .clear, lineWidth: 2))
                    .scaleEffect(selected ? 1.08 : 1)
                Text(s.title).font(.caption).foregroundStyle(selected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(s.title) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// A small slice of the remote so the theme can be judged before closing Settings.
private struct ThemePreview: View {
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "power").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                .frame(width: 34, height: 34).background(Theme.power, in: Circle())
            ZStack {
                Circle().fill(Theme.fill).frame(width: 96, height: 96)
                Text("OK").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(Theme.accent, in: Circle())
                    .shadow(color: Theme.glow.opacity(0.45), radius: 8, y: 2)
            }
            HStack(spacing: 2) {
                Text("Apps").font(.caption.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 5).background(Theme.accent, in: Capsule())
                Text("Keypad").font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(.horizontal, 8)
            }
            .padding(3).pill(Capsule())
        }
    }
}
