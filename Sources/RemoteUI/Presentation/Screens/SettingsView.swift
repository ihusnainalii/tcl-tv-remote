import SwiftUI
import TVKit

/// Settings shown inside the menu bar panel, as its own screen.
struct SettingsView: View {
    enum Tab: String, CaseIterable {
        case general = "General", look = "Look", tvs = "TVs", about = "About" // raw values are stored; don't localize

        var title: String {
            switch self {
            case .general: L10n.Settings.Tab.general
            case .look: L10n.Settings.Tab.look
            case .tvs: L10n.Settings.Tab.tvs
            case .about: L10n.Settings.Tab.about
            }
        }
    }

    // AppStorage survives the view rebuild that a theme change triggers.
    @AppStorage("settingsTab") private var tab = Tab.general.rawValue
    @Namespace private var ns

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { tab = t.rawValue } } label: {
                        Text(t.title).font(.caption.weight(.semibold))
                            .foregroundStyle(tab == t.rawValue ? .white : .secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                            .background {
                                if tab == t.rawValue { Capsule().fill(Theme.accent).matchedGeometryEffect(id: "settingsTab", in: ns) }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3).pill(Capsule())

            FitScroll(maxHeight: 470) {
                Group {
                    switch Tab(rawValue: tab) ?? .general {
                    case .general: GeneralSettings()
                    case .look: LookSettings()
                    case .tvs: TVSettings()
                    case .about: AboutSettings()
                    }
                }
                .padding(.bottom, 2)
                .transition(.blurReplace)
                .id(tab)
            }
        }
    }
}

// MARK: - Building blocks

private struct Card<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(spacing: 0) { content }
                .padding(.horizontal, 10).padding(.vertical, 2)
                .pill(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(title).font(.callout)
            Spacer()
            Toggle(title, isOn: $isOn).labelsHidden().toggleStyle(.switch).controlSize(.mini)
        }
        .frame(minHeight: 22)
        .padding(.vertical, 7)
    }
}

private struct InfoRow: View {
    let title: String, value: String
    var body: some View {
        HStack {
            Text(title).font(.callout)
            Spacer()
            Text(value).font(.callout.monospaced()).foregroundStyle(.secondary)
        }
        .frame(minHeight: 22)
        .padding(.vertical, 7)
    }
}

// MARK: - Tabs

private struct GeneralSettings: View {
    @EnvironmentObject var s: Store
    @AppStorage("autoConnect") private var autoConnect = true
    @AppStorage("notify") private var notify = true
    @AppStorage("retrySeconds") private var retry = 10.0

    var body: some View {
        VStack(spacing: 14) {
            Card(title: L10n.Settings.startup) {
                if PlatformInfo.isMac {
                    ToggleRow(title: L10n.Settings.launchAtLogin, isOn: Binding(get: { s.launchAtLogin }, set: { s.setLaunchAtLogin($0) }))
                    Divider()
                }
                ToggleRow(title: L10n.Settings.connectAutomatically, isOn: $autoConnect)
            }
            Card(title: L10n.Settings.connection) {
                HStack {
                    Text(L10n.Settings.retryEvery).font(.callout)
                    Spacer()
                    Picker("", selection: $retry) {
                        Text("5 s").tag(5.0); Text("10 s").tag(10.0); Text("30 s").tag(30.0); Text("1 min").tag(60.0)
                    }
                    .labelsHidden().fixedSize()
                }
                .frame(minHeight: 22)
                .padding(.vertical, 7)
                Divider()
                ToggleRow(title: L10n.Settings.notifications, isOn: $notify)
            }
            Card(title: L10n.Settings.keyboard) {
                InfoRow(title: L10n.Settings.Keyboard.navigate, value: "← ↑ → ↓")
                Divider()
                InfoRow(title: L10n.Settings.Keyboard.okBack, value: "⏎ · esc")
                Divider()
                InfoRow(title: L10n.Settings.Keyboard.backspace, value: "⌫")
                Divider()
                InfoRow(title: L10n.Settings.Keyboard.playMuteHome, value: "␣ · M · H")
                Divider()
                InfoRow(title: L10n.Settings.Keyboard.volume, value: "+ / −")
            }
        }
    }
}

private struct LookSettings: View {
    @AppStorage(AccentStyle.key) private var style = AccentStyle.violet.rawValue
    @AppStorage(AccentStyle.customKey) private var customHex = ""
    @AppStorage(AppearanceMode.key) private var mode = AppearanceMode.system.rawValue

    private var customColor: Binding<Color> {
        Binding(get: { Color(platform: AccentStyle.customColor) },
                set: { customHex = PlatformColor($0).hex; style = AccentStyle.custom.rawValue })
    }

    var body: some View {
        VStack(spacing: 14) {
            Card(title: L10n.Settings.colorTheme) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(AccentStyle.allCases) { swatch($0) }
                }
                .padding(.vertical, 10)
                Divider()
                HStack {
                    Text(L10n.Settings.customColor).font(.callout)
                    Spacer()
                    ColorPicker(L10n.Settings.customColor, selection: customColor, supportsOpacity: false).labelsHidden()
                }
                .frame(minHeight: 22)
                .padding(.vertical, 7)
            }
            Card(title: L10n.Settings.appearance) {
                Picker("", selection: $mode) {
                    ForEach(AppearanceMode.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented).labelsHidden()
                .padding(.vertical, 8)
                .onChange(of: mode) { AppearanceMode.apply() }
            }
        }
    }

    func swatch(_ s: AccentStyle) -> some View {
        let selected = style == s.rawValue
        let c = s.colors
        return Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { style = s.rawValue } } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(LinearGradient(colors: [c.0, c.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 30, height: 30)
                    .overlay {
                        if selected { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white) }
                    }
                    .padding(2)
                    .overlay(Circle().stroke(selected ? c.0 : .clear, lineWidth: 2))
                    .scaleEffect(selected ? 1.08 : 1)
                Text(s.title).font(.system(size: 9, weight: .medium)).foregroundStyle(selected ? .primary : .secondary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(s.title) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct TVSettings: View {
    @EnvironmentObject var s: Store
    @State private var confirmReset = false
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 14) {
            Card(title: L10n.Settings.savedTVs) {
                if s.known.isEmpty {
                    Text(L10n.Settings.SavedTVs.empty).font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                ForEach(Array(s.sortedKnown.enumerated()), id: \.element.id) { i, k in
                    if i > 0 { Divider() }
                    HStack(spacing: 8) {
                        Button { s.toggleFavorite(k) } label: {
                            Image(systemName: k.favorite == true ? "star.fill" : "star")
                                .foregroundStyle(k.favorite == true ? .yellow : .secondary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain).help(L10n.Settings.favoriteHelp)
                        VStack(alignment: .leading, spacing: 1) {
                            TextField(L10n.Common.name, text: Binding(get: { k.name }, set: { s.rename(k, $0) }))
                                .textFieldStyle(.plain).font(.callout.weight(.medium))
                            Text("\(k.tv.kind.rawValue) · \(k.tv.host)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) { s.forget(k) } label: { Image(systemName: "trash").font(.caption) }
                            .buttonStyle(.plain).foregroundStyle(.secondary).help(L10n.Settings.forgetHelp)
                    }
                    .padding(.vertical, 7)
                }
            }
            HStack {
                Button(L10n.Settings.clearHistory) { confirmClear = true }.disabled(s.known.count < 2)
                Spacer()
                Button(L10n.Settings.resetPairing) { confirmReset = true }
            }
            .controlSize(.small)
        }
        .confirmationDialog(L10n.Settings.confirmClear, isPresented: $confirmClear) {
            Button(L10n.Settings.clearHistory, role: .destructive) { s.clearHistory() }
        }
        .confirmationDialog(L10n.Settings.confirmReset, isPresented: $confirmReset) {
            Button(L10n.Settings.resetPairing, role: .destructive) { s.resetPairing() }
        } message: {
            Text(L10n.Settings.resetMessage)
        }
    }
}

private struct AboutSettings: View {
    @Environment(\.openURL) private var openURL
    var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }
    @State private var update: UpdateCheck.Result?
    @State private var checking = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Theme.accent).frame(width: 60, height: 60)
                Image(systemName: "appletvremote.gen4.fill").font(.system(size: 26)).foregroundStyle(.white)
            }
            .shadow(color: Theme.glow.opacity(0.35), radius: 10, y: 4)
            .padding(.top, 8)
            Text(L10n.App.name).font(.headline)
            Text(L10n.About.version(version)).font(.caption).foregroundStyle(.secondary)
            Text(L10n.About.description)
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Mac builds update from GitHub releases; iOS updates come from the App Store.
            if PlatformInfo.isMac { updateCheck }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var updateCheck: some View {
            Group {
                switch update {
                case .available(let v, let url)?:
                    VStack(spacing: 6) {
                        Text(L10n.About.updateAvailable(v)).font(.callout.weight(.medium))
                        Button(L10n.About.download) { openURL(url) }.buttonStyle(.borderedProminent)
                    }
                case .upToDate?: Label(L10n.About.upToDate, systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                case .failed(let msg)?: Text(msg).font(.caption).foregroundStyle(.secondary)
                case nil:
                    Button(checking ? L10n.About.checking : L10n.About.checkForUpdates) {
                        checking = true
                        Task { update = await UpdateCheck.run(current: version); checking = false }
                    }
                    .disabled(checking)
                }
            }
            .padding(.top, 4)
            .animation(.spring, value: update)
    }
}
