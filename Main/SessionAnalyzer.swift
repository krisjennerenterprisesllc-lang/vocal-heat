import Foundation
import AVFoundation
import Accelerate

public protocol SessionAnalyzer {
    func analyze(url: URL) async -> AnalysisStatus
}

public struct LocalSessionAnalyzer: SessionAnalyzer {
    public init() {}

    public func analyze(url: URL) async -> AnalysisStatus {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let result = self.performAnalysis(url: url)
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Pipeline

    private func performAnalysis(url: URL) -> AnalysisStatus {
        // Measure duration from asset first (fast)
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            return .error(code: "invalid_duration", message: "Audio duration is invalid.")
        }
        // Enforce a 3-second minimum usable audio
        if durationSeconds < 3 {
            return .tooShort(minimumSeconds: 3)
        }

        // Read PCM samples (mono, float32)
        guard let pcm = readPCM(url: url) else {
            return .error(code: "read_failed", message: "Failed to decode PCM audio.")
        }

        // Frame settings for analysis
        let sampleRate = pcm.sampleRate
        let frameSize = Int(sampleRate * 0.0464) // ~46ms window
        let hopSize = Int(sampleRate * 0.010)    // 10ms hop
        if frameSize <= 0 || hopSize <= 0 || pcm.samples.isEmpty {
            return .error(code: "bad_params", message: "Invalid analysis parameters.")
        }

        // Compute per-frame RMS for envelope stability
        let rms = frameRMS(samples: pcm.samples, frameSize: frameSize, hopSize: hopSize)

        // Compute F0 contour using autocorrelation-based estimator
        let f0Hz = estimateF0Contour(samples: pcm.samples,
                                     sampleRate: sampleRate,
                                     frameSize: frameSize,
                                     hopSize: hopSize)

        // Keep only voiced frames (non-zero F0)
        let voicedF0 = f0Hz.filter { $0 > 0 }

        // Require at least ~2 seconds of voiced frames
        let voicedSeconds = Double(voicedF0.count * hopSize) / sampleRate
        if voicedSeconds < 2.0 {
            return .error(code: "insufficient_voicing", message: "Not enough voiced content for analysis.")
        }

        // Derive sub-metrics from F0 and RMS
        let pitchAccuracy = scorePitchAccuracy(f0Contour: f0Hz)
        let vibratoControl = scoreVibrato(f0Contour: f0Hz, sampleRate: sampleRate, hopSize: hopSize)
        let stability = scoreStability(f0Contour: f0Hz, rms: rms)

        // Expression placeholder: derive from RMS contrast (deterministic)
        let expression = scoreExpression(rms: rms)

        // Build raw metrics (finalScore will be assigned after calibration)
        let raw = SessionMetrics(
            finalScore: nil,
            pitchAccuracy: pitchAccuracy,
            vibratoControl: vibratoControl,
            stability: stability,
            expression: expression,
            duration: durationSeconds,
            errorMessage: nil
        )

        // Calibrate to get finalScore and normalized subs
        let calibrated = CalibratedScoring.calibrate(raw).metrics

        return .analyzed(calibrated)
    }

    // MARK: - PCM decode

    private struct PCMBuffer {
        let samples: [Float]
        let sampleRate: Double
    }

    private func readPCM(url: URL) -> PCMBuffer? {
        do {
            let file = try AVAudioFile(forReading: url)
            guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                             sampleRate: file.fileFormat.sampleRate,
                                             channels: 1,
                                             interleaved: false) else { return nil }

            let frameCount = AVAudioFrameCount(file.length)
            guard frameCount > 0 else { return nil }

            let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try file.read(into: buf)

            // Downmix to mono if needed
            let channelCount = Int(buf.format.channelCount)
            let frameLen = Int(buf.frameLength)
            guard let data = buf.floatChannelData else { return nil }

            var mono = [Float](repeating: 0, count: frameLen)
            if channelCount == 1 {
                // Safe copy when single channel
                for i in 0..<frameLen {
                    mono[i] = data[0][i]
                }
            } else {
                // Average channels
                for i in 0..<frameLen {
                    var sum: Float = 0
                    for ch in 0..<channelCount {
                        sum += data[ch][i]
                    }
                    mono[i] = sum / Float(channelCount)
                }
            }

            return PCMBuffer(samples: mono, sampleRate: format.sampleRate)
        } catch {
            print("LocalSessionAnalyzer: readPCM error: \(error)")
            return nil
        }
    }

    // MARK: - Feature extraction helpers

    private func frameRMS(samples: [Float], frameSize: Int, hopSize: Int) -> [Float] {
        var out: [Float] = []
        var i = 0
        while i + frameSize <= samples.count {
            var sum: Float = 0
            // Simple and safe: sum of squares over the frame
            for j in 0..<frameSize {
                let x = samples[i + j]
                sum += x * x
            }
            let rms = sqrt(sum / Float(frameSize))
            out.append(rms)
            i += hopSize
        }
        return out
    }

    // Simple autocorrelation-based F0 estimator per frame
    private func estimateF0Contour(samples: [Float],
                                   sampleRate: Double,
                                   frameSize: Int,
                                   hopSize: Int) -> [Double] {
        // Voice range ~80–1000 Hz
        let minF: Double = 80
        let maxF: Double = 1000
        let minLag = Int(sampleRate / maxF)
        let maxLag = min(frameSize - 1, Int(sampleRate / minF))

        var f0: [Double] = []
        var i = 0
        let window = hannWindow(size: frameSize)

        while i + frameSize <= samples.count {
            let frame = Array(samples[i..<(i + frameSize)])
            let f = estimateF0ForFrame(frame: frame, window: window, minLag: minLag, maxLag: maxLag, sampleRate: sampleRate)
            f0.append(f)
            i += hopSize
        }
        return f0
    }

    private func estimateF0ForFrame(frame: [Float],
                                    window: [Float],
                                    minLag: Int,
                                    maxLag: Int,
                                    sampleRate: Double) -> Double {
        // Apply window
        var x = frame
        for i in 0..<x.count { x[i] *= window[i] }

        // Energy check to reject silence
        var energy: Float = 0
        for v in x { energy += v * v }
        if energy < 1e-6 { return 0 }

        // Autocorrelation (naive O(N^2) but fine for short frames)
        let n = x.count
        var bestLag = 0
        var bestVal: Float = 0

        for lag in minLag...maxLag {
            var sum: Float = 0
            var k = 0
            while k + lag < n {
                sum += x[k] * x[k + lag]
                k += 1
            }
            if sum > bestVal {
                bestVal = sum
                bestLag = lag
            }
        }

        if bestLag == 0 { return 0 }
        let f0 = sampleRate / Double(bestLag)
        if !f0.isFinite || f0 <= 0 { return 0 }
        return f0
    }

    private func hannWindow(size: Int) -> [Float] {
        var w = [Float](repeating: 0, count: size)
        for n in 0..<size {
            w[n] = 0.5 * (1 - cos(2 * .pi * Float(n) / Float(size - 1)))
        }
        return w
    }

    // MARK: - Sub-metric scoring (heuristic but deterministic)

    // Pitch accuracy: average absolute cents deviation to nearest semitone (12-TET)
    private func scorePitchAccuracy(f0Contour: [Double]) -> Int {
        let centsErrors: [Double] = f0Contour.compactMap { f in
            guard f > 0 else { return nil }
            let midi = 69.0 + 12.0 * log2(f / 440.0)
            let nearest = round(midi)
            let cents = abs((midi - nearest) * 100.0)
            return min(cents, 1000) // clamp extreme
        }
        guard centsErrors.count > 0 else { return 0 }

        let avgCents = centsErrors.reduce(0, +) / Double(centsErrors.count)

        // Map 0–50 cents → 100–0, clamp beyond 50 to low scores
        let score = max(0, min(100, Int(round((50.0 - min(50.0, avgCents)) * 2.0))))
        return score
    }

    // Vibrato control: look for 4–7 Hz modulation in detrended F0, and depth moderation (~0.5–1.0 semitone)
    private func scoreVibrato(f0Contour: [Double], sampleRate: Double, hopSize: Int) -> Int {
        // Convert f0 to semitones for easier depth measurement
        let semis: [Double] = f0Contour.map { f in
            guard f > 0 else { return 0 }
            return 12.0 * log2(f / 440.0) + 69.0
        }
        // Detrend (moving average)
        let smoothed = movingAverage(semis, window: 9)
        let detrended = zip(semis, smoothed).map { (s, m) in s - m }

        // Estimate modulation frequency via zero-crossing rate
        let frameRate = sampleRate / Double(hopSize) // frames per second
        let crossings = zeroCrossings(detrended)
        let zcr = Double(crossings) / (Double(detrended.count) / frameRate) / 2.0 // approx Hz

        // Depth as RMS of detrended in semitones
        let rms = rmsValue(detrended)
        let depthSemis = rms * 2.8 // rough p2p estimate

        // Score: best when rate ~5–6 Hz and depth ~0.5–1.0 semitone
        let rateScore = gaussian(value: zcr, mean: 5.5, sigma: 1.0) * 100
        let depthScore = gaussian(value: depthSemis, mean: 0.8, sigma: 0.5) * 100

        let combined = 0.6 * rateScore + 0.4 * depthScore
        return max(0, min(100, Int(round(combined))))
    }

    private func movingAverage(_ x: [Double], window: Int) -> [Double] {
        guard window > 1, x.count >= window else { return x }
        var out = [Double](repeating: 0, count: x.count)
        var sum = 0.0
        for i in 0..<x.count {
            sum += x[i]
            if i >= window { sum -= x[i - window] }
            let w = min(i + 1, window)
            out[i] = sum / Double(w)
        }
        return out
    }

    private func zeroCrossings(_ x: [Double]) -> Int {
        guard x.count > 1 else { return 0 }
        var count = 0
        for i in 1..<x.count {
            if (x[i - 1] <= 0 && x[i] > 0) || (x[i - 1] >= 0 && x[i] < 0) {
                count += 1
            }
        }
        return count
    }

    private func rmsValue(_ x: [Double]) -> Double {
        guard !x.isEmpty else { return 0 }
        var s = 0.0
        for v in x { s += v * v }
        return sqrt(s / Double(x.count))
    }

    private func gaussian(value x: Double, mean mu: Double, sigma: Double) -> Double {
        let z = (x - mu) / max(1e-6, sigma)
        return exp(-0.5 * z * z)
    }

    // Stability: combine low F0 jitter and steady RMS envelope
    private func scoreStability(f0Contour: [Double], rms: [Float]) -> Int {
        let voiced = f0Contour.filter { $0 > 0 }
        guard voiced.count > 4 else { return 0 }

        // Jitter: relative frame-to-frame deviation (Hz)
        var diffs: [Double] = []
        for i in 1..<voiced.count {
            let a = voiced[i - 1], b = voiced[i]
            diffs.append(abs(b - a))
        }
        let avg = voiced.reduce(0, +) / Double(voiced.count)
        let jitter = (diffs.reduce(0, +) / Double(diffs.count)) / max(1e-6, avg) // normalized

        // RMS steadiness: low variance is more stable (but not perfectly flat)
        let rmsD = rms.map { Double($0) }
        let meanR = rmsD.reduce(0, +) / Double(max(1, rmsD.count))
        let varR = rmsD.reduce(0) { $0 + ( ($1 - meanR) * ($1 - meanR) ) } / Double(max(1, rmsD.count))
        let stdR = sqrt(max(0, varR))

        // Map jitter and envelope std to scores (lower is better)
        let jitterScore = max(0, min(100, Int(round(100 * exp(-8.0 * jitter))))) // strong penalty for jitter
        let envScore = max(0, min(100, Int(round(100 * exp(-6.0 * stdR)))))      // penalize large swings

        // Combine with weights
        let combined = 0.65 * Double(jitterScore) + 0.35 * Double(envScore)
        return max(0, min(100, Int(round(combined))))
    }

    // Expression: simple proxy based on RMS contrast (deterministic)
    private func scoreExpression(rms: [Float]) -> Int {
        guard !rms.isEmpty else { return 0 }
        let r = rms.map { Double($0) }
        let mean = r.reduce(0, +) / Double(r.count)
        let centered = r.map { $0 - mean }
        // Use normalized RMS of centered envelope as contrast
        let numerator = sqrt(centered.reduce(0) { $0 + $1 * $1 } / Double(r.count))
        let denom = max(1e-6, r.max() ?? 1e-6)
        let contrast = numerator / denom // 0..1ish
        // Map moderate contrast to best scores (~0.15–0.35)
        let score = gaussian(value: contrast, mean: 0.25, sigma: 0.12) * 100
        return max(0, min(100, Int(round(score))))
    }
}
