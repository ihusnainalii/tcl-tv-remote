import SwiftUI
import TVKit

#if os(iOS)
/// The Remote tab: big touch targets, D-pad or touchpad, and on iPad a second column with apps.
struct MobileRemoteTab: View {
    @EnvironmentObject var s: Store
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("controlMode") private var mode = ControlMode.dpad

    enum ControlMode: String, CaseIterable { case dpad, touchpad }

    var body: some View {
        NavigationStack {
            ScrollView {
                if s.tv == nil {
                    NoTVView().padding(.horizontal, 20)
                } else if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 40) {
                        controls(big: true).frame(maxWidth: 460)
                        VStack(alignment: .leading, spacing: 14) {
                            Text(L10n.Mobile.Tab.apps.uppercased()).font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                            AppsGrid(iconSize: 64, columns: 4, maxHeight: .infinity)
                        }
                        .frame(maxWidth: 440)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                } else {
                    controls(big: false).padding(.horizontal, 20).padding(.bottom, 24)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(L10n.Mobile.Tab.remote)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if s.tv != nil { ToolbarItem(placement: .topBarLeading) { PowerButton(size: 34, glow: false) } }
                ToolbarItem(placement: .topBarTrailing) { TVSwitcher() }
            }
        }
        .remoteKeyboardShortcuts()
    }

    private func controls(big: Bool) -> some View {
        VStack(spacing: 22) {
            ConnectionBanner() // stays tappable: it holds the Pair button
            buttons(big: big).disabled(s.link == .needsPairing).opacity(s.link == .needsPairing ? 0.45 : 1)
        }
    }

    private func buttons(big: Bool) -> some View {
        let key: CGFloat = big ? 64 : 56, small: CGFloat = big ? 52 : 46, pad: CGFloat = big ? 320 : 260
        return VStack(spacing: big ? 26 : 22) {
            HStack(spacing: 12) {
                Picker("", selection: $mode) {
                    Label(L10n.Mobile.Mode.buttons, systemImage: "circle.grid.cross").tag(ControlMode.dpad)
                    Label(L10n.Mobile.Mode.touchpad, systemImage: "hand.point.up.left").tag(ControlMode.touchpad)
                }
                .pickerStyle(.segmented).labelsHidden()
                InputMenu(size: 40)
            }

            Group {
                switch mode {
                case .dpad: DPad(diameter: pad).frame(height: pad + 20)
                case .touchpad: Touchpad().frame(height: pad + 20)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: mode)

            HStack(spacing: 12) {
                RemoteKey(.back, "arrow.uturn.backward", size: key, iconSize: 18)
                RemoteKey(.home, "house.fill", size: key, iconSize: 18)
                RemoteKey(.search, "magnifyingglass", size: key, iconSize: 18)
                RemoteKey(.settings, "gearshape", size: key, iconSize: 18)
            }

            HStack(alignment: .center, spacing: 12) {
                Rocker(up: .volUp, down: .volDown, upIcon: "speaker.plus.fill", downIcon: "speaker.minus.fill",
                       label: L10n.Remote.volumeShort, scale: big ? 1.55 : 1.35)
                VStack(spacing: 10) {
                    RemoteKey(.playPause, "playpause.fill", size: key, iconSize: 20)
                    HStack(spacing: 10) {
                        RemoteKey(.rewind, "backward.fill", size: small, iconSize: 15)
                        RemoteKey(.mute, "speaker.slash.fill", size: small, iconSize: 15)
                        RemoteKey(.forward, "forward.fill", size: small, iconSize: 15)
                    }
                }
                Rocker(up: .chUp, down: .chDown, upIcon: "chevron.up", downIcon: "chevron.down",
                       label: L10n.Remote.channelShort, scale: big ? 1.55 : 1.35)
            }

            if let v = s.volume { VolumeBar(volume: v).padding(.horizontal, 4) }
        }
    }
}
#endif
