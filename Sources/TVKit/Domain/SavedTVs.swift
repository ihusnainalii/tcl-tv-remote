import Foundation

/// Saved TVs, persisted locally in UserDefaults (never leaves the Mac).
public enum SavedTVs {
    private static let key = "knownTVs"

    public static func load(_ defaults: UserDefaults = .standard) -> [KnownTV] {
        guard let d = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([KnownTV].self, from: d)) ?? []
    }

    public static func save(_ tvs: [KnownTV], _ defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(tvs), forKey: key)
    }
}
