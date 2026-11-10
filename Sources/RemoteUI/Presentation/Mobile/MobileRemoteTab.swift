import SwiftUI
import TVKit

#if os(iOS)
/// The Remote tab. Sized from the screen instead of scrolling, so the controls fill the space:
/// control surface (D-pad or touchpad) on top, utility row, volume/media cluster, app shortcuts.
/// On iPad, a second column holds apps and the keyboard so neither side is left empty.
struct MobileRemoteTab: View {
    @EnvironmentObject var s: Store
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("controlMode") private var mode = ControlMode.dpad

    enum ControlMode: String, CaseIterable { case dpad, touchpad }

    var body: some View {
        NavigationStack {
            Group {
                if s.tv == nil {
                    ScrollView { NoTVView().padding(.horizontal, 20) }
                } else {
                    GeometryReader { geo in
                        if sizeClass == .regular {
                            HStack(alignment: .top, spacing: 36) {
                                RemoteControls(mode: $mode, size: geo.size.height, width: min(460, geo.size.width * 0.46))
                                    .frame(width: min(460, geo.size.width * 0.46))
                                IPadSideColumn()
                            }
                            .padding(.horizontal, 32).padding(.vertical, 8)
                        } else {
                            RemoteControls(mode: $mode, size: geo.size.height, width: geo.size.width - 40)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationTitle(L10n.Mobile.Tab.remote)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if s.tv != nil { ToolbarItem(placement: .topBarLeading) { PowerButton(size: 34, glow: false) } }
                ToolbarItem(placement: .topBarTrailing) { TVSwitcher() }
            }
        }
        .remoteKeyboardShortcuts()
    }
}

/// Everything on the Remote tab's main column, scaled to the available height.
private struct RemoteControls: View {
    @EnvironmentObject var s: Store
    @Binding var mode: MobileRemoteTab.ControlMode
    let size: CGFloat // available height
    let width: CGFloat
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Shrinks everything a little on short screens (iPhone SE) and grows it on tall ones.
    private var unit: CGFloat { min(max(size / 760, 0.72), 1.2) }
    private var key: CGFloat { 56 * unit }
    private var small: CGFloat { 46 * unit }
    private var rockerScale: CGFloat { 1.3 * unit }
    /// One gap between every row, so spacing is even everywhere.
    private var gap: CGFloat { 20 * unit }
    private var showsApps: Bool { sizeClass != .regular && !s.displayedApps.isEmpty }
    private var showsBanner: Bool { s.link == .needsPairing || s.link == .failed }

    /// The control surface takes whatever height is left after the fixed rows and equal gaps.
    private var pad: CGFloat {
        var rows: [CGFloat] = [36, key, max(76 * rockerScale + 14, key + small + 10)] // picker, keys, media cluster
        if s.volume != nil { rows.append(20) }
        if showsApps { rows.append(50 * unit + 26) }
        if showsBanner { rows.append(58) }
        let fixed = rows.reduce(0, +) + gap * CGFloat(rows.count) + 18 // gaps around the pad + top/bottom inset
        return min(width, max(170, size - fixed))
    }

    var body: some View {
        VStack(spacing: gap) {
            ConnectionBanner()

            VStack(spacing: gap) {
                HStack(spacing: 12) {
                    Picker("", selection: $mode) {
                        Label(L10n.Mobile.Mode.buttons, systemImage: "circle.grid.cross").tag(MobileRemoteTab.ControlMode.dpad)
                        Label(L10n.Mobile.Mode.touchpad, systemImage: "hand.point.up.left").tag(MobileRemoteTab.ControlMode.touchpad)
                    }
                    .pickerStyle(.segmented).labelsHidden()
                    InputMenu(size: 36)
                }
                .frame(height: 36)

                Group {
                    switch mode {
                    case .dpad: DPad(diameter: pad, homeOnLongPress: true).frame(maxWidth: .infinity)
                    case .touchpad: Touchpad().frame(height: pad)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: mode)

                HStack(spacing: 10) {
                    RemoteKey(.back, "arrow.uturn.backward", size: key, iconSize: 18 * unit)
                    RemoteKey(.search, "magnifyingglass", size: key, iconSize: 18 * unit)
                    RemoteKey(.settings, "gearshape", size: key, iconSize: 18 * unit)
                }

                HStack(alignment: .center, spacing: 10) {
                    Rocker(up: .volUp, down: .volDown, upIcon: "speaker.plus.fill", downIcon: "speaker.minus.fill",
                           label: L10n.Remote.volumeShort, scale: rockerScale)
                    VStack(spacing: 10) {
                        RemoteKey(.playPause, "playpause.fill", size: key, iconSize: 20 * unit)
                        HStack(spacing: 10) {
                            RemoteKey(.rewind, "backward.fill", size: small, iconSize: 15 * unit)
                            RemoteKey(.mute, "speaker.slash.fill", size: small, iconSize: 15 * unit)
                            RemoteKey(.forward, "forward.fill", size: small, iconSize: 15 * unit)
                        }
                    }
                    Rocker(up: .chUp, down: .chDown, upIcon: "chevron.up", downIcon: "chevron.down",
                           label: L10n.Remote.channelShort, scale: rockerScale)
                }

                if let v = s.volume { VolumeBar(volume: v).padding(.horizontal, 4) }

                // iPad shows apps in the side column instead.
                if showsApps { AppStrip(iconSize: 50 * unit) }
            }
            .disabled(s.link == .needsPairing)
            .opacity(s.link == .needsPairing ? 0.45 : 1)
        }
        .padding(.vertical, 8)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// Horizontally scrolling app shortcuts (favorites and recents first), a tap from the remote.
private struct AppStrip: View {
    @EnvironmentObject var s: Store
    let iconSize: CGFloat

    var body: some View {
        if !s.displayedApps.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(s.displayedApps) { app in
                        Button { s.launch(app) } label: {
                            VStack(spacing: 4) {
                                AppIcon(app: app, tint: .gray, size: iconSize)
                                Text(app.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
                                    .frame(width: iconSize + 14)
                            }
                        }
                        .buttonStyle(PressStyle())
                        .accessibilityLabel(L10n.Apps.open(app.name))
                    }
                }
                .padding(.horizontal, 2).padding(.vertical, 4)
            }
            .scrollIndicators(.never)
        }
    }
}

/// iPad's second column: apps on top, then typing and the number pad.
private struct IPadSideColumn: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section(L10n.Mobile.Tab.apps) { AppsGrid(iconSize: 60, columns: 5, maxHeight: .infinity) }
                section(L10n.Remote.Tab.type) { TypePad(large: true) }
                section(L10n.Remote.Tab.keypad) { KeypadGrid(height: 52) }
                section(L10n.Remote.Tab.more) { MoreGrid(height: 56) }
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.never)
    }

    func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }
}
#endif
