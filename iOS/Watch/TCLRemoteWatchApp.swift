import SwiftUI
import TVKit
import WatchKit

@main
struct TCLRemoteWatchApp: App {
    @StateObject private var session = WatchSession()

    var body: some Scene {
        WindowGroup { WatchRootView().environmentObject(session) }
    }
}

private let accent = LinearGradient(colors: [Color(red: 0.929, green: 0.11, blue: 0.141), Color(red: 0.7, green: 0.07, blue: 0.106)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)

/// Three pages, swiped vertically: D-pad (Digital Crown = volume), controls, apps.
struct WatchRootView: View {
    @EnvironmentObject var s: WatchSession

    var body: some View {
        NavigationStack {
            TabView {
                DPadPage()
                ControlsPage()
                AppsPage()
            }
            .tabViewStyle(.verticalPage)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Circle().fill(statusColor).frame(width: 8, height: 8).accessibilityLabel(s.link)
                }
            }
            .overlay(alignment: .bottom) {
                if let m = s.message {
                    Text(m).font(.footnote).multilineTextAlignment(.center)
                        .padding(8).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 4)
                        .transition(.opacity)
                }
            }
        }
    }

    var statusColor: Color {
        switch s.link {
        case "connected": .green
        case "connecting": .orange
        case "pairing": .yellow
        case "offline": .red
        default: .gray
        }
    }
}

/// D-pad with OK, Home and Back in the bottom corners; turning the Digital Crown changes the volume one step per notch.
private struct DPadPage: View {
    @EnvironmentObject var s: WatchSession
    @State private var crown = 0.0
    @State private var sent = 0.0

    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height * 0.86)
            ZStack {
                Circle().fill(.white.opacity(0.08))
                key(.up, "chevron.up").offset(y: -d * 0.32)
                key(.down, "chevron.down").offset(y: d * 0.32)
                key(.left, "chevron.left").offset(x: -d * 0.32)
                key(.right, "chevron.right").offset(x: d * 0.32)
                Button { s.press(.ok) } label: {
                    Text("OK").font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(width: d * 0.4, height: d * 0.4).background(accent, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(width: d, height: d)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Home and Back sit in the bottom corners, under the ring.
            .overlay(alignment: .bottom) {
                HStack {
                    corner(.home, "house.fill")
                    Spacer()
                    corner(.back, "arrow.uturn.backward")
                }
            }
        }
        .focusable()
        .digitalCrownRotation($crown, from: -1000, through: 1000, by: 1, sensitivity: .medium, isContinuous: true)
        .onChange(of: crown) { _, value in
            while value - sent >= 1 { s.press(.volUp); sent += 1 }
            while sent - value >= 1 { s.press(.volDown); sent -= 1 }
        }
    }

    func corner(_ k: Key, _ icon: String) -> some View {
        Button { s.press(k) } label: {
            Image(systemName: icon).font(.body.weight(.semibold)).frame(width: 40, height: 40)
                .background(.white.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(k.label)
    }

    func key(_ k: Key, _ icon: String) -> some View {
        Button { s.press(k) } label: {
            Image(systemName: icon).font(.title3.weight(.bold)).frame(width: 40, height: 40).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(k.label)
    }
}

private struct ControlsPage: View {
    @EnvironmentObject var s: WatchSession
    // Only the essentials, as big targets; Home and Back are also on the D-pad page, volume on the Crown.
    private let items: [(Key, String)] = [(.back, "arrow.uturn.backward"), (.playPause, "playpause.fill"),
                                          (.mute, "speaker.slash.fill"), (.power, "power"),
                                          (.volDown, "speaker.minus.fill"), (.volUp, "speaker.plus.fill")]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            ForEach(items, id: \.0) { k, icon in
                Button { s.press(k) } label: {
                    Image(systemName: icon).font(.title3.weight(.semibold))
                        .foregroundStyle(k == .power ? .red : .primary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(k.label)
            }
        }
    }
}

private struct AppsPage: View {
    @EnvironmentObject var s: WatchSession

    var body: some View {
        List {
            if s.apps.isEmpty {
                Text("Open TCL Remote on your iPhone to load your apps.").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(s.apps) { app in
                Button(app.name) { s.launch(app) }
            }
        }
    }
}
