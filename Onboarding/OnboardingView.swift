import SwiftUI

struct OnboardingView: View {
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to VocalHeat",
            subtitle: "Your personal AI-powered vocal studio. Record, analyze, and track your voice like a pro.",
            icon: "flame.fill"
        ),
        OnboardingPage(
            title: "Studio + Duet Modes",
            subtitle: "Sing solo in Studio Mode or chase your favorite artists in Duet Mode with real-time pitch tracking.",
            icon: "music.mic"
        ),
        OnboardingPage(
            title: "Scores, Insights, Hall of Fame",
            subtitle: "Get detailed scores, long-term insights, and mark your most iconic takes for your Hall of Fame.",
            icon: "star.circle.fill"
        )
    ]

    // Later you’ll wire this to dismiss onboarding and show HomeView
    var onFinished: (() -> Void)?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 5/255, green: 0, blue: 25/255),
                    Color(red: 12/255, green: 0, blue: 45/255),
                    Color(red: 30/255, green: 0, blue: 70/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentPage)

                bottomControls
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("VocalHeat")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.cyan, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            Button {
                finishOnboarding()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentPage
                            ? Color.white
                            : Color.white.opacity(0.3)
                        )
                        .frame(width: index == currentPage ? 20 : 8, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }

            Button {
                handleNext()
            } label: {
                HStack(spacing: 10) {
                    Text(currentPage == pages.count - 1 ? "Get started" : "Next")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.pink, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(18)
                .shadow(color: .pink.opacity(0.5), radius: 16, y: 10)
            }
        }
        .padding(.top, 18)
    }

    // MARK: - Actions

    private func handleNext() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        onFinished?()
    }
}

// MARK: - Model

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 220, height: 220)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.cyan, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: .pink.opacity(0.7), radius: 18, y: 14)

                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 40)
        }
    }
}

