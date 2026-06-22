import Testing
import Foundation
import AVFoundation
@testable import Services

@Suite("VoiceTaleExporter")
struct VoiceTaleExporterTests {
    @Test func exportURLIsSiblingExportsDirectoryCAF() {
        let exporter = VoiceTaleExporter()
        let source = URL(fileURLWithPath: "/tmp/Tales/abc.m4a")
        let target = exporter.exportURL(forSource: source)
        #expect(target.lastPathComponent == "abc.caf")
        #expect(target.deletingLastPathComponent().lastPathComponent == "Exports")
        #expect(target.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent == "Tales")
    }

    @Test func exportURLPreservesBaseNameAndOverridesExtension() {
        let exporter = VoiceTaleExporter()
        let cafSource = URL(fileURLWithPath: "/tmp/Tales/some-uuid-12345.caf")
        let aacSource = URL(fileURLWithPath: "/tmp/Tales/aac-tale.m4a")
        let wavSource = URL(fileURLWithPath: "/tmp/Tales/wave-recording.wav")
        #expect(exporter.exportURL(forSource: cafSource).lastPathComponent == "some-uuid-12345.caf")
        #expect(exporter.exportURL(forSource: aacSource).lastPathComponent == "aac-tale.caf")
        #expect(exporter.exportURL(forSource: wavSource).lastPathComponent == "wave-recording.caf")
    }

    @Test func exportThrowsSourceMissingWhenFileDoesNotExist() async {
        let exporter = VoiceTaleExporter()
        let bogus = URL(fileURLWithPath: "/tmp/VoiceTaleExporterTests/does-not-exist-\(UUID().uuidString).m4a")
        await #expect(throws: VoiceTaleExporter.ExporterError.sourceMissing) {
            _ = try await exporter.exportCAF(from: bogus)
        }
    }

    @Test func exportConvertsSineWaveSourceToCanonicalCAF() async throws {
        // Generate a 0.25-second mono sine wave at 16 kHz as a CAF source.
        // 16 kHz is intentionally NOT 44.1 kHz so the test exercises the
        // sample-rate-conversion path of AVAudioConverter. (Source format is
        // CAF because AVAudioFile lets us write float PCM cleanly without
        // needing AAC encoding via AVAssetWriter.)
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoiceTaleExporterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        let source = temp.appendingPathComponent("source.caf")
        try writeSineWaveCAF(to: source, sampleRate: 16_000, durationSeconds: 0.25, frequency: 440)

        let exporter = VoiceTaleExporter()
        let exported = try await exporter.exportCAF(from: source)

        // The exporter writes under `<source-dir>/Exports/<base>.caf`. Confirm
        // both the URL shape and the file's presence + format.
        #expect(exported.deletingLastPathComponent().lastPathComponent == "Exports")
        #expect(exported.lastPathComponent == "source.caf")
        #expect(FileManager.default.fileExists(atPath: exported.path))

        let exportedFile = try AVAudioFile(forReading: exported)
        let format = exportedFile.fileFormat
        #expect(format.sampleRate == VoiceTaleExporter.targetSampleRate, "Expected 44.1 kHz, got \(format.sampleRate)")
        #expect(format.channelCount == VoiceTaleExporter.targetChannelCount)
        // PCM Int16 has bit-depth 16 — surface via the format description.
        let stream = format.streamDescription.pointee
        #expect(Int(stream.mBitsPerChannel) == VoiceTaleExporter.targetBitDepth)
    }

    @Test func exportIsIdempotentOnRepeatedCalls() async throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("VoiceTaleExporterTests-idempotent-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        let source = temp.appendingPathComponent("source.caf")
        try writeSineWaveCAF(to: source, sampleRate: 24_000, durationSeconds: 0.1, frequency: 220)

        let exporter = VoiceTaleExporter()
        let firstURL = try await exporter.exportCAF(from: source)
        let firstAttrs = try FileManager.default.attributesOfItem(atPath: firstURL.path)
        let firstMTime = firstAttrs[.modificationDate] as? Date

        // Sleep ≥1ms to ensure mtime would tick if the file were rewritten;
        // the idempotency contract says it should NOT be rewritten.
        try await Task.sleep(nanoseconds: 50_000_000)

        let secondURL = try await exporter.exportCAF(from: source)
        let secondAttrs = try FileManager.default.attributesOfItem(atPath: secondURL.path)
        let secondMTime = secondAttrs[.modificationDate] as? Date

        #expect(firstURL == secondURL)
        #expect(firstMTime == secondMTime, "Idempotent export must not rewrite the file on repeat calls")
    }

    // MARK: - Helpers

    private func writeSineWaveCAF(
        to url: URL,
        sampleRate: Double,
        durationSeconds: Double,
        frequency: Double
    ) throws {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "VoiceTaleExporterTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "format alloc failed"])
        }
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: true,
        ]
        let file = try AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        guard
            frameCount > 0,
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channelData = buffer.floatChannelData?[0]
        else {
            throw NSError(domain: "VoiceTaleExporterTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "buffer alloc failed"])
        }
        buffer.frameLength = frameCount
        let twoPiOverRate = (2 * Double.pi * frequency) / sampleRate
        for frame in 0..<Int(frameCount) {
            channelData[frame] = Float(sin(Double(frame) * twoPiOverRate) * 0.3)
        }
        try file.write(from: buffer)
    }
}
