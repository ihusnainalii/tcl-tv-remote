import SwiftUI
import TVKit

// MARK: - Remote

struct RemoteView: View {
    @EnvironmentObject var s: Store
    @State private var tab = Tab.apps
    @State private var text = ""
    @FocusState private var focused: Bool
    @Namespace private var ns

    enum Tab: String, CaseIterable { case apps = "Apps", keypad = "Keypad", type = "Type", more = "More" }

    var body: some View {
        VStack(spacing: 14) {
            banner

            HStack {
                Button { s.press(.power) } label: {
                    Image(systemName: "power").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 38, height: 38).background(Theme.power, in: Circle())
                        .shadow(color: .red.opacity(s.tvOn == false ? 0 : 0.45), radius: 8, y: 2)
                }.buttonStyle(PressStyle()).help("Power").accessibilityLabel("Power")
                Spacer()
                Menu {
                    ForEach([Key.hdmi1, .hdmi2, .hdmi3, .hdmi4], id: \.self) { k in
                        Button("HDMI \(k.rawValue.last!)") { s.press(k) }
                    }
                    Button("AV") { s.press(.av) }
                    Button("Live TV") { s.press(.tuner) }
                } label: {
                    Image(systemName: "rectangle.on.rectangle").font(.system(size: 13, weight: .semibold))
                        .frame(width: 38, height: 38).pill(Circle())
                }
                .menuStyle(.button).buttonStyle(PressStyle()).menuIndicator(.hidden).fixedSize().help("Input")
                .accessibilityLabel("Input source")
                key(.search, "magnifyingglass", size: 38, circle: true)
                key(.settings, "gearshape", size: 38, circle: true)
            }

            DPad()

            HStack(spacing: 10) {
                key(.back, "arrow.uturn.backward")
                key(.home, "house.fill")
                key(.info, "info.circle")
            }

            HStack(alignment: .center, spacing: 10) {
                Rocker(up: .volUp, down: .volDown, upIcon: "speaker.plus.fill", downIcon: "speaker.minus.fill", label: "VOL")
                VStack(spacing: 8) {
                    key(.mute, "speaker.slash.fill")
                    HStack(spacing: 6) {
                        key(.rewind, "backward.fill", size: 34)
                        key(.playPause, "playpause.fill", size: 34)
                        key(.forward, "forward.fill", size: 34)
                    }
                }
                Rocker(up: .chUp, down: .chDown, upIcon: "chevron.up", downIcon: "chevron.down", label: "CH")
            }

            if let v = s.volume { VolumeBar(volume: v).transition(.opacity.combined(with: .move(edge: .top))) }

            tabs
        }
        .disabled(s.link == .needsPairing)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
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
        .onAppear { focused = true }
    }

    @ViewBuilder var banner: some View {
        switch s.link {
        case .needsPairing:
            card(icon: "link.badge.plus", title: "Pair with this TV", subtitle: "One-time setup. A code will appear on the TV.",
                 action: "Pair") { s.beginPairing() }
        case .failed:
            card(icon: "wifi.exclamationmark", title: "TV is unreachable", subtitle: "Retrying automatically…",
                 action: "Retry", secondary: s.tv?.kind == .androidTV ? ("Re-pair", { s.beginPairing() }) : nil) { s.connect() }
        default: EmptyView()
        }
    }

    func card(icon: String, title: String, subtitle: String, action: String,
              secondary: (String, () -> Void)? = nil, _ run: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout.weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if let secondary { Button(secondary.0, action: secondary.1).buttonStyle(.bordered).controlSize(.small) }
            Button(action, action: run).buttonStyle(.borderedProminent).controlSize(.small)
        }
        .padding(10)
        .pill(RoundedRectangle(cornerRadius: 12))
        .disabled(false)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    var tabs: some View {
        VStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { tab = t } } label: {
                        Text(t.rawValue).font(.caption.weight(.semibold))
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
                case .keypad: keypad
                case .type: typer
                case .more: more
                }
            }
            .transition(.blurReplace)
            .id(tab)
        }
    }

    var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9], id: \.self) { n in digit(n) }
            key(.backspace, "delete.left")
            digit(0)
            key(.ok, "return")
        }
    }

    var more: some View {
        let items: [(Key, String)] = [(.guide, "list.bullet.rectangle"), (.exit, "xmark.circle"), (.captions, "captions.bubble"),
                                      (.previous, "backward.end.fill"), (.stop, "stop.fill"), (.next, "forward.end.fill"),
                                      (.powerOn, "power.circle"), (.powerOff, "power.circle.fill"), (.menu, "line.3.horizontal")]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(items, id: \.0) { k, icon in
                Button { s.press(k) } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                        Text(k.label).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 46).pill(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PressStyle())
            }
        }
    }

    func digit(_ n: Int) -> some View {
        Button { s.press(Key(rawValue: "n\(n)")!) } label: {
            Text("\(n)").font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 36).pill(RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(PressStyle())
    }

    /// Live keyboard: whatever changes in the field is mirrored to the TV's focused text box.
    var typer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Type on TV…", text: $text)
                    .textFieldStyle(.plain).padding(9).pill(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: text) { old, new in mirror(old, new) }
                    .onSubmit { s.press(.enter); text = "" }
                Button { s.press(.enter); text = "" } label: {
                    Image(systemName: "return").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 34, height: 34).background(Theme.accent, in: Circle())
                }
                .buttonStyle(PressStyle()).help("Send Enter to the TV").accessibilityLabel("Enter")
            }
            Text("Open a search or text box on the TV, then type here. Letters appear on the TV as you type; Return sends Enter.")
                .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Sends only the difference: backspaces for removed characters, then the added text.
    private func mirror(_ old: String, _ new: String) {
        let common = zip(old, new).prefix { $0 == $1 }.count
        for _ in 0..<(old.count - common) { s.press(.backspace) }
        s.type(String(new.dropFirst(common)))
    }

    func key(_ k: Key, _ icon: String, size: CGFloat = 40, circle: Bool = false) -> some View {
        Button { s.press(k) } label: {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: circle ? size : .infinity, minHeight: size, maxHeight: size)
                .frame(width: circle ? size : nil)
                .pill(RoundedRectangle(cornerRadius: circle ? size / 2 : 11))
        }
        .buttonStyle(PressStyle())
        .help(k.label)
        .accessibilityLabel(k.label)
    }
}

/// Circular D-pad with a glowing arc that glides to the pressed direction.
struct DPad: View {
    @EnvironmentObject var s: Store
    @State private var angle = 270.0
    @State private var glow = 0.0

    let dirs: [(Key, String, Double)] = [(.up, "chevron.up", 270), (.right, "chevron.right", 0),
                                         (.down, "chevron.down", 90), (.left, "chevron.left", 180)]

    var body: some View {
        ZStack {
            Circle().fill(Theme.fill).overlay(Circle().stroke(Theme.stroke, lineWidth: 0.5))
            Circle().trim(from: 0, to: 0.18)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .padding(4)
                .rotationEffect(.degrees(angle - 32.4))
                .opacity(glow)
                .shadow(color: Theme.glow.opacity(0.7), radius: 6)

            ForEach(dirs, id: \.0) { k, icon, a in
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                    .frame(width: 48, height: 48).contentShape(Rectangle())
                    .repeatPress { press(k, a) }
                    .accessibilityLabel(k.label)
                .offset(x: cos(a * .pi / 180) * 62, y: sin(a * .pi / 180) * 62)
            }

            Button { s.press(.ok) } label: {
                Text("OK").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 66, height: 66).background(Theme.accent, in: Circle())
                    .shadow(color: Theme.glow.opacity(0.45), radius: 10, y: 3)
            }.buttonStyle(PressStyle())
        }
        .frame(width: 176, height: 176)
    }

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

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: upIcon).frame(width: 46, height: 38).contentShape(Rectangle())
                .repeatPress { s.press(up) }.accessibilityLabel(up.label)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Image(systemName: downIcon).frame(width: 46, height: 38).contentShape(Rectangle())
                .repeatPress { s.press(down) }.accessibilityLabel(down.label)
        }
        .font(.system(size: 13, weight: .semibold))
        .pill(Capsule())
    }
}
