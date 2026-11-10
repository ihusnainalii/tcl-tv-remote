import Foundation

/// Where saved TVs live. Swappable so the library logic can be tested without UserDefaults.
public protocol TVRepository {
    func load() -> [KnownTV]
    func save(_ tvs: [KnownTV])
}

/// Saved TVs in UserDefaults, local to this Mac.
public struct UserDefaultsTVRepository: TVRepository {
    private let defaults: UserDefaults
    private let key = "knownTVs"

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() -> [KnownTV] {
        guard let d = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([KnownTV].self, from: d)) ?? []
    }

    public func save(_ tvs: [KnownTV]) { defaults.set(try? JSONEncoder().encode(tvs), forKey: key) }
}
