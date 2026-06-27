import Foundation

/// Per-kit "last emitted ``MasteryBand``" log used by the Phase B
/// ``VoiceTaleAnalyticsEvent/kitMasteryAdvanced(kit:fromBand:toBand:)``
/// surface to coalesce redundant emissions across cold launches.
///
/// Why this exists — per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`
/// § Phase B coalescing + the NINETEENTH-round handoff priority #2:
/// the existing in-memory `fromBand != toBand` guard fires every time
/// the kid's score crosses a quartile boundary. A kid bouncing around
/// the meeting/deepening edge (or playing many kits in a session)
/// produces a noisy wire surface — repeated `meeting → deepening` and
/// `deepening → meeting` pairs as the score wobbles. The cohort signal
/// the team actually wants is "the kid is at `deepening` now" — not
/// "the kid crossed the boundary 7 times this afternoon".
///
/// The log records, per kit, the last band we successfully *emitted*
/// (not the current in-memory band). The view-side @AppStorage binding
/// is JSON-encoded so the log survives cold launches; the value type
/// keeps the encode/decode + suppression check pure-function so the
/// invariants are testable without a SwiftUI host.
///
/// Anti-defeat: a malformed JSON value (e.g., a future migration that
/// changes the key shape) degrades to an empty log so a single corrupt
/// write never permanently suppresses emissions — the worst case is a
/// few one-time re-emissions on next launch. This mirrors the
/// `ReflectionRetentionPolicy.clampedRetentionDays(_:)` discipline.
///
/// Anti-PII: the stored shape is `[kit raw value : band raw value]`.
/// The log itself NEVER travels — only the suppression decision does.
/// The emitted analytics event keeps the existing band-only payload
/// (per the wire-shape lock-down test in
/// ``KitMasteryQuizWiringTests/kitMasteryAdvancedNeverCarriesRawScoreKey``).
public nonisolated struct KitMasteryBandLog: Sendable, Hashable, Codable {
    /// Internal store. Keyed by ``KitID`` raw value (Int) so this
    /// type stays free of any dependency on `ForgeMasteryEngine`
    /// (Models cannot import ForgeKit modules per the SPM dep graph).
    /// Value is ``MasteryBand`` raw value (String).
    private var entries: [Int: String]

    /// Public empty initializer — the canonical starting state.
    public init() {
        self.entries = [:]
    }

    /// Decode-from-`@AppStorage`-shaped JSON. Empty string and any
    /// malformed value both degrade to an empty log so a corrupt
    /// write never permanently suppresses emissions.
    public init(json: String) {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Int: String].self, from: data)
        else {
            self.entries = [:]
            return
        }
        self.entries = decoded
    }

    /// JSON encoding suitable for `@AppStorage` round-trip. Empty log
    /// encodes to `""` so the @AppStorage default never grows when no
    /// emissions have happened yet.
    public func encoded() -> String {
        guard !entries.isEmpty,
              let data = try? JSONEncoder().encode(entries),
              let s = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return s
    }

    /// Last emitted band for `kit`, or `nil` when no emission has been
    /// recorded yet (cold-launch / new-kid / never-crossed-a-band).
    public func lastBand(forKit kit: Int) -> String? {
        entries[kit]
    }

    /// `true` when the new `toBand` differs from the logged last band
    /// for `kit` — i.e., emission should proceed. Returns `true` when
    /// there is no logged band (first emission per kit per install).
    public func shouldEmit(forKit kit: Int, toBand: String) -> Bool {
        entries[kit] != toBand
    }

    /// Returns a new log with `band` recorded for `kit`. The caller
    /// is responsible for re-encoding via `encoded()` + writing the
    /// JSON back to its `@AppStorage` binding.
    public func recording(forKit kit: Int, band: String) -> KitMasteryBandLog {
        var next = self
        next.entries[kit] = band
        return next
    }
}
