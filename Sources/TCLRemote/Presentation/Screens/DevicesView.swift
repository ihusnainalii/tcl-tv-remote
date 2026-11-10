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

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if !s.known.isEmpty {
                        section("Recent")
                        ForEach(s.sortedKnown) { k in
                            DeviceRow(tv: k.tv, title: k.name, favorite: k.favorite == true,
                                      subtitle: Text("Last used ") + Text(k.lastUsed, format: .relative(presentation: .named)),
                                      online: s.isOnline(k.tv), current: s.tv?.id == k.id) { s.select(k.tv) }
                                .contextMenu {
                                    Button(k.favorite == true ? "Remove from Favorites" : "Add to Favorites") { s.toggleFavorite(k) }
                                    Button("Rename…") { newName = k.name; renaming = k }
                                    Divider()
                                    Button("Forget", role: .destructive) { s.forget(k) }
                                }
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
            .frame(maxHeight: .infinity)
            .scrollIndicators(.never)

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
        .alert("Rename TV", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $newName)
            Button("Save") { if let k = renaming { s.rename(k, newName) } }
            Button("Cancel", role: .cancel) {}
        }
    }

    func section(_ title: String) -> some View {
        Text(title.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            .padding(.top, 6).padding(.leading, 4)
    }
}

struct DeviceRow: View {
    let tv: TV
    var title: String? = nil
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
                                .transition(.scale.combined(with: .opacity)).accessibilityLabel("Favorite")
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
