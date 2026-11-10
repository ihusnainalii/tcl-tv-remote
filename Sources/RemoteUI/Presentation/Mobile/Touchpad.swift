import SwiftUI
import TVKit

#if os(iOS)
/// Swipe to move, tap to select. Each ~44pt of travel along the dominant axis is one arrow press,
/// so a long swipe moves several steps; a quick tap sends OK.
struct Touchpad: View {
    @EnvironmentObject var s: Store
    @State private var touch: CGPoint?
    @State private var consumed: CGSize = .zero
    @State private var moved = false
    @State private var pulse = false

    private let step: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Theme.fill)
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Theme.stroke, lineWidth: 0.5))
            .overlay {
                if touch == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.draw").font(.system(size: 28, weight: .light))
                        Text(L10n.Mobile.Touchpad.hint).font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                }
            }
            .overlay {
                if let touch {
                    Circle().fill(Theme.accent).frame(width: 64, height: 64)
                        .opacity(0.35).blur(radius: 6)
                        .scaleEffect(pulse ? 1.25 : 1)
                        .position(touch)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    if touch == nil { withAnimation(.easeOut(duration: 0.15)) { touch = v.location } } else { touch = v.location }
                    let dx = v.translation.width - consumed.width, dy = v.translation.height - consumed.height
                    if abs(dx) >= step, abs(dx) >= abs(dy) {
                        s.press(dx > 0 ? .right : .left)
                        consumed.width += dx > 0 ? step : -step
                        bump()
                    } else if abs(dy) >= step {
                        s.press(dy > 0 ? .down : .up)
                        consumed.height += dy > 0 ? step : -step
                        bump()
                    }
                    if hypot(v.translation.width, v.translation.height) > 10 { moved = true }
                }
                .onEnded { _ in
                    if !moved { s.press(.ok); bump() }
                    withAnimation(.easeOut(duration: 0.25)) { touch = nil }
                    consumed = .zero
                    moved = false
                })
            .accessibilityElement()
            .accessibilityLabel(L10n.Mobile.Mode.touchpad)
            .accessibilityAction { s.press(.ok) }
    }

    private func bump() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { pulse = true }
        withAnimation(.spring(response: 0.3).delay(0.1)) { pulse = false }
    }
}
#endif
