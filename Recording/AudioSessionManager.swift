import AVFoundation

/// Centralizes AVAudioSession configuration for recording and playback.
/// Use enterRecordingMode() when starting capture, and enterPlaybackMode(forceSpeaker:)
/// right before starting player-based playback.
enum AudioSessionManager {

    /// Configure the session for recording with duplex processing suited for headsets.
    /// Matches your engine’s needs.
    static func enterRecordingMode() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [
                    .allowBluetoothHFP,   // hands‑free headsets
                    .defaultToSpeaker     // prefer speaker when not on headset
                ]
            )
            // Reasonable sample rate for HFP; system may adjust.
            try session.setPreferredSampleRate(32000)
            try session.setActive(true, options: [])
            logCurrentRoute(prefix: "RecordingMode")
            return true
        } catch {
            print("AudioSessionManager: enterRecordingMode error: \(error)")
            return false
        }
    }

    /// Configure the session for playback. If forceSpeaker is true, route to speaker.
    static func enterPlaybackMode(forceSpeaker: Bool = true) {
        let session = AVAudioSession.sharedInstance()
        do {
            // Use .playback for louder, cleaner output without voice processing.
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
            if forceSpeaker {
                // In .playback, output already goes to speaker, but keep explicit override as belt-and-suspenders.
                try session.overrideOutputAudioPort(.speaker)
            }
            logCurrentRoute(prefix: "PlaybackMode")
        } catch {
            print("AudioSessionManager: enterPlaybackMode error: \(error)")
        }
    }

    /// Optional helper if you want to deactivate explicitly.
    static func deactivate(notifyOthers: Bool = true) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: notifyOthers ? [.notifyOthersOnDeactivation] : [])
        } catch {
            print("AudioSessionManager: deactivate error: \(error)")
        }
    }

    /// Lightweight logging to see where audio is going.
    private static func logCurrentRoute(prefix: String) {
        let session = AVAudioSession.sharedInstance()
        let outs = session.currentRoute.outputs.map { $0.portType.rawValue + "(\($0.portName))" }.joined(separator: ", ")
        print("AudioSessionManager[\(prefix)]: category=\(session.category.rawValue) mode=\(session.mode.rawValue) outputs=[\(outs)]")
    }
}
