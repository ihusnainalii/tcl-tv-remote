import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Accent color presets for the remote, plus a user-picked custom color.
enum AccentStyle: String, CaseIterable, Identifiable {
    case tclRed, violet, ocean, sunset, forest, rose, graphite, custom

    static let key = "accentStyle"
    static let customKey = "accentCustom"
    /// TCL red unless the user picked another accent.
    static var current: AccentStyle { AccentStyle(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .tclRed }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .violet: L10n.Theme.violet; case .ocean: L10n.Theme.ocean; case .sunset: L10n.Theme.sunset
        case .forest: L10n.Theme.forest; case .rose: L10n.Theme.rose; case .tclRed: L10n.Theme.tclRed
        case .graphite: L10n.Theme.graphite; case .custom: L10n.Theme.custom
        }
    }

    var colors: (Color, Color) {
        func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r, green: g, blue: b) }
        switch self {
        case .violet: return (rgb(0.38, 0.45, 1), rgb(0.66, 0.36, 1))
        case .ocean: return (rgb(0.0, 0.55, 1), rgb(0.0, 0.8, 0.78))
        case .sunset: return (rgb(1, 0.5, 0.25), rgb(1, 0.24, 0.5))
        case .forest: return (rgb(0.22, 0.74, 0.42), rgb(0.04, 0.52, 0.5))
        case .rose: return (rgb(1, 0.36, 0.58), rgb(0.72, 0.32, 1))
        case .tclRed: return (rgb(0.929, 0.11, 0.141), rgb(0.7, 0.07, 0.106)) // #ED1C24, TCL's logo red
        case .graphite: return (rgb(0.5, 0.52, 0.57), rgb(0.27, 0.29, 0.34))
        case .custom: return Self.gradient(from: Self.customColor)
        }
    }

    /// The custom color as stored hex (#RRGGBB).
    static var customColor: PlatformColor {
        PlatformColor(hex: UserDefaults.standard.string(forKey: customKey) ?? "") ?? PlatformColor(hex: "#6B5CE8")!
    }

    /// One picked color becomes a gentle gradient: same color to a slightly shifted, deeper hue.
    static func gradient(from c: PlatformColor) -> (Color, Color) {
        let rgb = c.srgb
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let end = PlatformColor(hue: (h + 0.07).truncatingRemainder(dividingBy: 1), saturation: min(1, s * 1.05),
                                brightness: b * 0.85, alpha: 1)
        return (Color(platform: rgb), Color(platform: end))
    }
}

public enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    static let key = "appearanceMode"
    public var id: String { rawValue }
    var title: String {
        switch self {
        case .system: L10n.Appearance.system
        case .light: L10n.Appearance.light
        case .dark: L10n.Appearance.dark
        }
    }

    public static let changed = Notification.Name("TCLRemoteAppearanceChanged")

    public static var current: AppearanceMode { AppearanceMode(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system }

    /// For SwiftUI's preferredColorScheme (iOS); nil follows the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    #if os(macOS)
    public var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    #endif

    /// Sets the app appearance and tells the popover, which otherwise follows the menu bar, not the app.
    /// On iOS the root view applies `colorScheme` itself.
    public static func apply() {
        #if os(macOS)
        NSApp.appearance = current.nsAppearance
        #endif
        NotificationCenter.default.post(name: changed, object: nil)
    }
}

extension View {
    /// Rebuilds the view tree when the accent changes, since Theme reads it statically.
    func themed() -> some View { modifier(Themed()) }
}

private struct Themed: ViewModifier {
    @AppStorage(AccentStyle.key) private var style = AccentStyle.violet.rawValue
    @AppStorage(AccentStyle.customKey) private var custom = ""
    @AppStorage(AppearanceMode.key) private var mode = AppearanceMode.system.rawValue
    func body(content: Content) -> some View {
        content.id(style + custom).tint(AccentStyle.current.colors.0)
            .preferredColorScheme(PlatformInfo.isMac ? nil : AppearanceMode(rawValue: mode)?.colorScheme)
    }
}
