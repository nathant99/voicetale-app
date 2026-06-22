import Foundation
import AVFoundation

/// Pillar Deepening C1 — converts a saved tale's recorded `.m4a` (AAC, native
/// sample rate per `AVAudioEngine.inputNode.outputFormat`) into the canonical
/// **44.1 kHz mono 16-bit PCM CAF** envelope per portfolio audio convention
/// (`@.claude/rules/audio-pipeline.md` + the C1 move definition in
/// `@Docs/HANDOFF_FROM_LABSMITH_PILLAR_DEEPENING_C1_VOICE_EXPORT.md`).
///
/// Apple's CAF container is the canonical "real artifact" for portfolio voice
/// exports: gapless, uncompressed, opens natively in Files / GarageBand /
/// Logic / QuickTime; portable to Mac / iPad school environments without
/// requiring an MP3 transcoder. Parent share is the canonical end-state per
/// Resnick "Projects" + Kafai & Burke "Connected Code" (cited in the handoff).
///
/// **What it is not** (anti-patterns per the handoff):
/// - Not a voice clone — we resample the kid's own recording; the kid's voice
///   is the kid's voice.
/// - Not an MP3 — CAF is canonical; the optional MP3 conversion lives outside
///   this exporter (defer to a Phase 1.1 follow-up if school-share friction
///   surfaces).
/// - Not a screen recording — the source is the audio capture path, not a UI
///   replay.
///
/// **Concurrency**: `actor` so callers can `await` from any context. All work
/// happens off the MainActor. The internal `AVAudioFile` + `AVAudioConverter`
/// calls are not Sendable-friendly across actor hops but stay scoped to a
/// single `export(from:)` invocation, so they don't escape.
public actor VoiceTaleExporter {
    public enum ExporterError: Error, Sendable, Equatable {
        case sourceMissing
        case readFailed(String)
        case writeFailed(String)
        case conversionFailed(String)
    }

    /// Canonical PCM CAF target — 44.1 kHz mono 16-bit per portfolio convention.
    public static let targetSampleRate: Double = 44_100
    public static let targetChannelCount: AVAudioChannelCount = 1
    public static let targetBitDepth: Int = 16

    public init() {}

    /// Converts ``sourceURL`` (any AVAudioFile-readable container: .m4a, .caf,
    /// .wav, .aif, etc.) into a canonical 44.1 kHz mono 16-bit PCM `.caf` next
    /// to the source under an `Exports/` sibling directory. Returns the CAF URL.
    ///
    /// Idempotent: if the export already exists at the target path, returns it
    /// without re-running the converter. The kid can hit "Share as audio" five
    /// times in a row without a perf cost.
    public func exportCAF(from sourceURL: URL) async throws -> URL {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw ExporterError.sourceMissing
        }
        let targetURL = exportURL(forSource: sourceURL)
        if FileManager.default.fileExists(atPath: targetURL.path) {
            return targetURL
        }
        try FileManager.default.createDirectory(
            at: targetURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let sourceFile: AVAudioFile
        do {
            sourceFile = try AVAudioFile(forReading: sourceURL)
        } catch {
            throw ExporterError.readFailed("\(error)")
        }
        let sourceProcessingFormat = sourceFile.processingFormat

        // Target format: 44.1 kHz mono 16-bit PCM interleaved. Settings dict
        // is what AVAudioFile writes to disk; commonFormat is what we hand to
        // it on each write call.
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Self.targetSampleRate,
            channels: Self.targetChannelCount,
            interleaved: true
        ) else {
            throw ExporterError.writeFailed("AVAudioFormat init failed")
        }
        let targetSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: Self.targetSampleRate,
            AVNumberOfChannelsKey: Self.targetChannelCount,
            AVLinearPCMBitDepthKey: Self.targetBitDepth,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        let outputFile: AVAudioFile
        do {
            // CRITICAL: pass commonFormat: + interleaved: explicitly so the
            // file's processingFormat matches the buffer we'll hand to
            // `write(from:)`. Without these, the no-commonFormat initializer
            // defaults the processingFormat to Float32, and AVAudioFile then
            // invokes ExtAudioFile's internal Float32→Int16 converter on
            // every write, which trips `CAVerboseAbort` on iOS sim. See
            // `.claude/rules/audio-pipeline.md` § "iOS: AVAudioFile
            // commonFormat must match the write buffer".
            outputFile = try AVAudioFile(
                forWriting: targetURL,
                settings: targetSettings,
                commonFormat: .pcmFormatInt16,
                interleaved: true
            )
        } catch {
            throw ExporterError.writeFailed("\(error)")
        }

        guard let converter = AVAudioConverter(from: sourceProcessingFormat, to: targetFormat) else {
            throw ExporterError.conversionFailed("AVAudioConverter init failed (\(sourceProcessingFormat) → \(targetFormat))")
        }

        // Read the entire source into a single PCM buffer. VoiceTale recordings
        // cap at ~120s; even at 48 kHz × Float32 × stereo that's ~46MB — well
        // within an iPhone process budget. A single-shot read avoids the
        // streaming-callback dance + the converter-state churn that the chunked
        // approach tripped on simulator AudioToolbox.
        let sourceFrameCount = AVAudioFrameCount(sourceFile.length)
        guard sourceFrameCount > 0 else {
            try? FileManager.default.removeItem(at: targetURL)
            throw ExporterError.writeFailed("source contained zero frames")
        }
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceProcessingFormat,
            frameCapacity: sourceFrameCount
        ) else {
            throw ExporterError.readFailed("AVAudioPCMBuffer alloc failed (input)")
        }
        do {
            try sourceFile.read(into: inputBuffer)
        } catch {
            throw ExporterError.readFailed("\(error)")
        }
        guard inputBuffer.frameLength > 0 else {
            try? FileManager.default.removeItem(at: targetURL)
            throw ExporterError.writeFailed("source contained zero frames after read")
        }

        // Output buffer must be sized for the post-conversion frame count.
        // Add a small headroom (1024 frames) for resampler lookahead state so
        // the converter never returns `.inputRanOut` against a full-but-tight
        // capacity. The actual `frameLength` on the buffer will be set by
        // AVAudioConverter.
        let ratio = Self.targetSampleRate / sourceProcessingFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(
            (Double(inputBuffer.frameLength) * ratio).rounded(.up)
        ) + 1024
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputCapacity
        ) else {
            throw ExporterError.writeFailed("AVAudioPCMBuffer alloc failed (output)")
        }

        var conversionError: NSError?
        var didDeliver = false
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if didDeliver {
                outStatus.pointee = .endOfStream
                return nil
            }
            didDeliver = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
        if status == .error, let conversionError {
            throw ExporterError.conversionFailed("\(conversionError)")
        }
        guard outputBuffer.frameLength > 0 else {
            try? FileManager.default.removeItem(at: targetURL)
            throw ExporterError.conversionFailed("converter produced 0 frames (status=\(status.rawValue))")
        }
        do {
            try outputFile.write(from: outputBuffer)
        } catch {
            throw ExporterError.writeFailed("\(error)")
        }
        return targetURL
    }

    /// Derives the export URL for ``sourceURL`` without performing the
    /// conversion. Exposed for tests + UI code that needs to surface the
    /// expected path before the export completes.
    public nonisolated func exportURL(forSource sourceURL: URL) -> URL {
        let exportsDir = sourceURL.deletingLastPathComponent()
            .appendingPathComponent("Exports", isDirectory: true)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        return exportsDir.appendingPathComponent("\(baseName).caf")
    }
}
