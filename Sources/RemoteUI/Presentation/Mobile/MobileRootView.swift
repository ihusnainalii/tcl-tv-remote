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
        .onAppear { if isWide, tab == .apps || tab == .keys { tab = .remote } }
        .onChange(of: isWide) { if isWide, tab == .apps || tab == .keys { tab = .remote } }
        // TV list and pairing float above whichever tab is open.
        .sheet(isPresented: Binding(get: { s.screen == .devices && s.tv != nil },
                                    set: { if !$0, s.screen == .devices { s.closeSettings() } })) {
            NavigationStack {
                ScrollView { DevicesView().padding(20) }
                    .navigationTitle(L10n.Mobile.tvs)
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
            OnboardingView { onboarded = true }
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

/// Shown on tabs that need a TV when none is selected yet.
struct NoTVView: View {
    @EnvironmentObject var s: Store

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(L10n.Mobile.Welcome.title).font(.title2.weight(.bold))
                Text(L10n.Mobile.Welcome.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            DevicesView()
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
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
