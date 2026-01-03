import SwiftUI

struct BackToStudioPill: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "house.fill")
                    .font(.footnote)
                Text("Studio")
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
        .accessibilityLabel("Back to Studio")
    }
}
