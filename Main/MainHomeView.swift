import SwiftUI

struct HomeMainView: View {
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

            VStack(spacing: 26) {
                header

                Spacer(minLength: 10)

                tileGrid

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Text("Vocal")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(" Heat Studio")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("by Kris Enterprises LLC")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            NavigationLink {
                StudioSettingsView()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Tiles

    private var tileGrid: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                NavigationLink {
                    RecordingView()
                } label: {
                    modeTile(
                        title: "Record",
                        subtitle: "Quick take",
                        iconName: "mic.fill",
                        startColor: Color(red: 230/255, green: 70/255, blue: 120/255),
                        endColor: Color(red: 255/255, green: 120/255, blue: 140/255)
                    )
                }

                NavigationLink {
                    DuetStudioView()
                } label: {
                    modeTile(
                        title: "Duet Mode",
                        subtitle: "Sing w/ ref track",
                        iconName: "headphones",
                        startColor: Color(red: 210/255, green: 80/255, blue: 180/255),
                        endColor: Color(red: 255/255, green: 140/255, blue: 210/255)
                    )
                }
            }

            HStack(spacing: 18) {
                NavigationLink {
                    SessionsListView()
                } label: {
                    modeTile(
                        title: "Sessions",
                        subtitle: "Review takes",
                        iconName: "waveform.path.ecg",
                        startColor: Color(red: 160/255, green: 80/255, blue: 220/255),
                        endColor: Color(red: 210/255, green: 120/255, blue: 255/255)
                    )
                }

                NavigationLink {
                    HallOfFameView()
                } label: {
                    modeTile(
                        title: "Hall of Fame",
                        subtitle: "Best performances",
                        iconName: "star.fill",
                        startColor: Color(red: 70/255, green: 150/255, blue: 255/255),
                        endColor: Color(red: 120/255, green: 220/255, blue: 255/255)
                    )
                }
            }
        }
    }

    private func modeTile(
        title: String,
        subtitle: String,
        iconName: String,
        startColor: Color,
        endColor: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [startColor, endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.9)
                .shadow(color: endColor.opacity(0.7), radius: 22, y: 14)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)

            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 4)

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
