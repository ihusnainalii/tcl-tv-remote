import SwiftUI

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
        // Fade the bottom edge when there's more to scroll, so a cut-off row reads as "scroll me".
        .mask {
            LinearGradient(stops: [.init(color: .black, location: 0),
                                   .init(color: .black, location: height > maxHeight ? 0.82 : 1),
                                   .init(color: height > maxHeight ? .clear : .black, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}
