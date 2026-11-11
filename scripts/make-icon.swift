// Renders the app icon: white TV symbol on the violet accent gradient.
// Usage: swift scripts/make-icon.swift
//   -> docs/icon.png (README), Resources/AppIcon.icns (Mac), iOS/App/Assets.xcassets/AppIcon.appiconset (iOS)
import AppKit

func render(_ size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // macOS icon grid: ~80% body with a soft drop shadow.
    let inset = size * 0.1, body = NSRect(x: inset, y: inset * 1.15, width: size - inset * 2, height: size - inset * 2)
    let path = NSBezierPath(roundedRect: body, xRadius: body.width * 0.225, yRadius: body.width * 0.225)
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = size * 0.03
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.012)
    NSGraphicsContext.saveGraphicsState(); shadow.set()
    NSGradient(colors: [NSColor(srgbRed: 0.38, green: 0.45, blue: 1, alpha: 1),
                        NSColor(srgbRed: 0.66, green: 0.36, blue: 1, alpha: 1)])!.draw(in: path, angle: -45)
    NSGraphicsContext.restoreGraphicsState()
    // Subtle top highlight.
    NSGradient(colors: [.white.withAlphaComponent(0.18), .white.withAlphaComponent(0)])!.draw(in: path, angle: -90)
    let config = NSImage.SymbolConfiguration(pointSize: body.height * 0.5, weight: .medium)
        .applying(.init(hierarchicalColor: .white))
    if let symbol = NSImage(systemSymbolName: "tv", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let s = symbol.size
        symbol.draw(in: NSRect(x: body.midX - s.width / 2, y: body.midY - s.height / 2, width: s.width, height: s.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

/// iOS icon: full-bleed and opaque (the system applies the rounded mask).
func renderFlat(_ size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSGradient(colors: [NSColor(srgbRed: 0.38, green: 0.45, blue: 1, alpha: 1),
                        NSColor(srgbRed: 0.66, green: 0.36, blue: 1, alpha: 1)])!.draw(in: rect, angle: -45)
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .medium).applying(.init(hierarchicalColor: .white))
    if let symbol = NSImage(systemSymbolName: "tv", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let s = symbol.size
        symbol.draw(in: NSRect(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2, width: s.width, height: s.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try render(CGFloat(base * scale)).representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
try render(512).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/icon.png"))
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try p.run(); p.waitUntilExit()
// iOS launch screen logo (shown at 3x, ~170pt) and its background color.
let launch = URL(fileURLWithPath: "iOS/App/Assets.xcassets/LaunchLogo.imageset")
try fm.createDirectory(at: launch, withIntermediateDirectories: true)
try render(512).representation(using: .png, properties: [:])!.write(to: launch.appendingPathComponent("launch-logo.png"))
try Data(#"{"images":[{"filename":"launch-logo.png","idiom":"universal","scale":"3x"}],"info":{"author":"xcode","version":1}}"#.utf8)
    .write(to: launch.appendingPathComponent("Contents.json"))
let bg = URL(fileURLWithPath: "iOS/App/Assets.xcassets/LaunchBackground.colorset")
try fm.createDirectory(at: bg, withIntermediateDirectories: true)
try Data(#"{"colors":[{"color":{"color-space":"srgb","components":{"red":"1.000","green":"1.000","blue":"1.000","alpha":"1.000"}},"idiom":"universal"},{"appearances":[{"appearance":"luminosity","value":"dark"}],"color":{"color-space":"srgb","components":{"red":"0.000","green":"0.000","blue":"0.000","alpha":"1.000"}},"idiom":"universal"}],"info":{"author":"xcode","version":1}}"#.utf8)
    .write(to: bg.appendingPathComponent("Contents.json"))

let iosSet = URL(fileURLWithPath: "iOS/App/Assets.xcassets/AppIcon.appiconset")
try fm.createDirectory(at: iosSet, withIntermediateDirectories: true)
try renderFlat(1024).representation(using: .png, properties: [:])!.write(to: iosSet.appendingPathComponent("icon-1024.png"))
try Data(#"{"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}"#.utf8)
    .write(to: iosSet.appendingPathComponent("Contents.json"))
try Data(#"{"info":{"author":"xcode","version":1}}"#.utf8).write(to: iosSet.deletingLastPathComponent().appendingPathComponent("Contents.json"))
print(p.terminationStatus == 0 ? "wrote docs/icon.png, Resources/AppIcon.icns and the iOS app icon" : "iconutil failed")
