import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

struct DuetRecordingView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var engine = LiveAudioEngine()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Review sheet
    @State private var pendingReviewURL: URL?
    @State private var showReview: Bool = false
    @State private var wasSavedFromReview: Bool = false
    @State private var pendingAnalysis: AnalysisStatus = .notAnalyzed

    // Optional export/share (kept for later)
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    // Cosmetic artist energy animation remains
    @State private var artistEnergy: CGFloat = 0.7

    // Coach mode selection for this take
    @State private var selectedMode: SessionFeedbackMode = .balanced

    // Importer
    @State private var showImporter: Bool = false

    // iPhone polish state
    @State private var showMicDeniedAlert: Bool = false
    @State private var recordButtonDisabled: Bool = false

    @EnvironmentObject private var tabSelection: TabSelectionStore

    private var elapsedSeconds: Int {
        Int(engine.elapsedTime.rounded())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.vhBackgroundTop, Color.vhBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                StudioHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text("Duet Recording")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Sing along with the reference track. We’ll compare your pitch line after.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                modeSelector

                timerAndTrackInfo
                visualizer

                monitorControls

                Spacer(minLength: 8)
                recordControls
                    .accessibilityLabel(engine.isRecording ? "Stop recording" : "Start recording")

                importButton
                    .accessibilityLabel("Import audio")

                Text("You’ll get a side-by-side VocalHeat graph comparing your pitch line to the artist’s after you stop.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topTrailing) {
            BackToStudioPill {
                tabSelection.selected = .studio
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                artistEnergy = 0.7
            }
        }
        .sheet(isPresented: $showReview, onDismiss: handleReviewDismiss) {
            if let url = pendingReviewURL {
                TakeReviewView(
                    recordedURL: url,
                    feedbackMode: selectedMode,
                    analysis: pendingAnalysis
                ) { saved in
                    wasSavedFromReview = saved
                }
                .environmentObject(sessionStore)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
        .sheet(isPresented: $showImporter) {
            DocumentImporter(allowedContentTypes: [.m4a, .mp3]) { result in
                switch result {
                case .success(let pickedURL):
                    Task { await handleImportedFile(from: pickedURL) }
                case .failure:
                    break
                }
            }
        }
        .alert("Microphone Access Needed", isPresented: $showMicDeniedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                #if canImport(UIKit)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
        } message: {
            Text("Please allow microphone access in Settings to record your voice.")
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Actions

    private func toggleRecordingTapped() {
        recordButtonDisabled = true
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                recordButtonDisabled = false
            }
        }

        if engine.isRecording {
            engine.stop()
            if let url = engine.lastRecordingURL {
                Task { await analyzeAndPresent(url) }
            }
        } else {
            preflightMicPermission { granted in
                if granted {
                    engine.start()
                } else {
                    showMicDeniedAlert = true
                }
            }
        }
    }

    private func stopAndAnalyze() {
        if engine.isRecording {
            engine.stop()
        }
        if let url = engine.lastRecordingURL {
            Task { await analyzeAndPresent(url) }
        }
    }

    private func analyzeAndPresent(_ url: URL) async {
        let analyzer = LocalSessionAnalyzer()
        let result = await analyzer.analyze(url: url)
        await MainActor.run {
            wasSavedFromReview = false
            pendingReviewURL = url
            pendingAnalysis = result
            showReview = true
        }
    }

    private func handleImportedFile(from pickedURL: URL) async {
        do {
            let localURL = try copyIntoSessionsDirectory(pickedURL)
            await analyzeAndPresent(localURL)
        } catch {
            print("Import failed: \(error)")
        }
    }
}

// MARK: - Placeholders and helpers for missing pieces

private extension DuetRecordingView {
    // Coach mode selector placeholder
    var modeSelector: some View {
        HStack(spacing: 10) {
            ForEach([SessionFeedbackMode.raw, .balanced, .gentle, .positive], id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.rawValue.capitalized)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    selectedMode == mode
                                    ? Color.white.opacity(0.14)
                                    : Color.white.opacity(0.06)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // Timer + track info placeholder
    var timerAndTrackInfo: some View {
        HStack {
            Label("\(elapsedSeconds)s", systemImage: "timer")
                .foregroundColor(.white)
            Spacer()
            Text("Reference: Selected track")
                .foregroundColor(.white.opacity(0.7))
                .font(.footnote)
        }
    }

    // Simple visualizer placeholder
    var visualizer: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .frame(height: 160)
            .overlay(
                Text(engine.isRecording ? "Recording…" : "Idle")
                    .foregroundColor(.white.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    // Monitor controls placeholder (binds to engine.monitorEnabled/monitorVolume)
    var monitorControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Monitor (headphones)", isOn: $engine.monitorEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .pink))
                .foregroundColor(.white)
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: Binding(
                    get: { Double(engine.monitorVolume) },
                    set: { engine.monitorVolume = Float($0) }
                ), in: 0...1)
            }
            .foregroundColor(.white.opacity(0.8))
        }
    }

    // Record controls placeholder
    var recordControls: some View {
        HStack(spacing: 16) {
            Button {
                toggleRecordingTapped()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: engine.isRecording ? "stop.fill" : "record.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(engine.isRecording ? "Stop" : "Record")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(colors: [Color.pink, Color.cyan], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .opacity(recordButtonDisabled ? 0.7 : 1.0)
            }
            .disabled(recordButtonDisabled)

            Button {
                stopAndAnalyze()
            } label: {
                Text("Analyze")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(14)
            }

            Spacer()
        }
    }

    // Import button placeholder
    var importButton: some View {
        Button {
            showImporter = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "tray.and.arrow.down.fill")
                Text("Import audio")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // Handle review dismiss
    func handleReviewDismiss() {
        // If you want to auto-save or clear state, do it here.
        // For now, just clear export URL flag.
        showShareSheet = false
    }

    // Copy imported file into Documents/VocalHeatSessions
    func copyIntoSessionsDirectory(_ sourceURL: URL) throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = docs.appendingPathComponent("VocalHeatSessions", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let destURL = dir.appendingPathComponent(UUID().uuidString + "." + (sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension))
        // If the source is a security-scoped URL, you may need startAccessingSecurityScopedResource in a real app.
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        try fm.copyItem(at: sourceURL, to: destURL)
        return destURL
    }

    // Microphone permission helper
    func preflightMicPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                AVAudioApplication.requestRecordPermission { granted in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                completion(true)
            case .denied:
                completion(false)
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }
}

// MARK: - ShareSheet wrapper (iOS only)

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
