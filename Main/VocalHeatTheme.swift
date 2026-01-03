import SwiftUI

// MARK: - Global VocalHeat Theme

enum VHTheme {

    // Core background for most screens
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(red: 0.05, green: 0.00, blue: 0.12),
            Color(red: 0.02, green: 0.03, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Primary neon colors
    static let hotPink = Color(red: 0.98, green: 0.25, blue: 0.60)
    static let neonBlue = Color(red: 0.18, green: 0.70, blue: 0.98)
    static let violet = Color(red: 0.42, green: 0.18, blue: 0.75)
    static let amber = Color(red: 0.98, green: 0.78, blue: 0.30)

    // Soft glass card background
    static let cardBackground = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Border for “primary” cards (Pro Studio, Hall of Fame, etc.)
    static let primaryBorder = LinearGradient(
        colors: [
            hotPink,
            neonBlue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Subtle border for secondary cards
    static let softBorder = Color.white.opacity(0.16)
}

// MARK: - View helpers

extension View {

    /// Applies the standard VocalHeat “glass card” style:
    /// - soft gradient background
    /// - subtle white border
    /// - light outer shadow
    func vhCardStyle(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(VHTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(VHTheme.softBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.65), radius: 14, x: 0, y: 10)
    }

    /// Quick way to apply the VocalHeat background to any screen.
    func vhBackground() -> some View {
        ZStack {
            VHTheme.backgroundGradient.ignoresSafeArea()
            self
        }
    }
}

