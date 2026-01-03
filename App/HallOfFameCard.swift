import SwiftUI

struct HallOfFameCard: View {
    let session: SessionModel

    private var metrics: SessionMetrics {
        session.metrics ?? .mock
    }

    private var title: String {
        session.title.isEmpty ? "Untitled session" : session.title
    }

    private var subtitle: String {
        "Score \(metrics.finalScore) • \(formattedDate(session.createdAt))"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 80/255, green: 0, blue: 130/255),
                            Color(red: 150/255, green: 0, blue: 220/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow, Color.white],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.3
                        )
                )
                .shadow(color: Color.yellow.opacity(0.6), radius: 18, x: 0, y: 18)

            HStack(spacing: 14) {
                VStack(alignment: .center, spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)

                    Text("\(metrics.finalScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Score")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 70)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        statChip("Pitch", metrics.pitchAccuracy)
                        statChip("Vibrato", metrics.vibratoControl)
                    }

                    HStack(spacing: 8) {
                        statChip("Stability", metrics.stability)
                        statChip("Expr.", metrics.expression)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(18)
        }
    }

    private func statChip(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.16))
        .clipShape(Capsule())
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}
