import Combine
import SwiftUI
#if os(macOS)
import AppKit
public typealias PlatformColor = NSColor
#else
import GameController
import UIKit
public typealias PlatformColor = UIColor
#endif

/// The few places where macOS and iOS differ, kept in one file.
extension Color {
    init(platform c: PlatformColor) {
        #if os(macOS)
        self.init(nsColor: c)
        #else
        self.init(uiColor: c)
        #endif
    }
}

extension PlatformColor {
    convenience init?(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        let r = CGFloat(v >> 16 & 0xFF) / 255, g = CGFloat(v >> 8 & 0xFF) / 255, b = CGFloat(v & 0xFF) / 255
        #if os(macOS)
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
        #else
        self.init(red: r, green: g, blue: b, alpha: 1)
        #endif
    }

    /// The color in sRGB, so component reads are valid on both platforms.
    var srgb: PlatformColor {
        #if os(macOS)
        usingColorSpace(.sRGB) ?? self
        #else
        self
        #endif
    }

    var hex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        srgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

enum Haptics {
    @MainActor static func tap() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        #else
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

enum PlatformInfo {
    /// Keyboard shortcuts only matter with a hardware keyboard: always on Mac, and on iPhone or iPad
    /// only while one is connected.
    @MainActor static var showsKeyboardShortcuts: Bool {
        #if os(macOS)
        true
        #else
        GCKeyboard.coalesced != nil
        #endif
    }

    /// Fires when a hardware keyboard connects or disconnects (never on macOS).
    static var keyboardChanges: AnyPublisher<Void, Never> {
        #if os(macOS)
        Empty().eraseToAnyPublisher()
        #else
        NotificationCenter.default.publisher(for: .GCKeyboardDidConnect)
            .merge(with: NotificationCenter.default.publisher(for: .GCKeyboardDidDisconnect))
            .map { _ in () }
            .eraseToAnyPublisher()
        #endif
    }

    /// Features that only make sense in a Mac menu bar app (quit, login item, update check).
    static var isMac: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }
}
