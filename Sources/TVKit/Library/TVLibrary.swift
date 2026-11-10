import Foundation

/// Rules for saved TVs and their apps: ordering, favorites, renaming, recents, custom shortcuts.
/// A plain value type with no I/O, so every rule is unit-testable.
public struct TVLibrary: Equatable {
    /// Most recently used first.
    public private(set) var tvs: [KnownTV]

    public init(_ tvs: [KnownTV] = []) { self.tvs = tvs }

    // MARK: TVs

    /// Favorites first, then most recently used.
    public var sorted: [KnownTV] { tvs.filter { $0.favorite == true } + tvs.filter { $0.favorite != true } }

    /// The TV to connect to on launch: a favorite, else the last one used.
    public var autoConnectPick: KnownTV? { tvs.first { $0.favorite == true } ?? tvs.first }

    public func saved(_ id: String?) -> KnownTV? { tvs.first { $0.id == id } }
    public func isSaved(_ tv: TV) -> Bool { saved(tv.id) != nil }

    /// Discovered TVs that aren't saved yet.
    public func unsaved(_ found: [TV]) -> [TV] { found.filter { !isSaved($0) } }

    /// Marks a TV as just used, keeping its favorites/nickname/apps.
    public mutating func remember(_ tv: TV, at date: Date = .now) {
        var k = saved(tv.id) ?? KnownTV(tv: tv, lastUsed: date)
        k.tv = tv
        k.lastUsed = date
        tvs.removeAll { $0.id == tv.id }
        tvs.insert(k, at: 0)
    }

    /// A saved TV reappeared on a new IP (DHCP). Updates it and returns the old id, if any.
    public mutating func follow(_ tv: TV) -> String? {
        guard let i = tvs.firstIndex(where: { $0.tv.name == tv.name && $0.tv.kind == tv.kind && $0.tv.host != tv.host })
        else { return nil }
        let old = tvs[i].id
        tvs[i].tv = tv
        return old
    }

    public mutating func forget(_ id: String) { tvs.removeAll { $0.id == id } }
    public mutating func clear(keeping id: String?) { tvs.removeAll { $0.id != id } }
    public mutating func toggleFavorite(_ id: String) { update(id) { $0.favorite = !($0.favorite ?? false) } }

    public mutating func rename(_ id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        update(id) { $0.nickname = trimmed.isEmpty ? nil : trimmed }
    }

    // MARK: apps

    /// Custom shortcuts + the TV's apps, ordered favorites, then recent, then the rest.
    public func apps(for id: String?, tvApps: [TVApp]) -> [TVApp] {
        let k = saved(id)
        let custom = k?.customApps ?? []
        let all = custom + tvApps.filter { a in !custom.contains { $0.id == a.id } }
        let fav = k?.favoriteApps ?? [], recent = k?.recentApps ?? []
        func rank(_ a: TVApp) -> Int {
            if let i = fav.firstIndex(of: a.id) { return i }
            if let i = recent.firstIndex(of: a.id) { return 100 + i }
            return 1000
        }
        return all.enumerated().sorted { (rank($0.1), $0.0) < (rank($1.1), $1.0) }.map(\.1)
    }

    public func isFavoriteApp(_ app: TVApp, on id: String?) -> Bool { saved(id)?.favoriteApps?.contains(app.id) == true }
    public func isCustomApp(_ app: TVApp, on id: String?) -> Bool { saved(id)?.customApps?.contains(app) == true }

    public mutating func toggleFavoriteApp(_ app: TVApp, on id: String) {
        update(id) { k in
            var f = k.favoriteApps ?? []
            if let i = f.firstIndex(of: app.id) { f.remove(at: i) } else { f.append(app.id) }
            k.favoriteApps = f
        }
    }

    public mutating func addCustomApp(_ app: TVApp, on id: String) {
        guard !app.name.isEmpty, !app.id.isEmpty else { return }
        update(id) { $0.customApps = ($0.customApps ?? []) + [app] }
    }

    public mutating func removeCustomApp(_ app: TVApp, on id: String) { update(id) { $0.customApps?.removeAll { $0 == app } } }

    /// Keeps the 5 most recently launched apps.
    public mutating func recordLaunch(_ app: TVApp, on id: String) {
        update(id) { $0.recentApps = Array(([app.id] + ($0.recentApps ?? []).filter { $0 != app.id }).prefix(5)) }
    }

    private mutating func update(_ id: String, _ change: (inout KnownTV) -> Void) {
        guard let i = tvs.firstIndex(where: { $0.id == id }) else { return }
        change(&tvs[i])
    }
}
