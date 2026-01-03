import SwiftUI

// MARK: - Main Studio Home View

struct AppHomeView: View {
    var onRecord: () -> Void = {}
    var onDuetMode: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onHome: () -> Void = {} // New: allow parent to wire a pop-to-root action if desired

    var body: some View {
        ZStack {
            // Studio background
            LinearGradient(
                colors: [Color.vhBackgroundTop, Color.vhBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header only (settings moved to overlay)
                StudioHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Tight neon hero (image + description)
                StudioHeroSection()
                    .padding(.top, 4)

                // Record / Duet buttons (fixed height 45pt)
                HStack(spacing: 16) {
                    StudioActionButton(
                        title: "Record",
                        subtitle: "Quick take",
                        systemImage: "mic.fill",
                        gradient: [
                            Color.vhMagentaPrimary, // unified
                            Color.vhMagentaSecondary
                        ],
                        action: onRecord,
                        sizeScale: 1.0,
                        heightScale: 1.0,
                        fixedHeight: 45
                    )

                    StudioActionButton(
                        title: "Duet Mode",
                        subtitle: "Sing w/ ref track",
                        systemImage: "music.mic",
                        gradient: [
                            Color.vhTealPrimary,
                            Color.vhTealSecondary
                        ],
                        action: onDuetMode,
                        sizeScale: 1.0,
                        heightScale: 1.0,
                        fixedHeight: 45
                    )
                }
                .padding(.horizontal, 24)

                // Feature cards (larger, equal sized 3-up)
                GeometryReader { geo in
                    // Make three equal cards with a bit more size.
                    // Keep spacing 12 between them and honor 24pt horizontal padding on both sides.
                    let totalSpacing: CGFloat = 12 * 2
                    let totalHorizontalPadding: CGFloat = 24 * 2
                    let availableWidth = geo.size.width - totalHorizontalPadding - totalSpacing
                    let cardWidth = max(130, availableWidth / 3) // increased minimum width
                    let cardHeight: CGFloat = 160                 // increased height

                    HStack(spacing: 12) {
                        StudioFeatureCard(
                            iconName: "waveform.path.ecg",
                            title: "Real-Time",
                            descriptionText: "Live pitch, vibrato, and stability.",
                            glowColor: Color(red: 0.50, green: 0.25, blue: 0.95),
                            strokeColor: Color(red: 0.55, green: 0.30, blue: 1.00)
                        )
                        .frame(width: cardWidth, height: cardHeight)

                        StudioFeatureCard(
                            iconName: "brain.head.profile",
                            title: "AI Coach",
                            descriptionText: "Natural-language feedback.",
                            glowColor: Color.vhTealPrimary,
                            strokeColor: Color.vhTealSecondary
                        )
                        .frame(width: cardWidth, height: cardHeight)

                        StudioFeatureCard(
                            iconName: "chart.bar.xaxis",
                            title: "Progress",
                            descriptionText: "Streaks and Hall of Fame.",
                            glowColor: Color.vhMagentaPrimary,     // unified
                            strokeColor: Color.vhMagentaSecondary // unified
                        )
                        .frame(width: cardWidth, height: cardHeight)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                }
                .frame(height: 160)          // match increased card height
                .padding(.top, 20)           // push a little lower on the page

                Spacer(minLength: 16)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Top-right overlay: Home + Settings pills (reusable)
            StudioTopRightControls(onHome: onHome, onOpenSettings: onOpenSettings)
                .padding(.top, 12)
                .padding(.trailing, 24)
        }
        .environment(\.colorScheme, .dark) // lock to dark studio look
    }
}

// MARK: - Header (Fit-to-width version)

struct StudioHeader: View {
    var body: some View {
        VStack(spacing: 4) {
            // MAIN TITLE
            HStack(spacing: 0) {
                Text("Vocal")
                    .foregroundColor(.white)

                Text(" Heat")
                    .foregroundColor(Color.vhTealPrimary)
                    .shadow(color: Color.vhTealSecondary.opacity(0.85), radius: 10, x: 0, y: 0)

                Text(" Studio")
                    .foregroundColor(Color.vhMagentaPrimary) // unified
                    .shadow(color: Color.vhMagentaSecondary.opacity(0.85), radius: 10, x: 0, y: 0) // unified glow
            }
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .allowsTightening(true)
            .padding(.top, 10)

            // SUBTITLE
            Text("by Kris Enterprises LLC")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.white.opacity(0.85))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Top-right controls (Home + Settings)

struct StudioTopRightControls: View {
    var onHome: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HomePillButton(action: onHome)
            SettingsPillButton(action: onOpenSettings)
        }
    }
}

// MARK: - Settings Button

struct SettingsPillButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.fill")
                    .font(.footnote)
                Text("Studio Settings")
                    .font(.footnote.weight(.medium))
            }
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Studio Settings")
    }
}

// MARK: - Home Button (new)

struct HomePillButton: View {
    var action: ()-> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "house.fill")
                    .font(.footnote)
                Text("Home")
                    .font(.footnote.weight(.medium))
            }
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Go to Home")
    }
}

// MARK: - Studio Hero (two-asset composition)

struct StudioHeroSection: View {
    // Asset names to add to your asset catalog:
    // - VocalHeatSilhouettes: silhouettes-only image (grayscale or white on transparent)
    // - VocalHeatMic: mic-only image (pure white on transparent)
    private let silhouettesAsset = "VocalHeatSilhouettes"
    private let micAsset = "VocalHeatMic"

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Base silhouettes, tinted by brand gradient
                Image(silhouettesAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .overlay(
                        LinearGradient(
                            colors: [Color.vhMagentaPrimary, Color.vhTealPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .blendMode(.screen) // try .plusLighter for stronger bloom
                        .opacity(0.8)
                    )
                    .shadow(color: Color.vhMagentaSecondary.opacity(0.6), radius: 6, y: 1.5)
                    .shadow(color: Color.vhTealSecondary.opacity(0.6), radius: 6, y: 1.5)

                // Top mic, kept pure white
                Image(micAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .shadow(color: .white.opacity(0.25), radius: 4, y: 1)
            }
            .padding(.top, 4)
            .padding(.bottom, 4)

            // Description
            Text("Your personal AI vocal coach. Real-time pitch, duet mode, and expressive feedback in one neon-lit studio.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Neon Action Button (with glow bleed + independent height)

struct StudioActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let gradient: [Color]
    var action: () -> Void = {}
    var sizeScale: CGFloat = 1.0      // scales content, corner radius, etc.
    var heightScale: CGFloat = 1.0    // scales only height and vertical padding
    var fixedHeight: CGFloat? = nil   // exact height override

    var body: some View {
        // If we force a fixed height, slightly reduce icon circle to fit nicely.
        let circleSize: CGFloat = fixedHeight != nil ? 32 : (40 * sizeScale)
        let verticalPad: CGFloat = fixedHeight != nil ? 6 : (12 * sizeScale * max(0.6, heightScale))
        let cornerRadius: CGFloat = 22 * sizeScale

        return Button(action: action) {
            ZStack {
                // Outer neon bleed layers (behind the button)
                GlowOverlay(gradient: gradient, cornerRadius: cornerRadius)

                // Button body (dimmed slightly)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.015)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: gradient.map { $0.opacity(0.90) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.6 * sizeScale
                            )
                    )
                    .shadow(
                        color: gradient.first?.opacity(0.55) ?? .white.opacity(0.5),
                        radius: 8 * sizeScale, x: 0, y: 1.5
                    )

                HStack(spacing: 10 * sizeScale) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: circleSize, height: circleSize)
                            .shadow(
                                color: gradient.first?.opacity(0.7) ?? .clear,
                                radius: 4, x: 0, y: 1.5
                            )

                        Image(systemName: systemImage)
                            .font(.system(size: 16 * sizeScale, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.95))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16 * sizeScale, weight: .semibold))
                            .foregroundStyle(Color.white)

                        Text(subtitle)
                            .font(.system(size: 12 * sizeScale, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.70))
                    }

                    Spacer()
                }
                .padding(.horizontal, 16 * sizeScale)
                .padding(.vertical, verticalPad)
            }
            .frame(height: fixedHeight ?? (72 * heightScale))
        }
        .buttonStyle(.plain)
    }
}

// Subview: layered glow bleed
private struct GlowOverlay: View {
    let gradient: [Color]
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Strong inner glow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 10)
                .blur(radius: 16)
                .opacity(0.85)

            // Medium halo
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LinearGradient(colors: gradient.map { $0.opacity(0.7) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 16)
                .blur(radius: 28)
                .opacity(0.75)

            // Wide soft bloom
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(LinearGradient(colors: gradient.map { $0.opacity(0.45) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 26)
                .blur(radius: 42)
                .opacity(0.7)
        }
    }
}

// MARK: - Feature Card (punchier)

struct StudioFeatureCard: View {
    let iconName: String
    let title: String
    let descriptionText: String
    let glowColor: Color
    let strokeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(strokeColor)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)

            Text(descriptionText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(strokeColor.opacity(0.60), lineWidth: 1.2)
        )
        .shadow(color: glowColor.opacity(0.55),
                radius: 12, x: 0, y: 1.5)
    }
}

// MARK: - Color Palette

extension Color {
    static let vhBackgroundTop = Color(red: 8/255, green: 4/255, blue: 22/255)
    static let vhBackgroundBottom = Color(red: 4/255, green: 0/255, blue: 10/255)

    // Unified magenta palette to match Record/Progress themes
    static let vhMagentaPrimary = Color(red: 1.00, green: 0.10, blue: 0.40)
    static let vhMagentaSecondary = Color(red: 0.95, green: 0.20, blue: 0.60)

    // Unified teal palette to match Duet/AI themes
    static let vhTealPrimary = Color(red: 0.15, green: 0.80, blue: 0.95)
    static let vhTealSecondary = Color(red: 0.40, green: 0.90, blue: 1.00)
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppHomeView()
    }
}
