import SwiftUI

struct PositiveRecordingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.green.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)

                Text("Positive Mode")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Here you’ll only get encouraging, constructive feedback from VocalHeat.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationTitle("Positive Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PositiveRecordingView()
}

