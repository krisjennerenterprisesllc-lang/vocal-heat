import SwiftUI

struct DuetStudioView: View {
    // MARK: - State
    @State private var selectedTab: DuetStudioTab = .library
    @State private var selectedTrackID: UUID? = DuetStudioTrack.mockTracks.first?.id
    @State private var enableCountIn: Bool = true
    @State private var outputDevice: OutputOption = .device
    @State private var showTrackDetails: Bool = false

    @EnvironmentObject private var tabSelection: TabSelectionStore
    @EnvironmentObject private var duetSession: DuetSessionStore

    var body: some View {
        ZStack {
            // Updated: match AppHomeView background
            LinearGradient(
                colors: [Color.vhBackgroundTop, Color.vhBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                // Updated: use the same StudioHeader as Home
                StudioHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Keep your existing subtitle under the shared header
                Text("Choose a reference track for Duet Mode")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                tabSelector

                trackListSection

                studioOptions

                Spacer(minLength: 8)

                NavigationLink(destination: DuetRecordingView()) {
                    startDuetButtonLabel
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        // Keep your existing toolbar title or remove if you prefer only the StudioHeader
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Duet Studio")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        // Keep your existing top-right control unchanged (BackToStudioPill)
        .overlay(alignment: .topTrailing) {
            BackToStudioPill {
                tabSelection.selected = .studio
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .onAppear {
            // Initialize local UI state from shared store if available
            if let selected = duetSession.selectedTrack {
                selectedTrackID = selected.id
            } else {
                selectedTrackID = DuetStudioTrack.mockTracks.first?.id
                if let first = DuetStudioTrack.mockTracks.first {
                    duetSession.selectedTrack = ReferenceTrack(
                        id: first.id,
                        title: first.title,
                        artist: first.artist,
                        duration: first.duration,
                        key: first.key,
                        tempo: first.tempo
                    )
                }
            }
            enableCountIn = duetSession.enableCountIn
            outputDevice = duetSession.outputDevice
        }
        .onChange(of: enableCountIn) { newValue, _ in
            duetSession.enableCountIn = newValue
        }
        .onChange(of: outputDevice) { newValue, _ in
            duetSession.outputDevice = newValue
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Tabs

    private var tabSelector: some View {
        HStack(spacing: 10) {
            ForEach(DuetStudioTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: selectedTab == tab
                                            ? [Color.purple.opacity(0.9), Color.pink.opacity(0.9)]
                                            : [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    Color.white.opacity(selectedTab == tab ? 0.35 : 0.15),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Track List

    private var trackListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REFERENCE TRACKS")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(selectedTab.subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 10) {
                ForEach(DuetStudioTrack.mockTracks) { track in
                    trackRow(for: track)
                }
            }
        }
    }

    private func trackRow(for track: DuetStudioTrack) -> some View {
        let isSelected = selectedTrackID == track.id

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: track.artworkGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: track.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: track.artworkGradient.last?.opacity(0.7) ?? .black, radius: 10, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if track.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.yellow.opacity(0.9))
                    }
                }

                Text(track.artist)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    labelChip(icon: "metronome.fill", text: "\(track.tempo)bpm")
                    labelChip(icon: "music.quarternote.3", text: track.key)
                    labelChip(icon: "clock", text: track.duration)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green.opacity(0.9))
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    Color.black.opacity(isSelected ? 0.35 : 0.22)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: isSelected
                            ? [Color.pink.opacity(0.95), Color.cyan.opacity(0.95)]
                            : [Color.white.opacity(0.14), Color.white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.1
                )
        )
        .shadow(color: isSelected ? Color.pink.opacity(0.55) : .clear, radius: 16, x: 0, y: 16)
        .onTapGesture {
            selectedTrackID = track.id
            duetSession.selectedTrack = ReferenceTrack(
                id: track.id,
                title: track.title,
                artist: track.artist,
                duration: track.duration,
                key: track.key,
                tempo: track.tempo
            )
        }
    }

    private func labelChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - Studio Options

    private var studioOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STUDIO OPTIONS")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        ForEach(OutputOption.allCases, id: \.self) { option in
                            Button {
                                outputDevice = option
                                duetSession.outputDevice = option
                            } label: {
                                Text(option.title)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(outputDevice == option ? .white : .white.opacity(0.65))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                outputDevice == option
                                                ? Color.white.opacity(0.14)
                                                : Color.white.opacity(0.06)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { enableCountIn },
                    set: { newValue in
                        enableCountIn = newValue
                        duetSession.enableCountIn = newValue
                    }
                )) {
                    Text("4-beat count-in")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.pink))
                .frame(maxWidth: 170)
            }
        }
    }

    // MARK: - Button Label

    private var startDuetButtonLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 60)
                .shadow(color: Color.pink.opacity(0.7), radius: 22, x: 0, y: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                )

            HStack(spacing: 10) {
                Image(systemName: "mic.and.signal.meter.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Open Duet Mode with selected track")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - Supporting Types

private enum DuetStudioTab: CaseIterable {
    case library
    case uploads
    case savedMixes

    var title: String {
        switch self {
        case .library: return "Library"
        case .uploads: return "Uploads"
        case .savedMixes: return "Saved mixes"
        }
    }

    var subtitle: String {
        switch self {
        case .library: return "From your music library"
        case .uploads: return "Custom audio you’ve added"
        case .savedMixes: return "Previously used duet setups"
        }
    }
}

private struct DuetStudioTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: String
    let key: String
    let tempo: Int
    let isFavorite: Bool
    let iconName: String
    let artworkGradient: [Color]

    static let mockTracks: [DuetStudioTrack] = [
        DuetStudioTrack(
            title: "Selena-style Ballad",
            artist: "Studio preset",
            duration: "3:42",
            key: "E♭ major",
            tempo: 72,
            isFavorite: true,
            iconName: "waveform.circle.fill",
            artworkGradient: [Color.pink, Color.orange]
        ),
        DuetStudioTrack(
            title: "Whitney-style Power Mix",
            artist: "Studio preset",
            duration: "4:10",
            key: "A major",
            tempo: 84,
            isFavorite: false,
            iconName: "sparkles",
            artworkGradient: [Color.purple, Color.blue]
        ),
        DuetStudioTrack(
            title: "Custom Upload #1",
            artist: "Your audio file",
            duration: "2:58",
            key: "B♭ minor",
            tempo: 92,
            isFavorite: false,
            iconName: "tray.and.arrow.up.fill",
            artworkGradient: [Color.cyan, Color.blue]
        )
    ]
}

// MARK: - Preview

struct DuetStudioView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DuetStudioView()
                .environmentObject(TabSelectionStore())
                .environmentObject(DuetSessionStore())
        }
    }
}
