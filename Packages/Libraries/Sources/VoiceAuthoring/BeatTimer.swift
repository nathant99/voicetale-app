import Foundation
import Models

/// Pure-value beat-arc timing for the 5-beat skeleton (Hook 10s / Setup 20s /
/// Rising 30s / Turn 30s / Close 20s, ±20% per beat). All methods are
/// `nonisolated` so callers (UI, the actor session, tests) can reach them
/// without an isolation hop.
nonisolated public enum BeatTimer {
    /// Per-beat tolerance window expressed as a fraction of the target. ±20%
    /// per ``ArcBeat`` per `@Docs/TECHNICAL_DESIGN.md`.
    public static let tolerance: Double = 0.20

    /// Sum of all five beat target durations.
    public static let totalSeconds: Double = ArcBeat.allCases.reduce(0) { $0 + $1.targetSeconds }

    /// The beat ``elapsed`` falls inside, or nil if the timeline has run out.
    public static func beat(forElapsedSeconds elapsed: Double) -> ArcBeat? {
        guard elapsed >= 0 else { return nil }
        var runningTotal: Double = 0
        for beat in ArcBeat.allCases {
            runningTotal += beat.targetSeconds
            if elapsed <= runningTotal {
                return beat
            }
        }
        return nil
    }

    /// Cumulative seconds at the START of ``beat`` (e.g., `.setup` starts at 10s).
    public static func startOffset(for beat: ArcBeat) -> Double {
        var total: Double = 0
        for current in ArcBeat.allCases {
            if current == beat { return total }
            total += current.targetSeconds
        }
        return total
    }

    /// Fraction of the current beat that has elapsed (0…1 within the active
    /// beat; 0 if before the start, 1 if past the end). Returns nil if there
    /// is no active beat.
    public static func progressWithinBeat(elapsedSeconds: Double) -> Double? {
        guard let beat = beat(forElapsedSeconds: elapsedSeconds) else { return nil }
        let start = startOffset(for: beat)
        let target = beat.targetSeconds
        guard target > 0 else { return nil }
        let local = max(0, min(target, elapsedSeconds - start))
        return local / target
    }

    /// Returns true if ``actual`` is within the tolerance window around the
    /// target duration for ``beat``.
    public static func isWithinTolerance(actual: Double, beat: ArcBeat) -> Bool {
        let lower = beat.targetSeconds * (1 - tolerance)
        let upper = beat.targetSeconds * (1 + tolerance)
        return actual >= lower && actual <= upper
    }

    /// Builds a ``BeatSegment`` timeline from a sequence of per-beat actual
    /// durations. Defaults to the target duration when an entry is missing.
    public static func buildTimeline(actualDurations: [ArcBeat: Double]) -> [BeatSegment] {
        ArcBeat.allCases.map { beat in
            BeatSegment(
                beat: beat,
                targetSeconds: beat.targetSeconds,
                actualSeconds: actualDurations[beat] ?? beat.targetSeconds,
                tolerance: tolerance
            )
        }
    }
}
