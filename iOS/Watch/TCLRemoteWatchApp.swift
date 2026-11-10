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

private let accent = LinearGradient(colors: [Color(red: 0.38, green: 0.45, blue: 1), Color(red: 0.66, green: 0.36, blue: 1)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing)

/// Three pages, swiped vertically: D-pad (Digital Crown = volume), controls, apps.
struct WatchRootView: View {
    @EnvironmentObject var s: WatchSession

    var body: some View {
        NavigationStack {
            TabView {
                DPadPage().navigationTitle(s.name)
                ControlsPage().navigationTitle(s.name)
                AppsPage().navigationTitle(s.name)
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

/// D-pad with OK; turning the Digital Crown changes the volume one step per notch.
private struct DPadPage: View {
    @EnvironmentObject var s: WatchSession
    @State private var crown = 0.0
    @State private var sent = 0.0

    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            ZStack {
                Circle().fill(.white.opacity(0.08))
                key(.up, "chevron.up").offset(y: -d * 0.32)
                key(.down, "chevron.down").offset(y: d * 0.32)
                key(.left, "chevron.left").offset(x: -d * 0.32)
                key(.right, "chevron.right").offset(x: d * 0.32)
                Button { s.press(.ok) } label: {
                    Text("OK").font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(width: d * 0.38, height: d * 0.38).background(accent, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .frame(width: d, height: d)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .digitalCrownRotation($crown, from: -1000, through: 1000, by: 1, sensitivity: .medium, isContinuous: true)
        .onChange(of: crown) { _, value in
            while value - sent >= 1 { s.press(.volUp); sent += 1 }
            while sent - value >= 1 { s.press(.volDown); sent -= 1 }
        }
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
    private let items: [(Key, String)] = [(.back, "arrow.uturn.backward"), (.home, "house.fill"), (.playPause, "playpause.fill"),
                                          (.volDown, "speaker.minus.fill"), (.mute, "speaker.slash.fill"), (.volUp, "speaker.plus.fill"),
                                          (.chDown, "chevron.down"), (.power, "power"), (.chUp, "chevron.up")]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(items, id: \.0) { k, icon in
                Button { s.press(k) } label: {
                    Image(systemName: icon).font(.body.weight(.semibold))
                        .foregroundStyle(k == .power ? .red : .primary)
                        .frame(maxWidth: .infinity, minHeight: 40)
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
