import AppKit
import SwiftUI

/// MenuBarExtra never resizes its window while it's open, so we size it to the SwiftUI content
/// ourselves, keeping the top edge pinned under the menu bar.
struct PanelSizer: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        guard size.height > 0 else { return }
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let content = window.contentRect(forFrameRect: window.frame)
            guard abs(content.height - size.height) > 0.5 else { return }
            let target = NSRect(x: content.minX, y: content.maxY - size.height, width: content.width, height: size.height)
            window.setFrame(window.frameRect(forContentRect: target), display: true, animate: window.isVisible)
        }
    }
}

/// A ScrollView that is only as tall as its content, up to `maxHeight`.
struct FitScroll<Content: View>: View {
    var maxHeight: CGFloat
    @ViewBuilder var content: Content
    @State private var height: CGFloat = 0

    var body: some View {
        ScrollView {
            content.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        }
        .scrollIndicators(.never)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(height, maxHeight))
    }
}
