import SwiftUI
import TVKit

// MARK: - Devices

struct DevicesView: View {
    @EnvironmentObject var s: Store
    @State private var manualIP = ""
    @State private var manualKind: TV.Kind = .androidTV
    @State private var showManual = false
    @State private var renaming: KnownTV?
    @State private var newName = ""

    var body: some View {
        VStack(spacing: 12) {
            if s.scanning { Radar().frame(height: 90).transition(.scale.combined(with: .opacity)) }

            FitScroll(maxHeight: 380) {
                VStack(alignment: .leading, spacing: 6) {
                    if !s.known.isEmpty {
                        section(L10n.Devices.recent)
                        ForEach(s.sortedKnown) { k in
                            DeviceRow(tv: k.tv, title: k.name, favorite: k.favorite == true,
                                      subtitle: Text(L10n.Devices.lastUsed) + Text(" ")
                                          + Text(k.lastUsed, format: .relative(presentation: .named)),
                                      online: s.isOnline(k.tv), current: s.tv?.id == k.id) { s.select(k.tv) }
                                .contextMenu {
                                    Button(k.favorite == true ? L10n.Common.removeFromFavorites : L10n.Common.addToFavorites) {
                                        s.toggleFavorite(k)
                                    }
                                    Button(L10n.Devices.rename) { newName = k.name; renaming = k }
                                    Divider()
                                    Button(L10n.Devices.forget, role: .destructive) { s.forget(k) }
                                }
                        }
                    }
                    if !s.newTVs.isEmpty {
                        section(L10n.Devices.onThisNetwork)
                        ForEach(s.newTVs) { tv in
                            DeviceRow(tv: tv, subtitle: Text("\(tv.kind.rawValue) · \(tv.host)"),
                                      online: true, current: false) { s.select(tv) }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    if s.known.isEmpty && s.newTVs.isEmpty && !s.scanning {
                        VStack(spacing: 6) {
                            Image(systemName: "tv.slash").font(.title).foregroundStyle(.secondary)
                            Text(L10n.Devices.noTVs).font(.callout.weight(.medium))
                            Text(L10n.Devices.sameWifi).font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                    }
                }
            }

            if showManual {
                VStack(spacing: 8) {
                    TextField(L10n.Devices.ipPlaceholder, text: $manualIP)
                        .textFieldStyle(.plain).padding(8).pill(RoundedRectangle(cornerRadius: 8))
                    Picker("", selection: $manualKind) {
                        ForEach(TV.Kind.allCases, id: \.self) { Text($0.rawValue) }
                    }.pickerStyle(.segmented).labelsHidden()
                    Button(L10n.Devices.connect) {
                        let ip = manualIP.trimmingCharacters(in: .whitespaces)
                        guard !ip.isEmpty else { return }
                        s.select(TV(name: L10n.Devices.manualName(ip), host: ip, kind: manualKind))
                    }
                    .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack {
                Button { withAnimation(.spring) { showManual.toggle() } } label: {
                    Label(showManual ? L10n.Devices.hide : L10n.Devices.addByIP, systemImage: showManual ? "chevron.up" : "plus")
                        .font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6).pill(Capsule())
                }.buttonStyle(PressStyle())
                Spacer()
                Button { s.scan() } label: {
                    Label(s.scanning ? L10n.Devices.scanning : L10n.Devices.scan, systemImage: "dot.radiowaves.left.and.right")
                        .symbolEffect(.variableColor.iterative, isActive: s.scanning)
                        .font(.caption.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6).background(Theme.accent, in: Capsule())
                }.buttonStyle(PressStyle()).disabled(s.scanning)
            }
        }
        .alert(L10n.Devices.renameTitle, isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField(L10n.Common.name, text: $newName)
            Button(L10n.Devices.save) { if let k = renaming { s.rename(k, newName) } }
            Button(L10n.Common.cancel, role: .cancel) {}
        }
    }

    func section(_ title: String) -> some View {
        Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            .padding(.top, 6).padding(.leading, 4)
    }
}

struct DeviceRow: View {
    let tv: TV
    var title: String?
    var favorite = false
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
                    HStack(spacing: 4) {
                        Text(title ?? tv.name).font(.callout.weight(.medium)).lineLimit(1)
                        if favorite {
                            Image(systemName: "star.fill").font(.system(size: 9)).foregroundStyle(.yellow)
                                .transition(.scale.combined(with: .opacity)).accessibilityLabel(L10n.Common.favorite)
                        }
                    }
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
        .buttonStyle(PressStyle(hoverScale: 1, pressScale: 0.97)) // full-width rows: highlight, don't grow
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
                    .shadow(color: Theme.glow.opacity(0.6), radius: 8)
            }
        }
        .accessibilityLabel(L10n.Devices.scanningForTVs)
    }
}
