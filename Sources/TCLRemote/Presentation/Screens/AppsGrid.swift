import SwiftUI
import TVKit

struct AppsGrid: View {
    @EnvironmentObject var s: Store
    @State private var shown = false
    @State private var query = ""
    @State private var adding = false
    @State private var newName = ""
    @State private var newID = ""

    var apps: [TVApp] {
        query.isEmpty ? s.displayedApps : s.displayedApps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 8) {
            if s.displayedApps.count > 9 {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                    TextField("Search apps", text: $query).textFieldStyle(.plain).font(.caption)
                }
                .padding(7).pill(RoundedRectangle(cornerRadius: 8))
            }
            if s.link != .connected && s.displayedApps.isEmpty {
                Text("Connect to see apps").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { i, app in
                            tile(app)
                                .scaleEffect(shown ? 1 : 0.6).opacity(shown ? 1 : 0)
                                .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(Double(min(i, 12)) * 0.03), value: shown)
                        }
                        if query.isEmpty { addTile }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: apps)
                }
                .frame(maxHeight: 170)
            }
        }
        .onAppear { shown = true }
    }

    func tile(_ app: TVApp) -> some View {
        Button { s.launch(app) } label: {
            VStack(spacing: 5) {
                Text(String(app.name.prefix(1)))
                    .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint(app.name).gradient, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                        if s.isFavorite(app) {
                            Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(.yellow)
                                .padding(3).background(.regularMaterial, in: Circle()).offset(x: 5, y: -5)
                                .transition(.scale)
                        }
                    }
                Text(app.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 6)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Open \(app.name)")
        .contextMenu {
            Button(s.isFavorite(app) ? "Remove from Favorites" : "Add to Favorites") { s.toggleFavorite(app) }
            if s.isCustom(app) { Button("Remove Shortcut", role: .destructive) { s.removeCustomApp(app) } }
        }
    }

    var addTile: some View {
        Button { adding = true } label: {
            VStack(spacing: 5) {
                Image(systemName: "plus").font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3])))
                    .foregroundStyle(.secondary)
                Text("Shortcut").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 6)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Add app shortcut")
        .popover(isPresented: $adding, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("New shortcut").font(.headline)
                TextField("Name", text: $newName)
                TextField(s.tv?.kind == .roku ? "Roku app ID, e.g. 12" : "App link, e.g. https://www.twitch.tv", text: $newID)
                HStack {
                    Spacer()
                    Button("Cancel") { adding = false }
                    Button("Add") {
                        s.addCustomApp(name: newName, id: newID)
                        newName = ""; newID = ""; adding = false
                    }
                    .buttonStyle(.borderedProminent).disabled(newName.isEmpty || newID.isEmpty)
                }
            }
            .textFieldStyle(.roundedBorder).padding(14).frame(width: 260)
        }
    }

    func tint(_ name: String) -> Color {
        let known: [String: Color] = ["Netflix": .red, "YouTube": .red, "Spotify": .green, "Prime Video": .cyan,
                                      "Disney+": .blue, "Max": .indigo, "Hulu": .green, "Plex": .orange, "Apple TV": .gray]
        if let c = known[name] { return c }
        let palette: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo, .mint]
        return palette[abs(name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }) % palette.count]
    }
}
