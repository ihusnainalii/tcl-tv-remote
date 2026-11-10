import AppKit
import SwiftUI

/// Accent color presets for the remote, plus a user-picked custom color.
enum AccentStyle: String, CaseIterable, Identifiable {
    case violet, ocean, sunset, forest, rose, tclRed, graphite, custom

    static let key = "accentStyle"
    static let customKey = "accentCustom"
    static var current: AccentStyle { AccentStyle(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .violet }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .violet: "Violet"; case .ocean: "Ocean"; case .sunset: "Sunset"; case .forest: "Forest"
        case .rose: "Rose"; case .tclRed: "TCL Red"; case .graphite: "Graphite"; case .custom: "Custom"
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
        case .tclRed: return (rgb(0.93, 0.13, 0.2), rgb(0.66, 0.05, 0.16))
        case .graphite: return (rgb(0.5, 0.52, 0.57), rgb(0.27, 0.29, 0.34))
        case .custom: return Self.gradient(from: Self.customColor)
        }
    }

    /// The custom color as stored hex (#RRGGBB).
    static var customColor: NSColor {
        NSColor(hex: UserDefaults.standard.string(forKey: customKey) ?? "") ?? NSColor(red: 0.42, green: 0.36, blue: 0.91, alpha: 1)
    }

    /// One picked color becomes a gentle gradient: same color to a slightly shifted, deeper hue.
    static func gradient(from c: NSColor) -> (Color, Color) {
        let rgb = c.usingColorSpace(.sRGB) ?? c
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let end = NSColor(hue: (h + 0.07).truncatingRemainder(dividingBy: 1), saturation: min(1, s * 1.05), brightness: b * 0.85, alpha: 1)
        return (Color(nsColor: rgb), Color(nsColor: end))
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    static let key = "appearanceMode"
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    static let changed = Notification.Name("TCLRemoteAppearanceChanged")

    static var current: AppearanceMode { AppearanceMode(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    /// Sets the app appearance and tells the popover, which otherwise follows the menu bar, not the app.
    static func apply() {
        NSApp.appearance = current.nsAppearance
        NotificationCenter.default.post(name: changed, object: nil)
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    var hex: String {
        let c = usingColorSpace(.sRGB) ?? self
        return String(format: "#%02X%02X%02X", Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
    }
}

extension View {
    /// Rebuilds the view tree when the accent changes, since Theme reads it statically.
    func themed() -> some View { modifier(Themed()) }
}

private struct Themed: ViewModifier {
    @AppStorage(AccentStyle.key) private var style = AccentStyle.violet.rawValue
    @AppStorage(AccentStyle.customKey) private var custom = ""
    func body(content: Content) -> some View {
        content.id(style + custom).tint(AccentStyle.current.colors.0)
    }
}
