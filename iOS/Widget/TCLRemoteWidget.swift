import SwiftUI
import WidgetKit

/// Home Screen widget for iPhone and iPad: one-tap remote buttons. Each button opens the app with a
/// `tclremote://key/<key>` link, and the app sends that key to the current TV.
@main
struct TCLRemoteWidgetBundle: WidgetBundle {
    var body: some Widget { RemoteWidget() }
}

struct RemoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TCLRemoteWidget", provider: Provider()) { _ in
            RemoteWidgetView().containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("TCL Remote")
        .description("Power, home, playback and volume for your TCL TV.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Entry: TimelineEntry { let date: Date }

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: .now)], policy: .never))
    }
}

private let accent = LinearGradient(colors: [Color(red: 0.38, green: 0.45, blue: 1), Color(red: 0.66, green: 0.36, blue: 1)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)

struct RemoteWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) {
                header.frame(maxWidth: .infinity, alignment: .leading)
                grid([("power", "power"), ("home", "house.fill"), ("playPause", "playpause.fill"),
                      ("volDown", "speaker.minus.fill"), ("mute", "speaker.slash.fill"), ("volUp", "speaker.plus.fill")], columns: 3)
            }
        default:
            VStack(alignment: .leading, spacing: 10) {
                header
                grid([("power", "power"), ("home", "house.fill"), ("playPause", "playpause.fill"), ("mute", "speaker.slash.fill")],
                     columns: 2)
            }
        }
    }

    private var header: some View {
        Link(destination: URL(string: "tclremote://open")!) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "tv").font(.title3.weight(.semibold)).foregroundStyle(.white)
                    .frame(width: 36, height: 36).background(accent, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                if family == .systemMedium {
                    Text("TCL Remote").font(.headline)
                    Text("Tap a button to control your TV").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func grid(_ keys: [(String, String)], columns: Int) -> some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(0..<(keys.count / columns), id: \.self) { row in
                GridRow {
                    ForEach(keys[(row * columns)..<(row * columns + columns)], id: \.0) { key, icon in
                        Link(destination: URL(string: "tclremote://key/\(key)")!) {
                            Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(key == "power" ? .red : .primary)
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }
        }
    }
}
