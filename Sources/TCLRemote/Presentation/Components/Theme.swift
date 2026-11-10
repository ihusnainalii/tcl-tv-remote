import SwiftUI
import TVKit

// MARK: - Theme

enum Theme {
    static let accent = LinearGradient(colors: [Color(red: 0.38, green: 0.45, blue: 1), Color(red: 0.66, green: 0.36, blue: 1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
    static let power = LinearGradient(colors: [Color(red: 1, green: 0.38, blue: 0.38), Color(red: 0.86, green: 0.15, blue: 0.3)],
                                      startPoint: .top, endPoint: .bottom)
    static let fill = Color.primary.opacity(0.07)
    static let stroke = Color.primary.opacity(0.09)
    static let spring = Animation.spring(response: 0.32, dampingFraction: 0.62)
}

/// Squishy press + hover lift used by every control.
struct PressStyle: ButtonStyle {
    func makeBody(configuration c: Configuration) -> some View { Pressable(c: c) }

    private struct Pressable: View {
        let c: Configuration
        @State private var hover = false
        var body: some View {
            c.label
                .scaleEffect(c.isPressed ? 0.88 : hover ? 1.04 : 1)
                .brightness(c.isPressed ? 0.12 : hover ? 0.04 : 0)
                .animation(Theme.spring, value: c.isPressed)
                .animation(.easeOut(duration: 0.15), value: hover)
                .onHover { hover = $0 }
        }
    }
}

/// Fires once on press, then repeats while held (D-pad, volume, channel).
private struct RepeatPress: ViewModifier {
    let action: () -> Void
    @State private var task: Task<Void, Never>?
    @State private var hover = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(task != nil ? 0.88 : hover ? 1.04 : 1)
            .brightness(task != nil ? 0.12 : hover ? 0.04 : 0)
            .animation(Theme.spring, value: task != nil)
            .animation(.easeOut(duration: 0.15), value: hover)
            .onHover { hover = $0 }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard task == nil else { return }
                    action()
                    task = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        while !Task.isCancelled {
                            action()
                            try? await Task.sleep(for: .milliseconds(110))
                        }
                    }
                }
                .onEnded { _ in task?.cancel(); task = nil })
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }
}

extension View {
    func repeatPress(_ action: @escaping () -> Void) -> some View { modifier(RepeatPress(action: action)) }

    func pill<S: Shape>(_ shape: S) -> some View {
        background(Theme.fill, in: shape).overlay(shape.stroke(Theme.stroke, lineWidth: 0.5))
    }
}
