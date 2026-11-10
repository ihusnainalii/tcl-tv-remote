import AppKit
import SwiftUI
import TVKit

/// Live volume from Google TV. Drag it, or swipe two fingers on the trackpad over it.
struct VolumeBar: View {
    @EnvironmentObject var s: Store
    let volume: TVVolume
    @State private var hover = false
    @State private var dragging = false

    var fraction: CGFloat { CGFloat(volume.level) / CGFloat(max(volume.max, 1)) }

    var body: some View {
        HStack(spacing: 8) {
            Button { s.press(.mute) } label: {
                Image(systemName: volume.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.caption).foregroundStyle(.secondary).contentTransition(.symbolEffect(.replace))
                    .frame(width: 18)
            }
            .buttonStyle(PressStyle()).accessibilityLabel(volume.muted ? L10n.Volume.unmute : L10n.Volume.mute)

            GeometryReader { g in
                let active = hover || dragging
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.fill)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(g.size.width * fraction, active ? 10 : 6))
                        .opacity(volume.muted ? 0.35 : 1)
                    Circle().fill(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .frame(width: active ? 14 : 0, height: active ? 14 : 0)
                        .offset(x: g.size.width * fraction - (active ? 7 : 0))
                }
                .frame(height: active ? 8 : 6)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        dragging = true
                        s.setVolume(Int((v.location.x / g.size.width * CGFloat(volume.max)).rounded()))
                    }
                    .onEnded { _ in dragging = false })
                .overlay(ScrollCatcher { s.nudgeVolume($0) })
            }
            .frame(height: 20)
            .onHover { hover = $0 }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover || dragging)

            Text("\(volume.level)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .contentTransition(.numericText()).frame(width: 24, alignment: .trailing)
        }
        .animation(.smooth(duration: 0.2), value: volume)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(volume.muted ? L10n.Volume.muted : L10n.Volume.label)
        .accessibilityValue(L10n.Volume.value(volume.level, volume.max))
        .accessibilityAdjustableAction { dir in
            if dir == .increment { s.nudgeVolume(1) } else if dir == .decrement { s.nudgeVolume(-1) }
        }
    }
}

/// Turns trackpad / mouse-wheel scrolling over the bar into volume steps.
private struct ScrollCatcher: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> CatcherView { CatcherView() }
    func updateNSView(_ v: CatcherView, context: Context) { v.onStep = onStep }

    final class CatcherView: NSView {
        var onStep: ((Int) -> Void)?
        private var accumulated: CGFloat = 0

        override func scrollWheel(with e: NSEvent) {
            // Momentum events keep coming after the fingers lift; they made the volume run away.
            guard e.momentumPhase.isEmpty else { return }
            if e.phase == .began { accumulated = 0 }
            // Horizontal or vertical swipe both work; right/up = louder. Mouse wheels step per notch.
            let raw = abs(e.scrollingDeltaX) > abs(e.scrollingDeltaY) ? -e.scrollingDeltaX : e.scrollingDeltaY
            let delta = e.isDirectionInvertedFromDevice ? -raw : raw
            let perStep: CGFloat = 14 // points of finger travel per volume step
            accumulated += e.hasPreciseScrollingDeltas ? delta : delta * perStep
            while abs(accumulated) >= perStep {
                onStep?(accumulated > 0 ? 1 : -1)
                accumulated -= accumulated > 0 ? perStep : -perStep
            }
        }
    }
}
