import Testing
import Foundation
@testable import VoiceAuthoring

/// Smoke tests for ``PerfSignposter`` — the instrumentation seam wrapped
/// around `AudioRecorder.start` + `TranscriptPipeline.transcribe`. Asserts
/// the public surface is callable + that the per-operation `targetDuration`
/// values match the Phase 1 exit criteria in
/// `@Docs/FEATURE_PLAN.md` § Quality (< 50 ms record / < 2 s transcript).
@Suite("PerfSignposter")
struct PerfSignposterTests {
    @Test func recordStartTargetIs50ms() {
        let target = PerfSignposter.Operation.recordStart.targetDuration
        #expect(target == .milliseconds(50))
    }

    @Test func transcriptTurnaroundTargetIs2s() {
        let target = PerfSignposter.Operation.transcriptTurnaround.targetDuration
        #expect(target == .seconds(2))
    }

    @Test func beginEndIsCallable() {
        // The signposter is registered with Apple's unified logging and is
        // safe to invoke from any context. Calling begin/end ensures the
        // wrapper doesn't throw or trap.
        let token = PerfSignposter.begin(.recordStart)
        PerfSignposter.end(token)
    }

    @Test func beginEndCarriesOperation() {
        let token = PerfSignposter.begin(.transcriptTurnaround)
        #expect(token.operation == .transcriptTurnaround)
        PerfSignposter.end(token)
    }
}
