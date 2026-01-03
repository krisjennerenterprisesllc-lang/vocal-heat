import Foundation
import AVFoundation
import Combine

/// LiveAudioEngine
/// - Real device: captures mic, writes AAC (.m4a), computes level, handles permissions/interruptions, supports optional monitoring and MP3 export via a separate manager.
/// - Simulator: generates fake levels and elapsed time (no disk I/O) for UI testing.
final class LiveAudioEngine: ObservableObject {

    // MARK: - Published state for UI

    @Published var isRecording: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    /// Approximate input level for UI: 0.0 – 1.0
    @Published var level: Float = 0.0

    /// URL of the last completed recording (.m4a). Nil while recording or if start failed.
    @Published var lastRecordingURL: URL?

    /// Monitoring: whether mic input should be routed to output (headphones recommended)
    @Published var monitorEnabled: Bool = false {
        didSet { updateMonitorRouting() }
    }

    /// Monitoring volume 0.0–1.0
    @Published var monitorVolume: Float = 0.5 {
        didSet { monitorMixerNode.outputVolume = monitorEnabled ? monitorVolume : 0.0 }
    }

    // MARK: - Private audio objects (device)

    private let engine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    // Render path to keep engine running reliably
    private let silentPlayer = AVAudioPlayerNode()
    private var silentBuffer: AVAudioPCMBuffer?

    // Monitoring path: input -> monitorMixerNode -> mainMixer
    private let monitorMixerNode = AVAudioMixerNode()

    // File writing
    private var fileOutput: AVAudioFile?
    private var currentRecordingURL: URL?

    // Timers
    private var levelTimer: Timer?
    private var simulatorTimer: Timer?

    // State flags
    private var hasInstalledTap = false
    private var observersInstalled = false
    private var monitorConnected = false

    // MP3 exporting (injected for testability; default provided)
    private let mp3Exporter: MP3Exporting

    init(mp3Exporter: MP3Exporting = MP3ExportManager()) {
        self.mp3Exporter = mp3Exporter
    }

    // MARK: - Public control

    func start() {
        #if targetEnvironment(simulator)
        guard !isRecording else { return }
        startSimulatorStub()
        #else
        guard !isRecording else { return }

        requestMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if granted {
                    self.startAudioSessionAndEngine()
                } else {
                    print("LiveAudioEngine: microphone permission denied.")
                    self.cleanupAfterStop()
                }
            }
        }
        #endif
    }

    func stop() {
        #if targetEnvironment(simulator)
        stopSimulatorStub()
        return
        #else
        guard isRecording else { return }

        engine.stop()
        removeInputTap()
        teardownSilentPlayerIfNeeded()
        disconnectMonitor()

        // Close file
        fileOutput = nil

        cleanupAfterStop()
        deactivateSession()
        removeObserversIfNeeded()

        // Publish completed file URL
        lastRecordingURL = currentRecordingURL
        currentRecordingURL = nil
        #endif
    }

    deinit {
        levelTimer?.invalidate()
        simulatorTimer?.invalidate()
        engine.stop()
        removeObserversIfNeeded()
    }

    // MARK: - Export

    /// Exports the given .m4a file to MP3 at the specified destination URL.
    /// This uses a placeholder manager until you integrate an MP3 encoder (e.g., LAME).
    func exportToMP3(inputM4AURL: URL, outputMP3URL: URL) async throws {
        try await mp3Exporter.exportToMP3(inputURL: inputM4AURL, outputURL: outputMP3URL)
    }

    // MARK: - Simulator stub

    private func startSimulatorStub() {
        guard !isRecording else { return }
        print("LiveAudioEngine: Simulator stub – generating fake levels.")
        isRecording = true
        elapsedTime = 0
        lastRecordingURL = nil

        simulatorTimer?.invalidate()
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            self.elapsedTime += 0.1
            // Generate a smooth fake level between 0.2 and 0.95
            let t = Float(self.elapsedTime)
            let base = (sin(t * 2.0) + 1.0) / 2.0 // 0...1
            self.level = 0.2 + base * 0.75
        }
        if let timer = simulatorTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopSimulatorStub() {
        guard isRecording else { return }
        simulatorTimer?.invalidate()
        simulatorTimer = nil
        cleanupAfterStop()
        print("LiveAudioEngine: Simulator stub stopped.")
        // Simulator doesn’t write files; keep lastRecordingURL nil.
    }

    // MARK: - Real device start flow

    private func startAudioSessionAndEngine() {
        // Use centralized session configuration for recording.
        guard AudioSessionManager.enterRecordingMode() else {
            print("LiveAudioEngine: failed to configure audio session – aborting start()")
            return
        }

        installObserversIfNeeded()

        // Attach monitor mixer and silent player
        if !engine.attachedNodes.contains(monitorMixerNode) {
            engine.attach(monitorMixerNode)
        }
        prepareSilentPlayerIfNeeded()

        // Prepare file destination
        do {
            let url = try makeNewRecordingURL()
            currentRecordingURL = url
            try prepareFileWriter(at: url)
        } catch {
            print("LiveAudioEngine: failed to prepare file writer: \(error)")
            cleanupAfterStop()
            deactivateSession()
            return
        }

        // Monitoring route (default off)
        connectMonitorIfNeeded()
        updateMonitorRouting()

        installInputTapIfNeeded()

        do {
            try engine.start()
            isRecording = true
            elapsedTime = 0
            lastRecordingURL = nil
            startLevelTimer()
            print("LiveAudioEngine: engine started; writing to \(currentRecordingURL?.lastPathComponent ?? "unknown")")
        } catch {
            print("LiveAudioEngine: failed to start engine: \(error)")
            cleanupAfterStop()
            deactivateSession()
        }
    }

    // MARK: - Permissions

    private func requestMicrophonePermission(_ completion: @escaping (Bool) -> Void) {
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

    // MARK: - Audio session

    private func deactivateSession() {
        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("LiveAudioEngine: failed to deactivate session: \(error)")
        }
    }

    // MARK: - Observers (interruptions, route changes)

    private func installObserversIfNeeded() {
        guard !observersInstalled else { return }
        observersInstalled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }

    private func removeObserversIfNeeded() {
        guard observersInstalled else { return }
        observersInstalled = false
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: audioSession)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: audioSession)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            print("LiveAudioEngine: interruption began")
            stop()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("LiveAudioEngine: interruption ended, resuming")
                    start()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        print("LiveAudioEngine: route change reason \(reason.rawValue)")
        switch reason {
        case .oldDeviceUnavailable, .categoryChange, .override, .unknown, .routeConfigurationChange, .wakeFromSleep, .noSuitableRouteForCategory:
            stop()
        case .newDeviceAvailable:
            stop()
            start()
        @unknown default:
            break
        }
    }

    // MARK: - Render path (silent player)

    private func prepareSilentPlayerIfNeeded() {
        if !engine.attachedNodes.contains(silentPlayer) {
            engine.attach(silentPlayer)
        }
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        if engine.outputConnectionPoints(for: silentPlayer, outputBus: 0).isEmpty {
            engine.connect(silentPlayer, to: mainMixer, format: format)
        }

        let frameCount: AVAudioFrameCount = 1024
        if silentBuffer == nil, let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            buf.frameLength = frameCount
            if let channelData = buf.floatChannelData {
                let channels = Int(format.channelCount)
                for c in 0..<channels {
                    memset(channelData[c], 0, Int(frameCount) * MemoryLayout<Float>.size)
                }
            }
            silentBuffer = buf
        }

        startSilentPlayerIfNeeded()
    }

    private func startSilentPlayerIfNeeded() {
        guard let buffer = silentBuffer else { return }
        if !silentPlayer.isPlaying {
            silentPlayer.play()
        }
        silentPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
    }

    private func teardownSilentPlayerIfNeeded() {
        if silentPlayer.isPlaying {
            silentPlayer.stop()
        }
        if engine.attachedNodes.contains(silentPlayer) {
            engine.detach(silentPlayer)
        }
        silentBuffer = nil
    }

    // MARK: - Monitoring

    private func connectMonitorIfNeeded() {
        guard !monitorConnected else { return }

        let input = engine.inputNode
        let mainMixer = engine.mainMixerNode
        let inputFormat = input.inputFormat(forBus: 0)

        if engine.outputConnectionPoints(for: monitorMixerNode, outputBus: 0).isEmpty {
            engine.connect(monitorMixerNode, to: mainMixer, format: inputFormat)
        }
        if engine.inputConnectionPoint(for: monitorMixerNode, inputBus: 0) == nil {
            engine.connect(input, to: monitorMixerNode, format: inputFormat)
        }

        monitorConnected = true
    }

    private func disconnectMonitor() {
        guard monitorConnected else { return }
        engine.disconnectNodeInput(monitorMixerNode)
        engine.disconnectNodeOutput(monitorMixerNode)
        monitorConnected = false
    }

    private func updateMonitorRouting() {
        // Simple approach: keep connections but set volume to 0 when disabled
        monitorMixerNode.outputVolume = monitorEnabled ? monitorVolume : 0.0
    }

    // MARK: - File management

    private func makeNewRecordingURL() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = docs.appendingPathComponent("VocalHeatSessions", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let filename = UUID().uuidString + ".m4a"
        return dir.appendingPathComponent(filename)
    }

    private func prepareFileWriter(at url: URL) throws {
        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)

        // Create an AAC format matching sample rate/channel count of input
        guard let aacFormat = AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVEncoderBitRateKey: 192_000
        ]) else {
            throw NSError(domain: "LiveAudioEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AAC format"])
        }

        fileOutput = try AVAudioFile(forWriting: url, settings: aacFormat.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    }

    // MARK: - Tap & level monitoring

    private func installInputTapIfNeeded() {
        guard !hasInstalledTap else { return }

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)

        guard format.channelCount > 0 else {
            print("LiveAudioEngine: no input channels available – cannot record.")
            return
        }

        input.installTap(onBus: 0,
                         bufferSize: 1024,
                         format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            // Write to file (if available)
            if let file = self.fileOutput {
                do {
                    try file.write(from: buffer)
                } catch {
                    print("LiveAudioEngine: file write error: \(error)")
                }
            }

            // Level metering
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            var sum: Float = 0
            if frameLength > 0 {
                for i in 0..<frameLength {
                    let x = channelData[i]
                    sum += x * x
                }
            }
            let rms = frameLength > 0 ? sqrt(sum / Float(frameLength)) : 0
            let avgPower = 20 * log10f(rms + 1e-7)
            let normalized = max(0, min(1, (avgPower + 60) / 60))

            DispatchQueue.main.async {
                self.level = normalized
            }
        }

        hasInstalledTap = true
    }

    private func removeInputTap() {
        guard hasInstalledTap else { return }
        engine.inputNode.removeTap(onBus: 0)
        hasInstalledTap = false
    }

    private func startLevelTimer() {
        levelTimer?.invalidate()

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            self.elapsedTime += 0.1
        }

        if let timer = levelTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func cleanupAfterStop() {
        isRecording = false
        levelTimer?.invalidate()
        levelTimer = nil
        level = 0
    }
}
