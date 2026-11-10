import SwiftUI

#if os(iOS)
/// First-launch walkthrough: four swipeable pages, Skip and Get Started. Shown again from Settings → About.
struct OnboardingView: View {
    static let doneKey = "onboardingDone"

    let finish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page: Identifiable {
        let id: Int
        let symbol: String
        let title: String
        let body: String
    }

    private var pages: [Page] {
        [Page(id: 0, symbol: "dot.radiowaves.left.and.right", title: L10n.Onboarding.Find.title, body: L10n.Onboarding.Find.body),
         Page(id: 1, symbol: "link.badge.plus", title: L10n.Onboarding.Pair.title, body: L10n.Onboarding.Pair.body),
         Page(id: 2, symbol: "hand.draw", title: L10n.Onboarding.Control.title, body: L10n.Onboarding.Control.body),
         Page(id: 3, symbol: "square.grid.2x2.fill", title: L10n.Onboarding.Apps.title, body: L10n.Onboarding.Apps.body)]
    }

    private var isLast: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(L10n.Onboarding.skip, action: finish)
                    .font(.body.weight(.medium)).foregroundStyle(.secondary)
                    .opacity(isLast ? 0 : 1)
            }
            .padding(.horizontal, 24).padding(.top, 12)

            TabView(selection: $page) {
                ForEach(pages) { p in
                    VStack(spacing: 28) {
                        Spacer()
                        ZStack {
                            Circle().fill(Theme.accent).frame(width: 150, height: 150)
                                .shadow(color: Theme.glow.opacity(0.4), radius: 24, y: 10)
                            Image(systemName: p.symbol).font(.system(size: 60, weight: .semibold)).foregroundStyle(.white)
                                .symbolEffect(.bounce, value: page == p.id && !reduceMotion)
                        }
                        VStack(spacing: 14) {
                            Text(p.title).font(.title.weight(.bold)).multilineTextAlignment(.center)
                            Text(p.body).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: 420)
                        Spacer()
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .tag(p.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(pages) { p in
                    Capsule().fill(page == p.id ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                        .frame(width: page == p.id ? 24 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: page)
            .accessibilityHidden(true)

            Button {
                if isLast { finish() } else { withAnimation(.spring) { page += 1 } }
            } label: {
                Text(isLast ? L10n.Onboarding.start : L10n.Onboarding.next)
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: 420).frame(height: 54)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressStyle(hoverScale: 1, pressScale: 0.97))
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)
        }
        .themed()
    }
}
#endif
