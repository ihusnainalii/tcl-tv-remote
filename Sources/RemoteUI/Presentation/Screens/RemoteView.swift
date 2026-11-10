import SwiftUI
import TVKit

// MARK: - Remote

struct RemoteView: View {
    @EnvironmentObject var s: Store
    @AppStorage("remoteTab") private var tab = Tab.apps // remembered between opens
    @FocusState private var focused: Bool
    @Namespace private var ns

    enum Tab: String, CaseIterable {
        case apps = "Apps", keypad = "Keypad", type = "Type", more = "More" // raw values are stored; don't localize

        var title: String {
            switch self {
            case .apps: L10n.Remote.Tab.apps
            case .keypad: L10n.Remote.Tab.keypad
            case .type: L10n.Remote.Tab.type
            case .more: L10n.Remote.Tab.more
            }
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ConnectionBanner() // stays tappable: it holds the Pair button
            controls.disabled(s.link == .needsPairing).opacity(s.link == .needsPairing ? 0.45 : 1)
        }
        .remoteKeyboardShortcuts()
        .focused($focused)
        .onAppear { focused = true }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack {
                PowerButton()
                Spacer()
                InputMenu()
                RemoteKey(.search, "magnifyingglass", size: 38, circle: true)
                RemoteKey(.settings, "gearshape", size: 38, circle: true)
            }

            DPad()

            HStack(spacing: 10) {
                RemoteKey(.back, "arrow.uturn.backward")
                RemoteKey(.home, "house.fill")
                RemoteKey(.info, "info.circle")
            }

            HStack(alignment: .center, spacing: 10) {
                Rocker(up: .volUp, down: .volDown, upIcon: "speaker.plus.fill", downIcon: "speaker.minus.fill",
                       label: L10n.Remote.volumeShort)
                VStack(spacing: 8) {
                    RemoteKey(.mute, "speaker.slash.fill")
                    HStack(spacing: 6) {
                        RemoteKey(.rewind, "backward.fill", size: 34)
                        RemoteKey(.playPause, "playpause.fill", size: 34)
                        RemoteKey(.forward, "forward.fill", size: 34)
                    }
                }
                Rocker(up: .chUp, down: .chDown, upIcon: "chevron.up", downIcon: "chevron.down", label: L10n.Remote.channelShort)
            }

            if let v = s.volume { VolumeBar(volume: v).transition(.opacity.combined(with: .move(edge: .top))) }

            tabs
        }
    }

    var tabs: some View {
        VStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { tab = t } } label: {
                        Text(t.title).font(.caption.weight(.semibold))
                            .foregroundStyle(tab == t ? .white : .secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                            .background {
                                if tab == t { Capsule().fill(Theme.accent).matchedGeometryEffect(id: "tab", in: ns) }
                            }
                            .contentShape(Capsule())
                    }.buttonStyle(.plain)
                }
            }
            .padding(3).pill(Capsule())

            Group {
                switch tab {
                case .apps: AppsGrid()
                case .keypad: KeypadGrid()
                case .type: TypePad()
                case .more: MoreGrid()
                }
            }
            .transition(.blurReplace)
            .id(tab)
        }
    }
}

extension View {
    /// Arrow keys, Return, Esc, Delete, Space, +/−, M and H drive the TV (Mac, and iPad/iPhone keyboards).
    func remoteKeyboardShortcuts() -> some View { modifier(RemoteKeyboardShortcuts()) }
}

private struct RemoteKeyboardShortcuts: ViewModifier {
    @EnvironmentObject var s: Store

    func body(content: Content) -> some View {
        content
            .focusable()
            .focusEffectDisabled()
            .onKeyPress { k in
                let map: [KeyEquivalent: Key] = [.upArrow: .up, .downArrow: .down, .leftArrow: .left, .rightArrow: .right,
                                                 .return: .ok, .delete: .backspace, .escape: .back, .space: .playPause, .home: .home]
                if let key = map[k.key] { s.press(key); return .handled }
                switch k.characters {
                case "+", "=": s.press(.volUp)
                case "-": s.press(.volDown)
                case "m": s.press(.mute)
                case "h": s.press(.home)
                default: return .ignored
                }
                return .handled
            }
    }
}

/// Circular D-pad with a glowing arc that glides to the pressed direction.
struct DPad: View {
    @EnvironmentObject var s: Store
    var diameter: CGFloat = 176
    @State private var angle = 270.0
    @State private var glow = 0.0

    let dirs: [(Key, String, Double)] = [(.up, "chevron.up", 270), (.right, "chevron.right", 0),
                                         (.down, "chevron.down", 90), (.left, "chevron.left", 180)]

    var body: some View {
        ZStack {
            Circle().fill(Theme.fill).overlay(Circle().stroke(Theme.stroke, lineWidth: 0.5))
            Circle().trim(from: 0, to: 0.18)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5 * scale, lineCap: .round))
                .padding(4)
                .rotationEffect(.degrees(angle - 32.4))
                .opacity(glow)
                .shadow(color: Theme.glow.opacity(0.7), radius: 6)

            ForEach(dirs, id: \.0) { k, icon, a in
                Image(systemName: icon).font(.system(size: 16 * scale, weight: .bold))
                    .frame(width: 48 * scale, height: 48 * scale).contentShape(Rectangle())
                    .repeatPress { press(k, a) }
                    .accessibilityLabel(k.label)
                .offset(x: cos(a * .pi / 180) * 62 * scale, y: sin(a * .pi / 180) * 62 * scale)
            }

            Button { s.press(.ok) } label: {
                Text("OK").font(.system(size: 15 * scale, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 66 * scale, height: 66 * scale).background(Theme.accent, in: Circle())
                    .shadow(color: Theme.glow.opacity(0.45), radius: 10, y: 3)
            }.buttonStyle(PressStyle())
        }
        .frame(width: diameter, height: diameter)
    }

    private var scale: CGFloat { diameter / 176 }

    func press(_ k: Key, _ a: Double) {
        s.press(k)
        // Take the shortest way around so the arc glides instead of spinning.
        var target = a
        while target - angle > 180 { target -= 360 }
        while angle - target > 180 { target += 360 }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { angle = target; glow = 1 }
        withAnimation(.easeOut(duration: 0.6).delay(0.25)) { glow = 0 }
    }
}

struct Rocker: View {
    @EnvironmentObject var s: Store
    let up: Key, down: Key, upIcon: String, downIcon: String, label: String
    var scale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: upIcon).frame(width: 46 * scale, height: 38 * scale).contentShape(Rectangle())
                .repeatPress { s.press(up) }.accessibilityLabel(up.label)
            Text(label).font(.system(size: 9 * scale, weight: .bold)).foregroundStyle(.secondary)
            Image(systemName: downIcon).frame(width: 46 * scale, height: 38 * scale).contentShape(Rectangle())
                .repeatPress { s.press(down) }.accessibilityLabel(down.label)
        }
        .font(.system(size: 13 * scale, weight: .semibold))
        .pill(Capsule())
    }
}
