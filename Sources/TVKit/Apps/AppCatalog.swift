import Foundation

/// Popular TV apps with their Android TV app links. Google TV can't report which apps are
/// installed over Remote v2, so users pick from this list; links for apps that aren't installed
/// simply don't open.
public enum AppCatalog {
    /// Shown by default on Google / Android TV.
    public static let featured: [TVApp] = [
        app("YouTube", "https://www.youtube.com"),
        app("Netflix", "https://www.netflix.com/title"),
        app("Prime Video", "https://app.primevideo.com"),
        app("Disney+", "https://www.disneyplus.com"),
        app("Spotify", "spotify://"),
        app("Max", "https://play.max.com"),
        app("Apple TV", "https://tv.apple.com"),
    ]

    /// Everything the picker offers, featured first.
    public static let googleTV: [TVApp] = featured + [
        app("YouTube Music", "https://music.youtube.com"),
        app("Hulu", "https://www.hulu.com"),
        app("Paramount+", "https://www.paramountplus.com"),
        app("Peacock", "https://www.peacocktv.com"),
        app("Twitch", "twitch://home"),
        app("Plex", "plex://"),
        app("Crunchyroll", "https://www.crunchyroll.com"),
        app("Tubi", "https://tubitv.com"),
        app("Pluto TV", "https://pluto.tv"),
        app("Sling TV", "https://watch.sling.com"),
        app("Discovery+", "https://www.discoveryplus.com"),
        app("Amazon Music", "https://music.amazon.com"),
        app("Apple Music", "https://music.apple.com"),
        app("TED", "https://www.ted.com"),
    ]

    private static func app(_ name: String, _ link: String) -> TVApp { TVApp(id: link, name: name) }
}
