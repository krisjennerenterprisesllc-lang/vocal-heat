import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct RecordingView: View {
    @StateObject private var engine = LiveAudioEngine()
    @State private var selectedMode: SessionFeedbackMode = .balanced

    @EnvironmentObject private var sessionStore: SessionStore
    @State private var pendingReviewURL: URL?
    @State private var showReview: Bool = false
    @State private var wasSavedFromReview: Bool = false
    @State private var pendingAnalysis: AnalysisStatus = .notAnalyzed

    @State private var showImporter: Bool = false
    @State private var showMicDeniedAlert: Bool = false
    @State private var recordButtonDisabled: Bool = false

    @EnvironmentObject private var tabSelection: TabSelectionStore
    @State private var showSettings: Bool = false

    var body: some View {
        // Minimal container so we can attach modifiers below.
        ZStack {
            LinearGradient(
                colors: [Color.vhBackgroundTop, Color.vhBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Recording")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                // Simple controls for now
                HStack(spacing: 12) {
                    Button {
                        toggleRecordingTapped()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: engine.isRecording ? "stop.fill" : "record.circle.fill")
                            Text(engine.isRecording ? "Stop" : "Record")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(colors: [Color.pink, Color.cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .opacity(recordButtonDisabled ? 0.7 : 1.0)
                    }
                    .disabled(recordButtonDisabled)

                    Button {
                        showImporter = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Import")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(14)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
        }
        // Sheets
        .sheet(isPresented: $showReview, onDismiss: handleReviewDismiss) {
            Group {
                if let url = pendingReviewURL {
                    TakeReviewView(
                        recordedURL: url,
                        feedbackMode: selectedMode,
                        analysis: pendingAnalysis
                    ) { saved in
                        wasSavedFromReview = saved
                    }
                    .environmentObject(sessionStore)
                } else {
                    Color.clear
                }
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
        // Alerts
        .alert("Microphone Access Needed", isPresented: $showMicDeniedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please allow microphone access in Settings to record your voice.")
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Actions

    private func stopAndAnalyze() {
        if engine.isRecording {
            engine.stop()
        }
        if let url = engine.lastRecordingURL {
            Task { await analyzeAndPresent(url) }
        }
    }

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

    // MARK: - Helpers added locally

    private func handleReviewDismiss() {
        // Clear any flags if needed after review closes
    }

    private func preflightMicPermission(_ completion: @escaping (Bool) -> Void) {
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

    private func copyIntoSessionsDirectory(_ sourceURL: URL) throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = docs.appendingPathComponent("VocalHeatSessions", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let destURL = dir.appendingPathComponent(UUID().uuidString + "." + (sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension))
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        try fm.copyItem(at: sourceURL, to: destURL)
        return destURL
    }
}
