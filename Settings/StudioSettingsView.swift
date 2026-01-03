import SwiftUI

struct StudioSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - State (for now, local-only)

    @State private var selectedLanguage: AppLanguage = .english
    @State private var animationStyle: AnimationStyle = .glowingMic
    @State private var outputPreference: OutputPreference = .device
    @State private var hapticsEnabled: Bool = true
    @State private var autoSaveSessions: Bool = true

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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    header

                    languageSection

                    animationSection

                    audioSection

                    behaviorSection

                    resetSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Studio Settings")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vocal Heat Studio")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.cyan, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Customize how VocalHeat looks, sounds, and responds while you record.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Language

    private var languageSection: some View {
        SettingsCard(title: "Language", subtitle: "Choose how the coach and UI speak to you.") {
            HStack(spacing: 10) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: language.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(language.displayName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedLanguage == language ? .white : .white.opacity(0.75))
                        .background(
                            Capsule()
                                .fill(
                                    selectedLanguage == language
                                    ? Color.white.opacity(0.18)
                                    : Color.white.opacity(0.08)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
    }

    // MARK: - Animation

    private var animationSection: some View {
        SettingsCard(
            title: "Animation Style",
            subtitle: "Control how the pitch visualizer behaves during recording."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(AnimationStyle.allCases, id: \.self) { style in
                    Button {
                        animationStyle = style
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: style.iconName)
                                .font(.system(size: 16, weight: .semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.displayName)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                Text(style.description)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            Spacer()

                            if animationStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 18, weight: .semibold))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.white.opacity(0.35))
                                    .font(.system(size: 18, weight: .regular))
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    if style != AnimationStyle.allCases.last {
                        Divider().background(Color.white.opacity(0.1))
                    }
                }
            }
        }
    }

    // MARK: - Audio Output

    private var audioSection: some View {
        SettingsCard(
            title: "Audio Output",
            subtitle: "Default playback device for VocalHeat."
        ) {
            HStack(spacing: 10) {
                ForEach(OutputPreference.allCases, id: \.self) { option in
                    Button {
                        outputPreference = option
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option.iconName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(option.displayName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(outputPreference == option ? .white : .white.opacity(0.75))
                        .background(
                            Capsule()
                                .fill(
                                    outputPreference == option
                                    ? Color.white.opacity(0.18)
                                    : Color.white.opacity(0.08)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }

            Text("You can still switch devices from Control Center on your iPhone during playback.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 6)
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        SettingsCard(
            title: "Behavior",
            subtitle: "Small details that change how the app feels while you use it."
        ) {
            VStack(spacing: 12) {
                Toggle(isOn: $hapticsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Haptics")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text("Tiny vibrations when you start/stop recording and hit key buttons.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.pink))

                Toggle(isOn: $autoSaveSessions) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-save sessions")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text("Automatically keep every recorded take in your Sessions list.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.cyan))
            }
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Danger zone")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Button {
                resetToDefaults()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset settings to defaults")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.35))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reset Logic

    private func resetToDefaults() {
        selectedLanguage = .english
        animationStyle = .glowingMic
        outputPreference = .device
        hapticsEnabled = true
        autoSaveSessions = true
    }
}

// MARK: - Supporting Types

private enum AppLanguage: CaseIterable {
    case english
    case spanish

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }

    var iconName: String {
        switch self {
        case .english: return "character.book.closed"
        case .spanish: return "globe"
        }
    }
}

private enum AnimationStyle: CaseIterable {
    case glowingMic
    case waveformPulse
    case minimalLine

    var displayName: String {
        switch self {
        case .glowingMic: return "Glowing mic"
        case .waveformPulse: return "Waveform pulse"
        case .minimalLine: return "Minimal line"
        }
    }

    var iconName: String {
        switch self {
        case .glowingMic: return "mic.circle.fill"
        case .waveformPulse: return "waveform.path.ecg"
        case .minimalLine: return "timeline.selection"
        }
    }

    var description: String {
        switch self {
        case .glowingMic:
            return "High-energy neon mic glow that reacts to your voice."
        case .waveformPulse:
            return "Smooth waveform-style motion with subtle color shifts."
        case .minimalLine:
            return "Clean, low-motion line for focus and low distraction."
        }
    }
}

private enum OutputPreference: CaseIterable {
    case device
    case bluetooth

    var displayName: String {
        switch self {
        case .device: return "This device"
        case .bluetooth: return "Bluetooth"
        }
    }

    var iconName: String {
        switch self {
        case .device: return "speaker.wave.2.fill"
        case .bluetooth: return "wave.3.right.circle.fill"
        }
    }
}

// MARK: - Reusable Card

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 14, y: 10)
    }
}

