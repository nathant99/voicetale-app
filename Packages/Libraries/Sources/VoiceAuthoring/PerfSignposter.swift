import Foundation
import os

/// Performance instrumentation for the two Phase 1 perf gates:
///
/// - **Record latency** — `AudioRecorder.start` should resolve in < 50 ms so
///   the kid hears no perceptible delay between tapping Record and the first
///   captured sample. Target: 50 ms.
/// - **Transcript turnaround** — `TranscriptPipeline.transcribe` should resolve
///   in < 2 s for a typical 60 s recording. Target: 2 s.
///
/// Each operation wraps in an `OSSignposter` interval (surfaces in Instruments
/// without Xcode attached) and additionally measures wall-clock elapsed time
/// via `ContinuousClock` so DEBUG builds emit a `[PERF]` log line whenever the
/// operation exceeds its target — making perf regressions visible during
/// normal development without a profiler.
///
/// Subsystem `com.sparkanvil.voicetale` + category `voice-authoring` so
/// `log show --predicate 'subsystem == "com.sparkanvil.voicetale"'` filters
/// to this app's perf stream specifically.
///
/// Begin/end token style is used (rather than a closure wrapper) so callers
/// can sit on any actor without an isolation-hop introducing a non-Sendable
/// closure value across the wrapper boundary.
public enum PerfSignposter {
    /// Canonical signposter — single shared instance per subsystem +
    /// category. Cheap to read (Apple's unified logging owns the store).
    nonisolated public static let signposter: OSSignposter = OSSignposter(
        subsystem: "com.sparkanvil.voicetale",
        category: "voice-authoring"
    )

    /// Named operations. New entries set both the signpost name and the
    /// target threshold above which a `[PERF]` log line emits.
    nonisolated public enum Operation: Sendable, Equatable {
        case recordStart
        case transcriptTurnaround

        public var name: StaticString {
            switch self {
            case .recordStart:          return "record.start"
            case .transcriptTurnaround: return "transcript.turnaround"
            }
        }

        /// Per Phase 1 exit criteria in `@Docs/FEATURE_PLAN.md` § Quality.
        public var targetDuration: Duration {
            switch self {
            case .recordStart:          return .milliseconds(50)
            case .transcriptTurnaround: return .seconds(2)
            }
        }
    }

    /// Sendable handle returned by `begin(_:)` — feed back to `end(_:)`.
    nonisolated public struct Token: Sendable {
        let operation: Operation
        let state: OSSignpostIntervalState
        let start: ContinuousClock.Instant
    }

    /// Open an interval. Pair with `end(_:)` (call from a `defer` to keep
    /// the perf signal even on the error path).
    nonisolated public static func begin(_ operation: Operation) -> Token {
        Token(
            operation: operation,
            state: signposter.beginInterval(operation.name),
            start: ContinuousClock().now
        )
    }

    /// Close the interval, emit Instruments signpost, and log a `[PERF]`
    /// line when elapsed time exceeded the operation's `targetDuration`.
    nonisolated public static func end(_ token: Token) {
        signposter.endInterval(token.operation.name, token.state)
        let elapsed = token.start.duration(to: ContinuousClock().now)
        let exceededTarget = elapsed > token.operation.targetDuration
        DebugLog.perf(operation: token.operation, elapsed: elapsed, exceededTarget: exceededTarget)
    }

    nonisolated enum DebugLog {
        nonisolated static func perf(operation: Operation, elapsed: Duration, exceededTarget: Bool) {
            #if DEBUG
            let marker = exceededTarget ? "OVER" : "ok"
            let thread = Thread.isMainThread ? "main" : "bg(\(Thread.current.name ?? "unnamed"))"
            print("[PERF] \(operation.name) — elapsed=\(elapsed) target=\(operation.targetDuration) \(marker) [thread=\(thread)]")
            #endif
        }
    }
}
