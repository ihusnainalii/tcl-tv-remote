import SwiftUI
import TVKit

struct AppsGrid: View {
    @EnvironmentObject var s: Store
    @State private var shown = false
    @State private var query = ""
    @State private var adding = false

    var apps: [TVApp] {
        query.isEmpty ? s.displayedApps : s.displayedApps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 8) {
            if s.displayedApps.count > 9 {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                    TextField(L10n.Apps.search, text: $query).textFieldStyle(.plain).font(.caption)
                }
                .padding(7).pill(RoundedRectangle(cornerRadius: 8))
            }
            if s.link != .connected && s.displayedApps.isEmpty {
                Text(L10n.Apps.connectToSee).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 60)
            } else {
                FitScroll(maxHeight: 220) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { i, app in
                            tile(app)
                                .scaleEffect(shown ? 1 : 0.6).opacity(shown ? 1 : 0)
                                .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(Double(min(i, 12)) * 0.03), value: shown)
                        }
                        if query.isEmpty, s.tv?.kind != .roku { addTile } // Roku already lists every installed app
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: apps)
                }
            }
        }
        .onAppear { shown = true }
    }

    func tile(_ app: TVApp) -> some View {
        Button { s.launch(app) } label: {
            VStack(spacing: 5) {
                AppIcon(app: app, tint: tint(app.name))
                    .overlay(alignment: .topTrailing) {
                        if s.isFavorite(app) {
                            Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                                .padding(3).background(.regularMaterial, in: Circle()).offset(x: 5, y: -5)
                                .transition(.scale)
                        }
                    }
                Text(app.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 68, maxHeight: 68)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(L10n.Apps.open(app.name))
        .contextMenu {
            Button(s.isFavorite(app) ? L10n.Common.removeFromFavorites : L10n.Common.addToFavorites) { s.toggleFavorite(app) }
            if s.isCustom(app) { Button(L10n.Apps.removeShortcut, role: .destructive) { s.removeCustomApp(app) } }
        }
    }

    var addTile: some View {
        Button { adding = true } label: {
            VStack(spacing: 5) {
                Image(systemName: "plus").font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3])))
                    .foregroundStyle(.secondary)
                Text(L10n.Common.add).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 68, maxHeight: 68)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(L10n.Apps.addAnApp)
        .popover(isPresented: $adding, arrowEdge: .bottom) { AppPicker().environmentObject(s) }
    }

    func tint(_ name: String) -> Color {
        let known: [String: Color] = ["Netflix": .red, "YouTube": .red, "Spotify": .green, "Prime Video": .cyan,
                                      "Disney+": .blue, "Max": .indigo, "Hulu": .green, "Plex": .orange, "Apple TV": .gray]
        if let c = known[name] { return c }
        let palette: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo, .mint]
        return palette[abs(name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }) % palette.count]
    }
}

/// Real app icon (from the TV or the App Store), with the letter tile as placeholder/fallback.
struct AppIcon: View {
    let app: TVApp
    let tint: Color
    @State private var url: URL?

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
            if let image = phase.image {
                image.resizable().interpolation(.high).scaledToFill()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                Text(String(app.name.prefix(1)))
                    .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(tint.gradient)
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.stroke, lineWidth: 0.5))
        .task(id: app.id) { url = await AppIconResolver.shared.icon(for: app) }
    }
}

/// Pick apps to add. Google TV can't list installed apps, so this offers a catalogue of popular
/// TV apps, plus a custom link for anything else.
struct AppPicker: View {
    @EnvironmentObject var s: Store
    @State private var query = ""
    @State private var showCustom = false
    @State private var name = ""
    @State private var link = ""

    var candidates: [TVApp] {
        AppCatalog.googleTV.filter { a in
            !s.displayedApps.contains { $0.id == a.id } && (query.isEmpty || a.name.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Apps.Picker.title).font(.headline)
            Text(L10n.Apps.Picker.explanation)
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                TextField(L10n.Apps.search, text: $query).textFieldStyle(.plain).font(.callout)
            }
            .padding(7).pill(RoundedRectangle(cornerRadius: 8))

            if candidates.isEmpty {
                Text(query.isEmpty ? L10n.Apps.Picker.allAdded : L10n.Apps.Picker.noMatch)
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(candidates) { app in
                            Button { withAnimation(.spring) { s.addCustomApp(name: app.name, id: app.id) } } label: {
                                VStack(spacing: 4) {
                                    AppIcon(app: app, tint: .gray)
                                    Text(app.name).font(.system(size: 9, weight: .medium)).lineLimit(1)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 4)
                            }
                            .buttonStyle(PressStyle())
                            .help(L10n.Apps.Picker.addApp(app.name))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .scrollIndicators(.never)
                .frame(height: 210)
            }

            DisclosureGroup(L10n.Apps.Picker.customLink, isExpanded: $showCustom) {
                VStack(spacing: 6) {
                    TextField(L10n.Common.name, text: $name)
                    TextField(L10n.Apps.Picker.linkPlaceholder, text: $link)
                    HStack {
                        Spacer()
                        Button(L10n.Common.add) {
                            s.addCustomApp(name: name, id: link)
                            name = ""; link = ""
                        }
                        .buttonStyle(.borderedProminent).disabled(name.isEmpty || link.isEmpty)
                    }
                }
                .textFieldStyle(.roundedBorder).padding(.top, 6)
            }
            .font(.callout)
        }
        .padding(14)
        .frame(width: 300)
    }
}
