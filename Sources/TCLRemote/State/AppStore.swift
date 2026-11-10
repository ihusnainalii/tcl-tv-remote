import AppKit
import Network
import ServiceManagement
import SwiftUI
import TVKit
import UserNotifications

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
    @Published var volume: Volume?
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled

    struct Volume: Equatable { var level: Int, max: Int, muted: Bool }

    private var remote: TVRemote?
    private let discovery = Discovery()
    private let pathMonitor = NWPathMonitor()
    private var failures = 0
    private var volumeTarget: Int?
    private var volumeTask: Task<Void, Never>?
    private var sentLevel = 0
    private var retryTask: Task<Void, Never>?

    /// Found on the network but never connected.
    var newTVs: [TV] { found.filter { f in !known.contains { $0.tv.id == f.id } } }
    func isOnline(_ tv: TV) -> Bool { found.contains { $0.id == tv.id } }

    init() {
        known = SavedTVs.load()

        // Auto-connect to the favorite TV, else the last one that worked.
        let auto = UserDefaults.standard.object(forKey: "autoConnect") as? Bool ?? true
        if auto, let pick = known.first(where: { $0.favorite == true }) ?? known.first { select(pick.tv) } else { scan() }

        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }

        // Reconnect when the Mac (re)joins a network.
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in
                guard let self, self.tv != nil, self.link != .connected, self.link != .connecting else { return }
                self.connect()
            }
        }
        pathMonitor.start(queue: .main)

        // Reconnect after the Mac wakes from sleep.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2)) // let Wi-Fi come back first
                if let self, self.tv != nil, self.link != .connected { self.connect() }
            }
        }
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch { show("Couldn't change login item: \(error.localizedDescription)") }
        launchAtLogin = SMAppService.mainApp.status == .enabled
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
        if let a = remote as? AndroidTVRemote {
            a.onPower = { [weak self] on in withAnimation { self?.tvOn = on } }
            a.onVolume = { [weak self] l, m, muted in
                guard let self, self.volumeTask == nil else { return } // don't fight the slider mid-drag
                withAnimation(.smooth) { self.volume = Volume(level: l, max: m, muted: muted) }
            }
            a.onDisconnect = { [weak self] in
                guard let self, self.link == .connected else { return }
                withAnimation(.smooth) { self.link = .failed }
                self.notify("TV disconnected", "\(self.displayName) dropped the connection. Retrying…")
                self.scheduleRetry()
            }
        }
        apps = []; tvOn = nil; volume = nil; failures = 0; retryTask?.cancel()
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
                if failures > 0 { show("Reconnected"); notify("Reconnected", "\(displayName) is back.") }
                failures = 0
                remember(tv)
                let list = await remote.apps()
                withAnimation(.spring) { apps = list }
            } catch {
                let isAndroid = remote is AndroidTVRemote
                // A remembered Google TV was paired before, so a failure means offline/moved, not unpaired.
                let wasPaired = known.contains { $0.id == tv.id }
                withAnimation(.smooth) { link = isAndroid && !wasPaired ? .needsPairing : .failed }
                if failures == 0 { notify(isAndroid && !wasPaired ? "Pairing required" : "TV unavailable", displayName) }
                failures += 1
                if wasPaired && failures == 1 { scan() } // maybe its IP changed
                if isAndroid && !wasPaired { return }
                scheduleRetry()
            }
        }
    }

    /// ponytail: fixed-interval retry (Settings) while offline; add backoff if battery use shows up.
    private func scheduleRetry() {
        retryTask?.cancel()
        let id = tv?.id
        retryTask = Task { [weak self] in
            let secs = UserDefaults.standard.object(forKey: "retrySeconds") as? Double ?? 10
            try? await Task.sleep(for: .seconds(secs))
            guard let self, !Task.isCancelled, self.tv?.id == id, self.link == .failed else { return }
            self.connect()
        }
    }

    private func remember(_ tv: TV) {
        var k = known.first { $0.id == tv.id } ?? KnownTV(tv: tv, lastUsed: .now)
        k.tv = tv; k.lastUsed = .now
        known.removeAll { $0.id == tv.id }
        known.insert(k, at: 0)
        save()
    }

    // MARK: saved TVs

    var current: KnownTV? { known.first { $0.id == tv?.id } }
    var displayName: String { current?.name ?? tv?.name ?? "TCL Remote" }
    /// Favorites first, then most recently used.
    var sortedKnown: [KnownTV] { known.filter { $0.favorite == true } + known.filter { $0.favorite != true } }

    private func update(_ id: String, _ change: (inout KnownTV) -> Void) {
        guard let i = known.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring) { change(&known[i]) }
        save()
    }

    func toggleFavorite(_ k: KnownTV) { update(k.id) { $0.favorite = !($0.favorite ?? false) } }
    func rename(_ k: KnownTV, _ name: String) {
        update(k.id) { $0.nickname = name.trimmingCharacters(in: .whitespaces).isEmpty ? nil : name }
    }

    func clearHistory() {
        withAnimation(.spring) { known.removeAll { $0.id != tv?.id } }
        save()
    }

    func resetPairing() {
        ClientIdentity.reset()
        show("Pairing reset. Google TVs will ask for a new code.")
        if tv?.kind == .androidTV { withAnimation(.smooth) { link = .needsPairing } }
    }

    // MARK: apps

    /// Custom shortcuts + TV apps, ordered favorites, then recent, then the rest.
    var displayedApps: [TVApp] {
        let all = (current?.customApps ?? []) + apps.filter { a in !(current?.customApps ?? []).contains { $0.id == a.id } }
        let fav = current?.favoriteApps ?? [], recent = current?.recentApps ?? []
        func rank(_ a: TVApp) -> Int {
            if let i = fav.firstIndex(of: a.id) { return i }
            if let i = recent.firstIndex(of: a.id) { return 100 + i }
            return 1000
        }
        return all.enumerated().sorted { (rank($0.1), $0.0) < (rank($1.1), $1.0) }.map(\.1)
    }

    func isFavorite(_ app: TVApp) -> Bool { current?.favoriteApps?.contains(app.id) == true }
    func isCustom(_ app: TVApp) -> Bool { current?.customApps?.contains(app) == true }

    func toggleFavorite(_ app: TVApp) {
        guard let id = current?.id else { return }
        update(id) { k in
            var f = k.favoriteApps ?? []
            if let i = f.firstIndex(of: app.id) { f.remove(at: i) } else { f.append(app.id) }
            k.favoriteApps = f
        }
    }

    func addCustomApp(name: String, id appID: String) {
        guard let id = current?.id, !name.isEmpty, !appID.isEmpty else { return }
        update(id) { $0.customApps = ($0.customApps ?? []) + [TVApp(id: appID, name: name)] }
    }

    func removeCustomApp(_ app: TVApp) {
        guard let id = current?.id else { return }
        update(id) { $0.customApps?.removeAll { $0 == app } }
    }

    // MARK: notifications

    func notify(_ title: String, _ body: String) {
        guard UserDefaults.standard.object(forKey: "notify") as? Bool ?? true, Bundle.main.bundleIdentifier != nil else { return }
        let c = UNMutableNotificationContent()
        c.title = title; c.body = body
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    private func save() { SavedTVs.save(known) }

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
                notify("Paired", "\(displayName) is ready to control.")
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

    /// Android TV Remote v2 has no "set volume" command, so walk there with volume up/down steps.
    func setVolume(_ level: Int) {
        guard let v = volume, let a = remote as? AndroidTVRemote else { return }
        let target = max(0, min(v.max, level))
        if volumeTask == nil { sentLevel = v.level }
        volumeTarget = target
        volume?.level = target // optimistic; the TV's own report confirms it afterwards
        guard volumeTask == nil else { return }
        volumeTask = Task { [weak self] in
            while let self, let t = self.volumeTarget, t != self.sentLevel {
                let up = t > self.sentLevel
                try? await a.press(up ? .volUp : .volDown)
                self.sentLevel += up ? 1 : -1
                try? await Task.sleep(for: .milliseconds(35))
            }
            self?.volumeTask = nil
            self?.volumeTarget = nil
        }
    }

    func nudgeVolume(_ delta: Int) { setVolume((volumeTarget ?? volume?.level ?? 0) + delta) }

    func press(_ key: Key) {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        run { try await $0.press(key) }
    }

    func type(_ text: String) { guard !text.isEmpty else { return }; run { try await $0.type(text) } }
    func launch(_ app: TVApp) {
        run { try await $0.launch(app) }
        show("Opening \(app.name)…")
        if let id = current?.id {
            update(id) { $0.recentApps = Array(([app.id] + ($0.recentApps ?? []).filter { $0 != app.id }).prefix(5)) }
        }
    }

    private func run(_ op: @escaping (TVRemote) async throws -> Void) {
        guard let remote else { return }
        Task {
            do {
                try await op(remote)
                if link != .connected, let tv { withAnimation(.smooth) { link = .connected }; remember(tv) }
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
