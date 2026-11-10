// Renders the app icon: white remote symbol on the violet accent gradient.
// Usage: swift scripts/make-icon.swift  -> docs/icon.png (README) + Resources/AppIcon.icns (app)
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
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "appletvremote.gen4.fill", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let s = symbol.size
        symbol.draw(in: NSRect(x: body.midX - s.width / 2, y: body.midY - s.height / 2, width: s.width, height: s.height))
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
print(p.terminationStatus == 0 ? "wrote docs/icon.png and Resources/AppIcon.icns" : "iconutil failed")
