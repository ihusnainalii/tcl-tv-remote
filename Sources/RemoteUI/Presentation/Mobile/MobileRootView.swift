import SwiftUI
import TVKit

#if os(iOS)
/// iPhone and iPad: native tab bar (Remote, Apps, Keys, Settings), TV switching and pairing as sheets.
/// The Mac keeps its compact menu bar panel (`RootView(style: .panel)`).
struct MobileRootView: View {
    @EnvironmentObject var s: Store
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("mobileTab") private var tab = MobileTab.remote
    @AppStorage(OnboardingView.doneKey) private var onboarded = false

    /// iPad's Remote tab already holds apps and keys in its second column, so it only adds Settings.
    private var isWide: Bool { sizeClass == .regular }

    enum MobileTab: String { case remote, apps, keys, settings }

    var body: some View {
        TabView(selection: $tab) {
            Tab(L10n.Mobile.Tab.remote, systemImage: "appletvremote.gen4.fill", value: MobileTab.remote) {
                MobileRemoteTab()
            }
            if !isWide {
                Tab(L10n.Mobile.Tab.apps, systemImage: "square.grid.2x2.fill", value: MobileTab.apps) {
                    MobileScreen(title: L10n.Mobile.Tab.apps) {
                        if s.tv == nil { NoTVView() } else {
                            AppsGrid(iconSize: 64, columns: 4, maxHeight: .infinity)
                        }
                    }
                }
                Tab(L10n.Mobile.Tab.keys, systemImage: "keyboard.fill", value: MobileTab.keys) {
                    MobileScreen(title: L10n.Mobile.Tab.keys) { MobileKeysView() }
                }
            }
            Tab(L10n.Mobile.Tab.settings, systemImage: "gearshape.fill", value: MobileTab.settings) {
                MobileScreen(title: L10n.Mobile.Tab.settings) { SettingsView() }
            }
        }
        .tint(AccentStyle.current.colors.0)
        .onAppear {
            if isWide, tab == .apps || tab == .keys { tab = .remote }
            if onboarded { SystemNotifications.requestAccess() } // no-op once answered
        }
        .onChange(of: isWide) { if isWide, tab == .apps || tab == .keys { tab = .remote } }
        // TV list and pairing float above whichever tab is open.
        .sheet(isPresented: Binding(get: { s.screen == .devices && s.tv != nil },
                                    set: { if !$0, s.screen == .devices { s.closeSettings() } })) {
            NavigationStack {
                ScrollView { DevicesView().padding(20) }
                    .navigationTitle(L10n.Mobile.tvs)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.Common.done) { s.closeSettings() } } }
            }
            .presentationDetents([.medium, .large])
            .environmentObject(s)
        }
        .sheet(isPresented: Binding(get: { s.screen == .pairing }, set: { if !$0, s.screen == .pairing { s.cancelPairing() } })) {
            PairingView().padding(24).presentationDetents([.medium]).environmentObject(s)
        }
        .overlay(alignment: .bottom) { Toast().padding(.bottom, 90) }
        .fullScreenCover(isPresented: Binding(get: { !onboarded }, set: { if !$0 { onboarded = true } })) {
            OnboardingView { onboarded = true; SystemNotifications.requestAccess() }
        }
        .themed()
    }
}

/// A tab's page: large title, scrolling content, TV switcher in the toolbar.
struct MobileScreen<Content: View>: View {
    @EnvironmentObject var s: Store
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, 20).padding(.bottom, 24)
                    .frame(maxWidth: 700).frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.clear)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { TVSwitcher() } }
        }
    }
}

/// Status dot + current TV; menu to switch TVs or find new ones.
struct TVSwitcher: View {
    @EnvironmentObject var s: Store

    var body: some View {
        Menu {
            ForEach(s.sortedKnown) { k in
                Button { s.select(k.tv) } label: {
                    Label(k.name, systemImage: s.tv?.id == k.id ? "checkmark" : (k.favorite == true ? "star" : "tv"))
                }
            }
            Divider()
            Button { s.showDevices() } label: { Label(L10n.Mobile.findTVs, systemImage: "dot.radiowaves.left.and.right") }
        } label: {
            HStack(spacing: 6) {
                Circle().fill(statusColor).frame(width: 8, height: 8)
                Text(s.tv.map { _ in s.displayName } ?? L10n.Mobile.tvs).font(.subheadline.weight(.semibold)).lineLimit(1)
                Image(systemName: "chevron.down").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
        }
        .accessibilityLabel(L10n.Mobile.tvs)
    }

    var statusColor: Color {
        switch s.link {
        case .connected: .green
        case .connecting: .orange
        case .needsPairing: .yellow
        case .failed: .red
        case .idle: .gray
        }
    }
}

/// Shown on tabs that need a TV when none is selected yet. Empty state: one icon, one title, one
/// message, centred, with a primary Scan button and Add by IP. Once TVs are found it shows the list.
struct NoTVView: View {
    @EnvironmentObject var s: Store
    @State private var addingIP = false

    var body: some View {
        if s.known.isEmpty && s.newTVs.isEmpty {
            emptyState
                .containerRelativeFrame(.vertical) // centred in the scroll area
                .sheet(isPresented: $addingIP) { AddByIPSheet().environmentObject(s).presentationDetents([.height(300)]) }
        } else {
            DevicesView().frame(maxWidth: 560).frame(maxWidth: .infinity).padding(.top, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                if s.scanning {
                    Radar().frame(width: 120, height: 120).transition(.opacity)
                } else {
                    Image(systemName: "tv.slash").font(.system(size: 52, weight: .light)).foregroundStyle(.secondary)
                        .frame(width: 120, height: 120).transition(.opacity)
                }
            }
            .animation(.smooth, value: s.scanning)

            VStack(spacing: 8) {
                Text(s.scanning ? L10n.Mobile.Empty.searching : L10n.Devices.noTVs).font(.title2.weight(.bold))
                Text(s.scanning ? L10n.Mobile.Empty.searchingHint : L10n.Devices.sameWifi)
                    .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentTransition(.opacity)

            VStack(spacing: 12) {
                Button { s.scan() } label: {
                    HStack(spacing: 8) {
                        if s.scanning { ProgressView().tint(.white) } else { Image(systemName: "dot.radiowaves.left.and.right") }
                        Text(s.scanning ? L10n.Devices.scanning : L10n.Mobile.scanForTVs)
                    }
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Theme.accent, in: Capsule())
                }
                .buttonStyle(PressStyle(hoverScale: 1, pressScale: 0.97))
                .disabled(s.scanning)

                Button { addingIP = true } label: {
                    Label(L10n.Devices.addByIP, systemImage: "plus").font(.headline)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(.fill.tertiary, in: Capsule())
                }
                .buttonStyle(PressStyle(hoverScale: 1, pressScale: 0.97))
            }
            .frame(maxWidth: 360)
            .padding(.top, 10)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
    }
}

/// Connect to a TV by its IP address.
struct AddByIPSheet: View {
    @EnvironmentObject var s: Store
    @Environment(\.dismiss) private var dismiss
    @State private var ip = ""
    @State private var kind: TV.Kind = .androidTV
    @FocusState private var focused: Bool

    private var trimmed: String { ip.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Devices.addByIP).font(.title3.weight(.bold))
            TextField(L10n.Devices.ipPlaceholder, text: $ip)
                .keyboardType(.numbersAndPunctuation).textInputAutocapitalization(.never).autocorrectionDisabled()
                .focused($focused)
                .padding(14).background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Picker("", selection: $kind) {
                ForEach(TV.Kind.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented).labelsHidden()
            Button {
                s.select(TV(name: L10n.Devices.manualName(trimmed), host: trimmed, kind: kind))
                dismiss()
            } label: {
                Text(L10n.Devices.connect).font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Theme.accent, in: Capsule())
                    .opacity(trimmed.isEmpty ? 0.5 : 1)
            }
            .buttonStyle(PressStyle(hoverScale: 1, pressScale: 0.97))
            .disabled(trimmed.isEmpty)
        }
        .padding(24)
        .onAppear { focused = true }
    }
}

/// Keys tab: typing, number pad and the extra keys.
struct MobileKeysView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            section(L10n.Remote.Tab.type) { TypePad(large: true) }
            section(L10n.Remote.Tab.keypad) { KeypadGrid(height: 56) }
            section(L10n.Remote.Tab.more) { MoreGrid(height: 64) }
        }
    }

    func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }
}

struct Toast: View {
    @EnvironmentObject var s: Store

    var body: some View {
        if let t = s.toast {
            Text(t)
                .font(.callout.weight(.medium))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
#endif
