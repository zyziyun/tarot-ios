import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @State private var isActive = false
    @State private var opacity = 1.0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    let content: () -> AnyView

    var body: some View {
        ZStack {
            content()

            if !isActive {
                if hasSeenOnboarding {
                    // Returning user: quick splash
                    quickSplash
                } else {
                    // First time: onboarding carousel
                    OnboardingCarousel {
                        hasSeenOnboarding = true
                        withAnimation(.easeOut(duration: 0.5)) {
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isActive = true
                            appState.splashFinished = true
                        }
                    }
                    .opacity(opacity)
                }
            }
        }
    }

    private var quickSplash: some View {
        RandomSplashPage()
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isActive = true
                        appState.splashFinished = true
                    }
                }
            }
    }
}

// MARK: - Onboarding Carousel

private struct OnboardingCarousel: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var fadeIn = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "LaunchImage",
            title: "Tarot Mystica",
            subtitle: "Discover insights through the ancient art of tarot. Beautiful card spreads, intuitive drawing, and meaningful readings.",
            accent: "✦"
        ),
        OnboardingPage(
            imageName: nil,
            title: "17 Spread Layouts",
            subtitle: "From simple 3-card readings to the complete Celtic Cross. Each spread reveals a unique perspective on your question.",
            accent: "🔮",
            showSpreadPreview: true
        ),
        OnboardingPage(
            imageName: nil,
            title: "AI Deep Reading",
            subtitle: "On-device AI interprets your cards privately. No data leaves your phone — your readings stay between you and the cards.",
            accent: "🧠",
            showAIPreview: true
        ),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.965, blue: 0.94)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        onboardingPageView(pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom area
                VStack(spacing: 20) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentPage ? Color(red: 0.486, green: 0.227, blue: 0.929) : Color.gray.opacity(0.3))
                                .frame(width: 7, height: 7)
                                .scaleEffect(idx == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.25), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Begin Reading")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.176, green: 0.161, blue: 0.149))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .cornerRadius(28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                    }
                    .padding(.horizontal, 32)

                    // Skip
                    if currentPage < pages.count - 1 {
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 13))
                                .foregroundColor(Color.gray)
                        }
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .opacity(fadeIn ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                fadeIn = true
            }
        }
    }

    @ViewBuilder
    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()

            if let imageName = page.imageName {
                // Image slide (first page)
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 340)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
                    .padding(.horizontal, 40)
            } else if page.showSpreadPreview {
                // Spread layout previews
                spreadPreviewGrid
            } else if page.showAIPreview {
                // AI reading preview
                aiPreviewCard
            }

            Spacer().frame(height: 40)

            // Text content
            VStack(spacing: 14) {
                Text(page.accent)
                    .font(.system(size: 20))

                Text(page.title)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(Color(red: 0.176, green: 0.161, blue: 0.149))
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }

            Spacer()
        }
    }

    // Spread layout mini previews for page 2
    private var spreadPreviewGrid: some View {
        let previewSpreads: [(String, String, Int)] = [
            ("threeCard", "🃏", 3),
            ("celtic", "☘️", 10),
            ("hexagram", "✡️", 7),
            ("zodiac", "♈", 12),
        ]

        return HStack(spacing: 16) {
            ForEach(previewSpreads, id: \.0) { key, icon, count in
                VStack(spacing: 8) {
                    ZStack {
                        SpreadLayoutView(
                            spreadKey: key,
                            count: count,
                            accentColor: Color(red: 0.788, green: 0.659, blue: 0.298),
                            cardColor: Color(red: 0.788, green: 0.659, blue: 0.298).opacity(0.2),
                            size: 56
                        )
                        Text(icon)
                            .font(.system(size: 14))
                            .opacity(0.4)
                    }
                    .frame(width: 64, height: 64)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(12)
                }
            }
        }
    }

    // AI preview card for page 3
    private var aiPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("AI Deep Reading")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.176, green: 0.161, blue: 0.149))
            }

            VStack(alignment: .leading, spacing: 6) {
                fakeTextLine(width: 220)
                fakeTextLine(width: 180)
                fakeTextLine(width: 200)
                fakeTextLine(width: 140)
            }
            .padding(.top, 4)

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.green.opacity(0.7))
                Text("100% on-device, private")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 4)
    }

    private func fakeTextLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.12))
            .frame(width: width, height: 10)
    }
}

private struct OnboardingPage {
    let imageName: String?
    let title: String
    let subtitle: String
    let accent: String
    var showSpreadPreview: Bool = false
    var showAIPreview: Bool = false
}

// MARK: - Random Splash (returning users)

private struct RandomSplashPage: View {
    @State private var variant = Int.random(in: 0...2)
    @State private var fadeIn = false

    private let cream = Color(red: 0.98, green: 0.965, blue: 0.94)
    private let dark = Color(red: 0.176, green: 0.161, blue: 0.149)
    private let gold = Color(red: 0.788, green: 0.659, blue: 0.298)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                switch variant {
                case 0:
                    // Card art splash
                    Image("LaunchImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
                        .padding(.horizontal, 48)

                case 1:
                    // Spread layouts
                    splashSpreadGrid

                default:
                    // AI preview
                    splashAICard
                }

                Spacer().frame(height: 36)

                VStack(spacing: 10) {
                    Text("Tarot Mystica")
                        .font(.system(size: 30, weight: .light, design: .serif))
                        .foregroundColor(dark)
                    Text("✦")
                        .font(.system(size: 10))
                        .foregroundColor(gold.opacity(0.5))
                }

                Spacer()
            }
            .opacity(fadeIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                fadeIn = true
            }
        }
    }

    private var splashSpreadGrid: some View {
        let spreads: [(String, String, Int)] = [
            ("threeCard", "🃏", 3),
            ("celtic", "☘️", 10),
            ("hexagram", "✡️", 7),
            ("zodiac", "♈", 12),
        ]

        return HStack(spacing: 16) {
            ForEach(spreads, id: \.0) { key, icon, count in
                ZStack {
                    SpreadLayoutView(
                        spreadKey: key,
                        count: count,
                        accentColor: gold,
                        cardColor: gold.opacity(0.2),
                        size: 56
                    )
                    Text(icon)
                        .font(.system(size: 14))
                        .opacity(0.4)
                }
                .frame(width: 64, height: 64)
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
            }
        }
    }

    private var splashAICard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("AI Deep Reading")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(dark)
            }

            VStack(alignment: .leading, spacing: 6) {
                fakeLine(220)
                fakeLine(180)
                fakeLine(200)
                fakeLine(140)
            }
            .padding(.top, 4)

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.green.opacity(0.7))
                Text("100% on-device, private")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 280)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 4)
    }

    private func fakeLine(_ width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.12))
            .frame(width: width, height: 10)
    }
}
