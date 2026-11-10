import Foundation

/// Finds an icon for an app: the TV's own icon when it has one (Roku), otherwise the matching
/// app's artwork from Apple's public App Store lookup API. Only the app name/bundle id is sent.
public actor AppIconResolver {
    public static let shared = AppIconResolver()

    /// Store bundle ids for the built-in Google TV shortcuts, so lookups are exact.
    private let knownBundles = [
        "YouTube": "com.google.ios.youtube", "Netflix": "com.netflix.Netflix",
        "Prime Video": "com.amazon.aiv.AIVApp", "Disney+": "com.disney.disneyplus",
        "Spotify": "com.spotify.client", "Max": "com.wbd.stream", "Apple TV": "com.apple.tv",
    ]
    private let cacheKey = "appIconURLs"
    private let defaults: UserDefaults
    private var cache: [String: String]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        cache = defaults.dictionary(forKey: cacheKey) as? [String: String] ?? [:]
    }

    public func icon(for app: TVApp) async -> URL? {
        if let icon = app.icon { return icon }
        if let hit = cache[app.name] { return hit.isEmpty ? nil : URL(string: hit) }

        var query = URLComponents(string: "https://itunes.apple.com/lookup")!
        if let bundle = knownBundles[app.name] {
            query.queryItems = [.init(name: "bundleId", value: bundle)]
        } else {
            query.path = "/search"
            query.queryItems = [.init(name: "term", value: app.name), .init(name: "entity", value: "software"),
                                .init(name: "limit", value: "1")]
        }
        guard let url = query.url, let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        let found = Self.artwork(in: data)
        cache[app.name] = found?.absoluteString ?? "" // remember misses too
        defaults.set(cache, forKey: cacheKey)
        return found
    }

    static func artwork(in data: Data) -> URL? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let first = (json["results"] as? [[String: Any]])?.first,
              let art = first["artworkUrl512"] as? String ?? first["artworkUrl100"] as? String else { return nil }
        return URL(string: art)
    }
}
