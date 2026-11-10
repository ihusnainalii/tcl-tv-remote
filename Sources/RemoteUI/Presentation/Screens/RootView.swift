import SwiftUI
import TVKit

// MARK: - Root

/// The whole remote UI. `.panel` is the Mac menu bar popover; `.fullScreen` is iPhone and iPad.
public struct RootView: View {
    public enum Style { case panel, fullScreen }

    @EnvironmentObject var s: Store
    let style: Style

    public init(style: Style = .panel) { self.style = style }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func slide(_ edge: Edge) -> AnyTransition { reduceMotion ? .opacity : .push(from: edge) }

    public var body: some View {
        switch style {
        case .panel:
            content
                .frame(width: 300)
                .fixedSize(horizontal: false, vertical: true) // popover sizes itself to this ideal height
                .themed()
        case .fullScreen:
            ScrollView {
                content.frame(maxWidth: 440).frame(maxWidth: .infinity) // centered column on iPad
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(.background.secondary)
            .themed()
        }
    }

    private var content: some View {
        VStack(spacing: 14) {
            Header()
            ZStack {
                switch s.screen {
                case .devices: DevicesView().transition(slide(.leading))
                case .pairing: PairingView().transition(slide(.trailing))
                case .remote: RemoteView().transition(slide(.trailing))
                case .settings: SettingsView().transition(slide(.trailing))
                }
            }
            .frame(maxWidth: .infinity)
            // Clip slide transitions, but leave room for button glows near the edges.
            .clipShape(Rectangle().inset(by: -14))
        }
        .padding(16)
        .overlay(alignment: .bottom) {
            if let t = s.toast {
                Text(t)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
            }
        }
    }
}

struct Header: View {
    @EnvironmentObject var s: Store

    var status: (String, Color) {
        switch s.link {
        case .idle: (L10n.Status.notConnected, .secondary)
        case .connecting: (L10n.Status.connecting, .orange)
        case .connected: (s.tvOn == false ? L10n.Status.standby : L10n.Status.connected, .green)
        case .needsPairing: (L10n.Status.pairingRequired, .yellow)
        case .failed: (L10n.Status.offline, .red)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(Theme.accent).frame(width: 32, height: 32)
                Image(systemName: "tv").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(s.displayName).font(.headline).lineLimit(1).contentTransition(.opacity)
                HStack(spacing: 5) {
                    StatusDot(color: status.1, pulsing: s.link == .connecting || s.link == .connected)
                    Text(status.0).font(.caption).foregroundStyle(.secondary).contentTransition(.opacity)
                }
            }
            Spacer()
            if s.screen == .settings {
                Button { s.closeSettings() } label: { icon("xmark") }.buttonStyle(PressStyle()).help(L10n.Header.closeSettings)
            } else if s.screen == .remote {
                Button { s.showDevices() } label: { icon("list.bullet") }.buttonStyle(PressStyle()).help(L10n.Header.tvs)
            } else if s.screen == .devices, s.tv != nil {
                Button { s.select(s.tv!) } label: { icon("appletvremote.gen4") }.buttonStyle(PressStyle()).help(L10n.Header.remote)
            }
            Menu {
                #if os(macOS)
                Toggle(L10n.Menu.launchAtLogin, isOn: Binding(get: { s.launchAtLogin }, set: { s.setLaunchAtLogin($0) }))
                #endif
                Button(L10n.Menu.findTVs) { s.showDevices() }
                Button(L10n.Menu.settings) { s.showSettings() }.keyboardShortcut(",")
                #if os(macOS)
                Divider()
                Button(L10n.Menu.quit) { NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
                #endif
            } label: { icon("ellipsis") }
            .menuStyle(.button).buttonStyle(PressStyle()).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel(L10n.Header.moreOptions)
        }
        .animation(.smooth, value: s.link)
    }

    func icon(_ name: String) -> some View {
        Image(systemName: name).accessibilityHidden(true).font(.system(size: 12, weight: .semibold))
            .frame(width: 28, height: 28).pill(Circle())
    }
}

struct StatusDot: View {
    let color: Color
    let pulsing: Bool
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle().fill(color).frame(width: 7, height: 7)
            .background(
                Circle().stroke(color, lineWidth: 1.5)
                    .scaleEffect(on ? 2.6 : 1).opacity(on ? 0 : 0.7)
                    .opacity(pulsing && !reduceMotion ? 1 : 0)
            )
            .onAppear { withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { on = true } }
    }
}
