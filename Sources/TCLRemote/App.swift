import SwiftUI

@main
struct TCLRemoteApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        MenuBarExtra {
            RootView().environmentObject(store)
        } label: {
            Image(systemName: store.link == .connected ? "appletvremote.gen4.fill" : "appletvremote.gen4")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Theme

enum Theme {
    static let accent = LinearGradient(colors: [Color(red: 0.38, green: 0.45, blue: 1), Color(red: 0.66, green: 0.36, blue: 1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
    static let power = LinearGradient(colors: [Color(red: 1, green: 0.38, blue: 0.38), Color(red: 0.86, green: 0.15, blue: 0.3)],
                                      startPoint: .top, endPoint: .bottom)
    static let fill = Color.primary.opacity(0.07)
    static let stroke = Color.primary.opacity(0.09)
    static let spring = Animation.spring(response: 0.32, dampingFraction: 0.62)
}

/// Squishy press + hover lift used by every control.
struct PressStyle: ButtonStyle {
    func makeBody(configuration c: Configuration) -> some View { Pressable(c: c) }

    private struct Pressable: View {
        let c: Configuration
        @State private var hover = false
        var body: some View {
            c.label
                .scaleEffect(c.isPressed ? 0.88 : hover ? 1.04 : 1)
                .brightness(c.isPressed ? 0.12 : hover ? 0.04 : 0)
                .animation(Theme.spring, value: c.isPressed)
                .animation(.easeOut(duration: 0.15), value: hover)
                .onHover { hover = $0 }
        }
    }
}

extension View {
    func pill<S: Shape>(_ shape: S) -> some View {
        background(Theme.fill, in: shape).overlay(shape.stroke(Theme.stroke, lineWidth: 0.5))
    }
}

// MARK: - Root

struct RootView: View {
    @EnvironmentObject var s: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func slide(_ edge: Edge) -> AnyTransition { reduceMotion ? .opacity : .push(from: edge) }

    var body: some View {
        VStack(spacing: 14) {
            Header()
            ZStack {
                switch s.screen {
                case .devices: DevicesView().transition(slide(.leading))
                case .pairing: PairingView().transition(slide(.trailing))
                case .remote: RemoteView().transition(slide(.trailing))
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .padding(16)
        .frame(width: 300)
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
        case .idle: ("Not connected", .secondary)
        case .connecting: ("Connecting…", .orange)
        case .connected: (s.tvOn == false ? "Standby" : "Connected", .green)
        case .needsPairing: ("Pairing required", .yellow)
        case .failed: ("Offline", .red)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(Theme.accent).frame(width: 32, height: 32)
                Image(systemName: "tv").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(s.tv?.name ?? "TCL Remote").font(.headline).lineLimit(1)
                HStack(spacing: 5) {
                    StatusDot(color: status.1, pulsing: s.link == .connecting || s.link == .connected)
                    Text(status.0).font(.caption).foregroundStyle(.secondary).contentTransition(.opacity)
                }
            }
            Spacer()
            if s.screen == .remote {
                Button { s.showDevices() } label: { icon("list.bullet") }.buttonStyle(PressStyle()).help("TVs")
            } else if s.screen == .devices, s.tv != nil {
                Button { s.select(s.tv!) } label: { icon("appletvremote.gen4") }.buttonStyle(PressStyle()).help("Remote")
            }
            Menu {
                Toggle("Launch at Login", isOn: Binding(get: { s.launchAtLogin }, set: { s.setLaunchAtLogin($0) }))
                Button("Find TVs…") { s.showDevices() }
                Divider()
                Button("Quit TCL Remote") { NSApp.terminate(nil) }.keyboardShortcut("q")
            } label: { icon("ellipsis") }
            .menuStyle(.button).buttonStyle(PressStyle()).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel("More options")
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

// MARK: - Devices

struct DevicesView: View {
    @EnvironmentObject var s: Store
    @State private var manualIP = ""
    @State private var manualKind: TV.Kind = .androidTV
    @State private var showManual = false

    var body: some View {
        VStack(spacing: 12) {
            if s.scanning { Radar().frame(height: 90).transition(.scale.combined(with: .opacity)) }

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if !s.known.isEmpty {
                        section("Recent")
                        ForEach(s.known) { k in
                            DeviceRow(tv: k.tv, subtitle: Text("Last used ") + Text(k.lastUsed, format: .relative(presentation: .named)),
                                      online: s.isOnline(k.tv), current: s.tv?.id == k.id) { s.select(k.tv) }
                                .contextMenu { Button("Forget", role: .destructive) { s.forget(k) } }
                        }
                    }
                    if !s.newTVs.isEmpty {
                        section("On this network")
                        ForEach(s.newTVs) { tv in
                            DeviceRow(tv: tv, subtitle: Text("\(tv.kind.rawValue) · \(tv.host)"), online: true, current: false) { s.select(tv) }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    if s.known.isEmpty && s.newTVs.isEmpty && !s.scanning {
                        VStack(spacing: 6) {
                            Image(systemName: "tv.slash").font(.title).foregroundStyle(.secondary)
                            Text("No TVs found").font(.callout.weight(.medium))
                            Text("Make sure your Mac and TV are on the same Wi-Fi.").font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                    }
                }
            }
            .frame(maxHeight: 280)
            .fixedSize(horizontal: false, vertical: true)

            if showManual {
                VStack(spacing: 8) {
                    TextField("TV IP address, e.g. 192.168.1.20", text: $manualIP)
                        .textFieldStyle(.plain).padding(8).pill(RoundedRectangle(cornerRadius: 8))
                    Picker("", selection: $manualKind) {
                        ForEach(TV.Kind.allCases, id: \.self) { Text($0.rawValue) }
                    }.pickerStyle(.segmented).labelsHidden()
                    Button("Connect") {
                        let ip = manualIP.trimmingCharacters(in: .whitespaces)
                        guard !ip.isEmpty else { return }
                        s.select(TV(name: "TCL TV (\(ip))", host: ip, kind: manualKind))
                    }
                    .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack {
                Button { withAnimation(.spring) { showManual.toggle() } } label: {
                    Label(showManual ? "Hide" : "Add by IP", systemImage: showManual ? "chevron.up" : "plus")
                        .font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6).pill(Capsule())
                }.buttonStyle(PressStyle())
                Spacer()
                Button { s.scan() } label: {
                    Label(s.scanning ? "Scanning…" : "Scan", systemImage: "dot.radiowaves.left.and.right")
                        .symbolEffect(.variableColor.iterative, isActive: s.scanning)
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Theme.accent, in: Capsule())
                }.buttonStyle(PressStyle()).disabled(s.scanning)
            }
        }
    }

    func section(_ title: String) -> some View {
        Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            .padding(.top, 6).padding(.leading, 4)
    }
}

struct DeviceRow: View {
    let tv: TV
    let subtitle: Text
    let online: Bool
    let current: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tv.kind == .roku ? "tv.badge.wifi" : "tv.inset.filled")
                    .font(.system(size: 16)).frame(width: 34, height: 34)
                    .background(current ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.fill), in: RoundedRectangle(cornerRadius: 9))
                    .foregroundStyle(current ? .white : .primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tv.name).font(.callout.weight(.medium)).lineLimit(1)
                    subtitle.font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Circle().fill(online ? Color.green : Color.secondary.opacity(0.4)).frame(width: 6, height: 6)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(8)
            .contentShape(Rectangle())
            .pill(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressStyle())
    }
}

struct Radar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { t in
            let phase = reduceMotion ? 0.3 : t.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2
            ZStack {
                ForEach(0..<3) { i in
                    let p = (phase + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Circle().stroke(Theme.accent, lineWidth: 2)
                        .scaleEffect(0.2 + p * 0.8).opacity(1 - p)
                }
                Circle().fill(Theme.accent).frame(width: 14, height: 14)
                    .shadow(color: .purple.opacity(0.6), radius: 8)
            }
        }
        .accessibilityLabel("Scanning for TVs")
    }
}

// MARK: - Pairing

struct PairingView: View {
    @EnvironmentObject var s: Store
    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.tv").font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.accent).symbolEffect(.pulse)
            VStack(spacing: 4) {
                Text("Enter the code on your TV").font(.headline)
                Text("A 6-character code is showing on screen.").font(.caption).foregroundStyle(.secondary)
            }
            ZStack {
                TextField("", text: $code).focused($focused).opacity(0.01)
                    .onChange(of: code) { _, new in
                        let clean = String(new.uppercased().filter(\.isHexDigit).prefix(6))
                        if clean != new { code = clean }
                        if clean.count == 6 { s.submitCode(clean) }
                    }
                HStack(spacing: 7) {
                    ForEach(0..<6, id: \.self) { i in
                        let chars = Array(code)
                        let active = i == chars.count && focused
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Theme.fill)
                                .overlay(RoundedRectangle(cornerRadius: 9)
                                    .stroke(active ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.stroke), lineWidth: active ? 2 : 0.5))
                            if i < chars.count {
                                Text(String(chars[i])).font(.system(size: 20, weight: .semibold, design: .monospaced))
                                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                            }
                        }
                        .frame(width: 36, height: 44)
                        .scaleEffect(active ? 1.06 : 1)
                    }
                }
                .animation(Theme.spring, value: code)
                .contentShape(Rectangle())
                .onTapGesture { focused = true }
            }
            .keyframeAnimator(initialValue: 0.0, trigger: s.pairError) { c, x in c.offset(x: x) } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-10, duration: 0.06); CubicKeyframe(9, duration: 0.06)
                    CubicKeyframe(-6, duration: 0.06); CubicKeyframe(4, duration: 0.06); CubicKeyframe(0, duration: 0.06)
                }
            }
            .onChange(of: s.pairError) { code = "" }

            HStack {
                Button("Cancel") { s.cancelPairing() }.buttonStyle(.bordered)
                Button("Pair") { s.submitCode(code) }.buttonStyle(.borderedProminent).disabled(code.count < 6)
            }
        }
        .padding(.vertical, 8)
        .onAppear { focused = true }
    }
}

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

    var typer: some View {
        HStack(spacing: 8) {
            TextField("Type on TV…", text: $text)
                .textFieldStyle(.plain).padding(9).pill(RoundedRectangle(cornerRadius: 10))
                .onSubmit { s.type(text); text = "" }
            Button { s.type(text); text = "" } label: {
                Image(systemName: "paperplane.fill").foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Theme.accent, in: Circle())
            }.buttonStyle(PressStyle()).disabled(text.isEmpty)
        }
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
                .shadow(color: .purple.opacity(0.7), radius: 6)

            ForEach(dirs, id: \.0) { k, icon, a in
                Button { press(k, a) } label: {
                    Image(systemName: icon).font(.system(size: 16, weight: .bold))
                        .frame(width: 48, height: 48).contentShape(Rectangle())
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel(k.label)
                .offset(x: cos(a * .pi / 180) * 62, y: sin(a * .pi / 180) * 62)
            }

            Button { s.press(.ok) } label: {
                Text("OK").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 66, height: 66).background(Theme.accent, in: Circle())
                    .shadow(color: .purple.opacity(0.45), radius: 10, y: 3)
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
            Button { s.press(up) } label: { Image(systemName: upIcon).frame(width: 46, height: 38).contentShape(Rectangle()) }
                .buttonStyle(PressStyle()).accessibilityLabel(up.label)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Button { s.press(down) } label: { Image(systemName: downIcon).frame(width: 46, height: 38).contentShape(Rectangle()) }
                .buttonStyle(PressStyle()).accessibilityLabel(down.label)
        }
        .font(.system(size: 13, weight: .semibold))
        .pill(Capsule())
    }
}

struct AppsGrid: View {
    @EnvironmentObject var s: Store
    @State private var shown = false

    var body: some View {
        if s.apps.isEmpty {
            Text(s.link == .connected ? "No apps" : "Connect to see apps").font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 60)
        } else {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(Array(s.apps.enumerated()), id: \.element.id) { i, app in
                        Button { s.launch(app) } label: {
                            VStack(spacing: 5) {
                                Text(String(app.name.prefix(1)))
                                    .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(tint(app.name).gradient, in: RoundedRectangle(cornerRadius: 10))
                                Text(app.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .buttonStyle(PressStyle())
                        .scaleEffect(shown ? 1 : 0.6).opacity(shown ? 1 : 0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(Double(min(i, 12)) * 0.03), value: shown)
                    }
                }
            }
            .frame(maxHeight: 170)
            .onAppear { shown = true }
        }
    }

    func tint(_ name: String) -> Color {
        let known: [String: Color] = ["Netflix": .red, "YouTube": .red, "Spotify": .green, "Prime Video": .cyan,
                                      "Disney+": .blue, "Max": .indigo, "Hulu": .green, "Plex": .orange]
        if let c = known[name] { return c }
        let palette: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo, .mint]
        return palette[abs(name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }) % palette.count]
    }
}

/// Live volume level reported by Google TV.
struct VolumeBar: View {
    let volume: Store.Volume
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: volume.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.caption).foregroundStyle(.secondary).contentTransition(.symbolEffect(.replace))
            GeometryReader { g in
                Capsule().fill(Theme.fill)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Theme.accent)
                            .frame(width: g.size.width * CGFloat(volume.level) / CGFloat(max(volume.max, 1)))
                            .opacity(volume.muted ? 0.35 : 1)
                    }
            }
            .frame(height: 6)
            Text("\(volume.level)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .contentTransition(.numericText()).frame(width: 24, alignment: .trailing)
        }
        .animation(.smooth, value: volume)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(volume.muted ? "Muted" : "Volume \(volume.level) of \(volume.max)")
    }
}
