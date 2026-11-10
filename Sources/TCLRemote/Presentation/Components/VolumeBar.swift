import SwiftUI
import TVKit

/// Live volume level reported by Google TV.
struct VolumeBar: View {
    let volume: Store.Volume
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: volume.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.caption).foregroundStyle(.secondary).contentTransition(.symbolEffect(.replace))
            GeometryReader { g in
                Capsule().fill(Theme.fill)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Theme.accent)
                            .frame(width: g.size.width * CGFloat(volume.level) / CGFloat(max(volume.max, 1)))
                            .opacity(volume.muted ? 0.35 : 1)
                    }
            }
            .frame(height: 6)
            Text("\(volume.level)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .contentTransition(.numericText()).frame(width: 24, alignment: .trailing)
        }
        .animation(.smooth, value: volume)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(volume.muted ? "Muted" : "Volume \(volume.level) of \(volume.max)")
    }
}
