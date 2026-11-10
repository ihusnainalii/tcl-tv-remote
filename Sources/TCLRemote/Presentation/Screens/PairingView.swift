import SwiftUI
import TVKit

// MARK: - Pairing

struct PairingView: View {
    @EnvironmentObject var s: Store
    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.tv").font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.accent).symbolEffect(.pulse)
            VStack(spacing: 4) {
                Text("Enter the code on your TV").font(.headline)
                Text("A 6-character code is showing on screen.").font(.caption).foregroundStyle(.secondary)
            }
            ZStack {
                TextField("", text: $code).focused($focused).opacity(0.01)
                    .onChange(of: code) { _, new in
                        let clean = String(new.uppercased().filter(\.isHexDigit).prefix(6))
                        if clean != new { code = clean }
                        if clean.count == 6 { s.submitCode(clean) }
                    }
                HStack(spacing: 7) {
                    ForEach(0..<6, id: \.self) { i in
                        let chars = Array(code)
                        let active = i == chars.count && focused
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Theme.fill)
                                .overlay(RoundedRectangle(cornerRadius: 9)
                                    .stroke(active ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.stroke),
                                            lineWidth: active ? 2 : 0.5))
                            if i < chars.count {
                                Text(String(chars[i])).font(.system(size: 20, weight: .semibold, design: .monospaced))
                                    .transition(.scale(scale: 0.4).combined(with: .opacity))
                            }
                        }
                        .frame(width: 36, height: 44)
                        .scaleEffect(active ? 1.06 : 1)
                    }
                }
                .animation(Theme.spring, value: code)
                .contentShape(Rectangle())
                .onTapGesture { focused = true }
            }
            .keyframeAnimator(initialValue: 0.0, trigger: s.pairError) { c, x in c.offset(x: x) } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-10, duration: 0.06); CubicKeyframe(9, duration: 0.06)
                    CubicKeyframe(-6, duration: 0.06); CubicKeyframe(4, duration: 0.06); CubicKeyframe(0, duration: 0.06)
                }
            }
            .onChange(of: s.pairError) { code = "" }

            HStack {
                Button("Cancel") { s.cancelPairing() }.buttonStyle(.bordered)
                Button("Pair") { s.submitCode(code) }.buttonStyle(.borderedProminent).disabled(code.count < 6)
            }
        }
        .padding(.vertical, 8)
        .onAppear { focused = true }
    }
}
