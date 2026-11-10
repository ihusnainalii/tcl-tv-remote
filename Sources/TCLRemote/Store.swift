import AppKit
import Network
import SwiftUI

/// A TV we've connected to before.
struct KnownTV: Codable, Hashable, Identifiable {
    var tv: TV
    var lastUsed: Date
    var id: String { tv.id }
}

@MainActor
final class Store: ObservableObject {
    enum Screen: Equatable { case devices, pairing, remote }
    enum Link: Equatable { case idle, connecting, connected, needsPairing, failed }

    @Published var screen: Screen = .devices
    @Published var link: Link = .idle
    @Published var tv: TV?
    @Published var known: [KnownTV] = []     // most recent first
    @Published var found: [TV] = []
    @Published var scanning = false
    @Published var apps: [TVApp] = []
    @Published var toast: String?
    @Published var pairError = false
    @Published var tvOn: Bool?

    private var remote: TVRemote?
    private let discovery = Discovery()
    private let pathMonitor = NWPathMonitor()
    private let knownKey = "knownTVs"

    /// Found on the network but never connected.
    var newTVs: [TV] { found.filter { f in !known.contains { $0.tv.id == f.id } } }
    func isOnline(_ tv: TV) -> Bool { found.contains { $0.id == tv.id } }

    init() {
        if let d = UserDefaults.standard.data(forKey: knownKey),
           let list = try? JSONDecoder().decode([KnownTV].self, from: d) { known = list }

        // Auto-connect to the last TV that worked.
        if let last = known.first { select(last.tv) } else { scan() }

        // Reconnect when the Mac (re)joins a network.
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in
                guard let self, self.tv != nil, self.link != .connected, self.link != .connecting else { return }
                self.connect()
            }
        }
        pathMonitor.start(queue: .main)
    }

    func scan() {
        guard !scanning else { return }
        withAnimation(.snappy) { scanning = true }
        Task {
            await discovery.scan { [weak self] tv in
                guard let self else { return }
                self.followMovedTV(tv)
                guard !self.found.contains(tv) else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { self.found.append(tv) }
            }
            withAnimation(.snappy) { scanning = false }
        }
    }

    /// DHCP gave a remembered TV a new IP: same name + kind on another host → update and reconnect.
    private func followMovedTV(_ tv: TV) {
        guard let i = known.firstIndex(where: { $0.tv.name == tv.name && $0.tv.kind == tv.kind && $0.tv.host != tv.host })
        else { return }
        let wasCurrent = self.tv?.id == known[i].tv.id
        known[i].tv = tv
        save()
        if wasCurrent, link != .connected { select(tv) }
    }

    func select(_ tv: TV) {
        self.tv = tv
        remote = tv.kind == .roku ? RokuRemote(host: tv.host) : AndroidTVRemote(host: tv.host)
        (remote as? AndroidTVRemote)?.onPower = { [weak self] on in withAnimation { self?.tvOn = on } }
        apps = []; tvOn = nil
        go(.remote)
        connect()
    }

    func forget(_ k: KnownTV) {
        withAnimation(.spring) { known.removeAll { $0.id == k.id } }
        save()
        if tv?.id == k.id { tv = nil; remote = nil; withAnimation { link = .idle } }
    }

    func showDevices() { go(.devices); scan() }

    func connect() {
        guard let remote, let tv else { return }
        withAnimation(.smooth) { link = .connecting }
        Task {
            do {
                try await remote.connect()
                withAnimation(.smooth) { link = .connected }
                remember(tv)
                let list = await remote.apps()
                withAnimation(.spring) { apps = list }
            } catch {
                let isAndroid = remote is AndroidTVRemote
                // A remembered Google TV was paired before, so a failure means offline/moved, not unpaired.
                let wasPaired = known.contains { $0.id == tv.id }
                withAnimation(.smooth) { link = isAndroid && !wasPaired ? .needsPairing : .failed }
                if wasPaired { scan() } // maybe its IP changed
            }
        }
    }

    private func remember(_ tv: TV) {
        known.removeAll { $0.id == tv.id }
        known.insert(KnownTV(tv: tv, lastUsed: .now), at: 0)
        save()
    }

    private func save() { UserDefaults.standard.set(try? JSONEncoder().encode(known), forKey: knownKey) }

    // MARK: pairing (Google TV)

    func beginPairing() {
        guard let a = remote as? AndroidTVRemote else { return }
        go(.pairing)
        Task {
            do { try await a.startPairing() } catch { show("Pairing failed: \(error.localizedDescription)"); go(.remote) }
        }
    }

    func submitCode(_ code: String) {
        guard let a = remote as? AndroidTVRemote else { return }
        Task {
            do {
                try await a.finishPairing(code: code)
                show("Paired")
                go(.remote)
                connect()
            } catch {
                withAnimation(.default) { pairError.toggle() }
                show(error.localizedDescription)
            }
        }
    }

    func cancelPairing() { (remote as? AndroidTVRemote)?.cancelPairing(); go(.remote) }

    // MARK: commands

    func press(_ key: Key) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        run { try await $0.press(key) }
    }

    func type(_ text: String) { guard !text.isEmpty else { return }; run { try await $0.type(text) } }
    func launch(_ app: TVApp) { run { try await $0.launch(app) }; show("Opening \(app.name)…") }

    private func run(_ op: @escaping (TVRemote) async throws -> Void) {
        guard let remote else { return }
        Task {
            do {
                try await op(remote)
                if link != .connected, let tv { withAnimation(.smooth) { link = .connected }; remember(tv) }
            } catch {
                withAnimation(.smooth) { link = .failed }
                show(error.localizedDescription)
            }
        }
    }

    private func go(_ s: Screen) { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { screen = s } }

    func show(_ message: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if toast == message { withAnimation(.easeOut(duration: 0.3)) { toast = nil } }
        }
    }
}
