import AppKit
import SwiftUI
import TVKit

/// Presentation state for the panel. Coordinates TVKit (drivers, library, discovery) and the
/// system services; the rules themselves live in TVKit and are unit-tested there.
@MainActor
final class Store: ObservableObject {
    enum Screen: Equatable { case devices, pairing, remote }
    enum Link: Equatable { case idle, connecting, connected, needsPairing, failed }

    @Published private(set) var screen: Screen = .devices
    @Published private(set) var link: Link = .idle
    @Published private(set) var tv: TV?
    @Published private(set) var library: TVLibrary
    @Published private(set) var found: [TV] = []
    @Published private(set) var scanning = false
    @Published private(set) var apps: [TVApp] = []
    @Published private(set) var toast: String?
    @Published private(set) var pairError = false
    @Published private(set) var tvOn: Bool?
    @Published private(set) var volume: TVVolume?
    @Published private(set) var launchAtLogin = LoginItem.isEnabled

    private let repository: TVRepository
    private let discovery = Discovery()
    private var monitor: ConnectivityMonitor?
    private var remote: TVRemote?
    private var stepper: VolumeStepper?
    private var failures = 0
    private var retryTask: Task<Void, Never>?
    private var lastVolumeChange = Date.distantPast

    init(repository: TVRepository = UserDefaultsTVRepository()) {
        self.repository = repository
        library = TVLibrary(repository.load())
        SystemNotifications.requestAccess()

        if Preferences.autoConnect, let pick = library.autoConnectPick { select(pick.tv) } else { scan() }

        monitor = ConnectivityMonitor { [weak self] in
            guard let self, self.tv != nil, self.link != .connected, self.link != .connecting else { return }
            self.connect()
        }
    }

    // MARK: derived state for views

    var known: [KnownTV] { library.tvs }
    var sortedKnown: [KnownTV] { library.sorted }
    var current: KnownTV? { library.saved(tv?.id) }
    var displayName: String { current?.name ?? tv?.name ?? "TCL Remote" }
    var newTVs: [TV] { library.unsaved(found) }
    func isOnline(_ tv: TV) -> Bool { found.contains { $0.id == tv.id } }
    var displayedApps: [TVApp] { library.apps(for: tv?.id, tvApps: apps) }
    func isFavorite(_ app: TVApp) -> Bool { library.isFavoriteApp(app, on: tv?.id) }
    func isCustom(_ app: TVApp) -> Bool { library.isCustomApp(app, on: tv?.id) }

    // MARK: discovery

    func scan() {
        guard !scanning else { return }
        withAnimation(.snappy) { scanning = true }
        Task {
            await discovery.scan { [weak self] tv in self?.discovered(tv) }
            withAnimation(.snappy) { scanning = false }
        }
    }

    private func discovered(_ tv: TV) {
        if let oldID = library.follow(tv) {
            persist()
            if self.tv?.id == oldID, link != .connected { select(tv) }
        }
        guard !found.contains(tv) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { found.append(tv) }
    }

    func showDevices() { go(.devices); scan() }

    // MARK: connection

    func select(_ tv: TV) {
        retryTask?.cancel()
        self.tv = tv
        let r = RemoteFactory.make(for: tv)
        remote = r
        stepper = VolumeStepper { [weak r] key in try await r?.press(key) }
        if let reporting = r as? StateReporting { observe(reporting) }
        apps = []; tvOn = nil; volume = nil; failures = 0
        go(.remote)
        connect()
    }

    private func observe(_ r: StateReporting) {
        r.onPower = { [weak self] on in withAnimation { self?.tvOn = on } }
        r.onVolume = { [weak self] v in
            // The TV reports lag behind the slider; ignore them briefly so the bar doesn't jump back.
            guard let self, self.stepper?.isActive != true, Date().timeIntervalSince(self.lastVolumeChange) > 1 else { return }
            withAnimation(.smooth) { self.volume = v }
        }
        r.onDisconnect = { [weak self] in
            guard let self, self.link == .connected else { return }
            withAnimation(.smooth) { self.link = .failed }
            SystemNotifications.post("TV disconnected", "\(self.displayName) dropped the connection. Retrying…")
            self.scheduleRetry()
        }
    }

    func connect() {
        guard let remote, let tv else { return }
        withAnimation(.smooth) { link = .connecting }
        Task {
            do {
                try await remote.connect()
                withAnimation(.smooth) { link = .connected }
                if failures > 0 { show("Reconnected"); SystemNotifications.post("Reconnected", "\(displayName) is back.") }
                failures = 0
                update { $0.remember(tv) }
                let list = await remote.apps()
                withAnimation(.spring) { apps = list }
            } catch {
                // A saved TV was paired before, so failing means offline or moved, not unpaired.
                let needsPairing = remote is PairingCapable && !library.isSaved(tv)
                withAnimation(.smooth) { link = needsPairing ? .needsPairing : .failed }
                if failures == 0 { SystemNotifications.post(needsPairing ? "Pairing required" : "TV unavailable", displayName) }
                failures += 1
                if needsPairing { return }
                if failures == 1 { scan() } // maybe its IP changed
                scheduleRetry()
            }
        }
    }

    /// ponytail: fixed-interval retry (Settings) while offline; add backoff if battery use shows up.
    private func scheduleRetry() {
        retryTask?.cancel()
        let id = tv?.id
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Preferences.retrySeconds))
            guard let self, !Task.isCancelled, self.tv?.id == id, self.link == .failed else { return }
            self.connect()
        }
    }

    // MARK: pairing

    func beginPairing() {
        guard let p = remote as? PairingCapable else { return }
        go(.pairing)
        Task {
            do { try await p.startPairing() } catch { show("Pairing failed: \(error.localizedDescription)"); go(.remote) }
        }
    }

    func submitCode(_ code: String) {
        guard let p = remote as? PairingCapable else { return }
        Task {
            do {
                try await p.finishPairing(code: code)
                show("Paired")
                SystemNotifications.post("Paired", "\(displayName) is ready to control.")
                go(.remote)
                connect()
            } catch {
                withAnimation(.default) { pairError.toggle() }
                show(error.localizedDescription)
            }
        }
    }

    func cancelPairing() { (remote as? PairingCapable)?.cancelPairing(); go(.remote) }

    func resetPairing() {
        ClientIdentity.reset()
        show("Pairing reset. Google TVs will ask for a new code.")
        if remote is PairingCapable { withAnimation(.smooth) { link = .needsPairing } }
    }

    // MARK: saved TVs & apps

    func forget(_ k: KnownTV) {
        update { $0.forget(k.id) }
        if tv?.id == k.id { tv = nil; remote = nil; withAnimation { link = .idle } }
    }

    func clearHistory() { update { $0.clear(keeping: tv?.id) } }
    func toggleFavorite(_ k: KnownTV) { update { $0.toggleFavorite(k.id) } }
    func rename(_ k: KnownTV, _ name: String) { update { $0.rename(k.id, to: name) } }

    func toggleFavorite(_ app: TVApp) { guard let id = tv?.id else { return }; update { $0.toggleFavoriteApp(app, on: id) } }
    func removeCustomApp(_ app: TVApp) { guard let id = tv?.id else { return }; update { $0.removeCustomApp(app, on: id) } }
    func addCustomApp(name: String, id appID: String) {
        guard let id = tv?.id else { return }
        update { $0.addCustomApp(TVApp(id: appID, name: name), on: id) }
    }

    private func update(_ change: (inout TVLibrary) -> Void) {
        withAnimation(.spring) { change(&library) }
        persist()
    }

    private func persist() { repository.save(library.tvs) }

    // MARK: commands

    func press(_ key: Key) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        run { try await $0.press(key) }
    }

    func type(_ text: String) { guard !text.isEmpty else { return }; run { try await $0.type(text) } }

    func launch(_ app: TVApp) {
        run { try await $0.launch(app) }
        show("Opening \(app.name)…")
        if let id = tv?.id { update { $0.recordLaunch(app, on: id) } }
    }

    func setVolume(_ level: Int) {
        guard let v = volume, let stepper else { return }
        let target = max(0, min(v.max, level))
        volume?.level = target // optimistic; the TV's own report confirms it afterwards
        lastVolumeChange = .now
        stepper.move(from: v.level, to: target)
    }

    func nudgeVolume(_ delta: Int) { setVolume((stepper?.target ?? volume?.level ?? 0) + delta) }

    func setLaunchAtLogin(_ on: Bool) {
        do { try LoginItem.set(on) } catch { show("Couldn't change login item: \(error.localizedDescription)") }
        launchAtLogin = LoginItem.isEnabled
    }

    private func run(_ op: @escaping (TVRemote) async throws -> Void) {
        guard let remote else { return }
        Task {
            do {
                try await op(remote)
                if link != .connected, let tv { withAnimation(.smooth) { link = .connected }; update { $0.remember(tv) } }
            } catch TVError.unsupported(let name) {
                show("\(name) isn't available on this TV")
            } catch {
                withAnimation(.smooth) { link = .failed }
                show(error.localizedDescription)
                scheduleRetry()
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
