import SwiftUI
import TVKit

// Building blocks shared by the Mac panel and the iPhone/iPad layouts.

/// A remote key: SF Symbol on a pill, sends `key` when tapped.
struct RemoteKey: View {
    @EnvironmentObject var s: Store
    let key: Key
    let icon: String
    var size: CGFloat = 40
    var circle = false
    var iconSize: CGFloat = 13

    init(_ key: Key, _ icon: String, size: CGFloat = 40, circle: Bool = false, iconSize: CGFloat = 13) {
        self.key = key; self.icon = icon; self.size = size; self.circle = circle; self.iconSize = iconSize
    }

    var body: some View {
        Button { s.press(key) } label: {
            Image(systemName: icon).font(.system(size: iconSize, weight: .semibold))
                .frame(maxWidth: circle ? size : .infinity, minHeight: size, maxHeight: size)
                .frame(width: circle ? size : nil)
                .pill(RoundedRectangle(cornerRadius: circle ? size / 2 : size * 0.28))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .help(key.label)
        .accessibilityLabel(key.label)
    }
}

struct PowerButton: View {
    @EnvironmentObject var s: Store
    var size: CGFloat = 38
    var glow = true // off where the container clips shadows (e.g. iOS toolbars)

    var body: some View {
        Button { s.press(.power) } label: {
            Image(systemName: "power").font(.system(size: size * 0.4, weight: .bold)).foregroundStyle(.white)
                .frame(width: size, height: size).background(Theme.power, in: Circle())
                .shadow(color: .red.opacity(glow && s.tvOn != false ? 0.45 : 0), radius: 8, y: 2)
        }
        .buttonStyle(PressStyle()).help(L10n.Remote.power).accessibilityLabel(L10n.Remote.power)
    }
}

/// HDMI / AV / Live TV picker.
struct InputMenu: View {
    @EnvironmentObject var s: Store
    var size: CGFloat = 38

    var body: some View {
        Menu {
            ForEach([Key.hdmi1, .hdmi2, .hdmi3, .hdmi4], id: \.self) { k in
                Button(L10n.Remote.hdmi(String(k.rawValue.last!))) { s.press(k) }
            }
            Button(L10n.Remote.av) { s.press(.av) }
            Button(L10n.Remote.liveTV) { s.press(.tuner) }
        } label: {
            Image(systemName: "cable.connector").font(.system(size: size * 0.34, weight: .semibold))
                .frame(width: size, height: size).pill(Circle())
        }
        .menuStyle(.button).buttonStyle(PressStyle()).menuIndicator(.hidden).fixedSize()
        .help(L10n.Remote.input).accessibilityLabel(L10n.Remote.inputSource)
    }
}

/// "Pair with this TV" / "TV is unreachable" card, shown above the controls when needed.
struct ConnectionBanner: View {
    @EnvironmentObject var s: Store

    var body: some View {
        switch s.link {
        case .needsPairing:
            card(icon: "link.badge.plus", title: L10n.Remote.PairCard.title, subtitle: L10n.Remote.PairCard.subtitle,
                 action: L10n.Pairing.pair) { s.beginPairing() }
        case .failed:
            card(icon: "wifi.exclamationmark", title: L10n.Remote.OfflineCard.title,
                 subtitle: [s.lastError, s.autoRetryStopped ? L10n.Remote.OfflineCard.stopped : L10n.Remote.OfflineCard.subtitle]
                    .compactMap { $0 }.joined(separator: " "),
                 action: L10n.Remote.retry,
                 secondary: s.tv?.kind == .androidTV ? (L10n.Remote.repair, { s.beginPairing() }) : nil) { s.connect() }
        default: EmptyView()
        }
    }

    func card(icon: String, title: String, subtitle: String, action: String,
              secondary: (String, () -> Void)? = nil, _ run: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout.weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if let secondary { Button(secondary.0, action: secondary.1).buttonStyle(.bordered).controlSize(.small) }
            Button(action, action: run).buttonStyle(.borderedProminent).controlSize(.small)
        }
        .padding(10)
        .pill(RoundedRectangle(cornerRadius: 12))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct KeypadGrid: View {
    @EnvironmentObject var s: Store
    var height: CGFloat = 36

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9], id: \.self) { digit($0) }
            RemoteKey(.backspace, "delete.left", size: height)
            digit(0)
            RemoteKey(.ok, "return", size: height)
        }
    }

    func digit(_ n: Int) -> some View {
        Button { s.press(Key(rawValue: "n\(n)")!) } label: {
            Text("\(n)").font(.system(size: height * 0.47, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: height).pill(RoundedRectangle(cornerRadius: height * 0.28))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

/// Guide, exit, captions, stop, previous/next, discrete power and menu.
struct MoreGrid: View {
    @EnvironmentObject var s: Store
    var height: CGFloat = 46

    private let items: [(Key, String)] = [(.guide, "list.bullet.rectangle"), (.exit, "xmark.circle"), (.captions, "captions.bubble"),
                                          (.previous, "backward.end.fill"), (.stop, "stop.fill"), (.next, "forward.end.fill"),
                                          (.powerOn, "power.circle"), (.powerOff, "power.circle.fill"), (.menu, "line.3.horizontal")]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(items, id: \.0) { k, icon in
                Button { s.press(k) } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon).font(.system(size: height * 0.3, weight: .semibold))
                        Text(k.label).font(.system(size: max(9, height * 0.2), weight: .medium)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: height).pill(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle())
            }
        }
    }
}

/// Live keyboard: whatever changes in the field is mirrored to the TV's focused text box.
struct TypePad: View {
    @EnvironmentObject var s: Store
    @State private var text = ""
    var large = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField(L10n.Remote.Typing.placeholder, text: $text)
                    .textFieldStyle(.plain).padding(large ? 14 : 9).pill(RoundedRectangle(cornerRadius: large ? 14 : 10))
                    .font(large ? .body : nil)
                    .autocorrectionDisabled()
                    .onChange(of: text) { old, new in mirror(old, new) }
                    .onSubmit { s.press(.enter); text = "" }
                Button { s.press(.enter); text = "" } label: {
                    Image(systemName: "return").font(.system(size: large ? 16 : 13, weight: .bold)).foregroundStyle(.white)
                        .frame(width: large ? 48 : 34, height: large ? 48 : 34).background(Theme.accent, in: Circle())
                }
                .buttonStyle(PressStyle()).help(L10n.Remote.Typing.enterHelp).accessibilityLabel(L10n.Remote.Typing.enter)
            }
            Text(L10n.Remote.Typing.hint)
                .font(large ? .footnote : .caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Sends only the difference: backspaces for removed characters, then the added text.
    private func mirror(_ old: String, _ new: String) {
        let common = zip(old, new).prefix { $0 == $1 }.count
        for _ in 0..<(old.count - common) { s.press(.backspace) }
        s.type(String(new.dropFirst(common)))
    }
}
