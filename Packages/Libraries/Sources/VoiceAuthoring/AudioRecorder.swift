import Foundation
import AVFoundation
import os

/// Microphone capture pipeline. Drives ``AVAudioEngine`` through the
/// two-part safety rule from `@.claude/rules/concurrency.md`
/// § "Extension to AVAudioNodeTap closures (TWO-PART rule)":
///
/// 1. The tap closure NEVER captures `self` (any flavor).
/// 2. The tap closure is `@Sendable` and writes into an
///    ``OSAllocatedUnfairLock``-backed accumulator.
///
/// Drains happen at ``stop(writingTo:at:)`` time on `@MainActor`. The output
/// file is an AAC-encoded `.m4a` written via ``AVAudioFile``.
///
/// All capture entry points are gated through ``PermissionGate`` — if the
/// `NSMicrophoneUsageDescription` key is missing the recorder refuses to
/// start so the process does not hard-crash on AVAudio invocation (per
/// `@.claude/rules/warnings.md` § "Privacy-Gated Frameworks").
@MainActor
@Observable
public final class AudioRecorder {
    public enum RecorderError: Error, Sendable, Equatable {
        case usageDescriptionMissing
        case permissionDenied
        case engineStartFailed
        case noActiveRecording
        case fileWriteFailed
    }

    public struct StopResult: Sendable, Equatable {
        public let duration: TimeInterval
        public let sampleCount: Int
        public let fileURL: URL?
    }

    public private(set) var isRecording: Bool = false
    public private(set) var startedAt: Date?
    public private(set) var lastError: RecorderError?

    /// Sendable Float-sample accumulator captured by the tap closure. NEVER
    /// touch `self` from the tap; mutate this lock-protected buffer only.
    @ObservationIgnored
    private let bufferAccumulator = OSAllocatedUnfairLock<[Float]>(initialState: [])

    @ObservationIgnored
    private var engine: AVAudioEngine?

    @ObservationIgnored
    private var recordingFormat: AVAudioFormat?

    public init() {}

    /// Starts a fresh capture session. Throws if microphone permission is
    /// missing or denied; throws if the audio engine refuses to start.
    ///
    /// Bracketed by `PerfSignposter.begin/end(.recordStart)` so the operation
    /// surfaces in Instruments + emits a `[PERF]` log line whenever the
    /// elapsed time exceeds the Phase 1 < 50 ms target. The `defer` ensures
    /// the perf signal fires on the error path too.
    public func start(at now: Date = Date()) async throws {
        let token = PerfSignposter.begin(.recordStart)
        defer { PerfSignposter.end(token) }
        try await startInner(at: now)
    }

    private func startInner(at now: Date) async throws {
        guard PermissionGate.hasMicrophoneUsageDescription else {
            lastError = .usageDescriptionMissing
            throw RecorderError.usageDescriptionMissing
        }
        let granted = await PermissionGate.requestMicrophonePermission()
        guard granted else {
            lastError = .permissionDenied
            throw RecorderError.permissionDenied
        }
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Sendable local binding captured by value — the closure must NOT
        // reach back into `self` per the AVAudioNodeTap TWO-PART rule.
        let accumulator = bufferAccumulator
        bufferAccumulator.withLock { $0.removeAll(keepingCapacity: true) }
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { @Sendable buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
            accumulator.withLock { $0.append(contentsOf: samples) }
        }
        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            lastError = .engineStartFailed
            throw RecorderError.engineStartFailed
        }
        self.engine = engine
        self.recordingFormat = format
        self.startedAt = now
        self.isRecording = true
        self.lastError = nil
        DebugLog.audio("AudioRecorder.start — sampleRate=\(format.sampleRate)Hz channels=\(format.channelCount)")
    }

    /// Stops the engine, optionally writes the buffered PCM to ``url`` as
    /// AAC `.m4a`, and returns the captured duration + sample count.
    public func stop(writingTo url: URL? = nil, at now: Date = Date()) throws -> StopResult {
        guard isRecording, let engine, let startedAt, let recordingFormat else {
            lastError = .noActiveRecording
            throw RecorderError.noActiveRecording
        }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        let duration = now.timeIntervalSince(startedAt)
        let drained: [Float] = bufferAccumulator.withLock { state in
            let snapshot = state
            state.removeAll(keepingCapacity: false)
            return snapshot
        }
        self.engine = nil
        self.startedAt = nil
        self.isRecording = false
        var writtenURL: URL?
        if let url {
            do {
                try writePCMToAAC(samples: drained, format: recordingFormat, to: url)
                writtenURL = url
            } catch {
                lastError = .fileWriteFailed
                throw RecorderError.fileWriteFailed
            }
        }
        DebugLog.audio("AudioRecorder.stop — duration=\(String(format: "%.2f", duration))s samples=\(drained.count) wroteFile=\(writtenURL != nil)")
        return StopResult(duration: duration, sampleCount: drained.count, fileURL: writtenURL)
    }

    /// Cancels an in-flight recording without producing output.
    public func cancel() {
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
        startedAt = nil
        isRecording = false
        bufferAccumulator.withLock { $0.removeAll(keepingCapacity: false) }
        DebugLog.audio("AudioRecorder.cancel")
    }

    /// Current elapsed seconds — convenience for SwiftUI timers.
    public func elapsedSeconds(at now: Date = Date()) -> Double {
        guard let startedAt else { return 0 }
        return now.timeIntervalSince(startedAt)
    }

    // MARK: - File output

    private func writePCMToAAC(samples: [Float], format: AVAudioFormat, to url: URL) throws {
        let aacSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderBitRateKey: 64_000,
        ]
        let file = try AVAudioFile(
            forWriting: url,
            settings: aacSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let frameCount = AVAudioFrameCount(samples.count)
        guard
            frameCount > 0,
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channelData = buffer.floatChannelData?[0]
        else {
            throw RecorderError.fileWriteFailed
        }
        buffer.frameLength = frameCount
        samples.withUnsafeBufferPointer { source in
            guard let base = source.baseAddress else { return }
            channelData.update(from: base, count: samples.count)
        }
        try file.write(from: buffer)
    }
}

extension AudioRecorder {
    /// Local lightweight emitter so the VoiceAuthoring target stays
    /// dependency-free of Services. Mirrors the seam in
    /// `Services/DebugLog.swift`.
    enum DebugLog {
        static func audio(_ message: String, _ context: StaticString = #function) {
            #if DEBUG
            let thread = Thread.isMainThread ? "main" : "bg(\(Thread.current.name ?? "unnamed"))"
            print("[AUDIO] \(context) — \(message) [thread=\(thread)]")
            #endif
        }
    }
}
