import Foundation

/// Delight & Polish "Share-worthy moments" — published-tale certificates.
/// Kid-readable composition derived from a saved ``VoiceTaleEntry`` so the
/// kid can save a SwiftUI-rendered image of the certificate via
/// `ImageRenderer`. Per `@Docs/FEATURE_PLAN.md` § Phase Delight & Polish
/// § Share-worthy moments — published-tale certificates carry-over.
///
/// Per ADR-016 — NO AI image gen for kid-facing surfaces. The certificate
/// is a pure SwiftUI composition rendered to an image at save time; the
/// composition is driven by the Bramble-register one-liner ``headline``
/// + the kid-readable metadata (``title`` / ``moodLabel`` / ``dateLabel``
/// / ``beatBadge``).
///
/// Pure value type + `nonisolated` so the derivation runs without crossing
/// an actor boundary. Anti-shame contract on the headline: never grades a
/// "bad" tale; never frames missing beats or short duration as deficient.
/// Locked by unit tests.
nonisolated public struct PublishedTaleCertificate: Sendable, Hashable {
    /// Kid-chosen tale title — surfaces as the certificate's main line.
    public let title: String
    /// Display label for the tale's mood (e.g. "Funny", "Scary"). The
    /// certificate composition uses this as the chip line above the
    /// headline.
    public let moodLabel: String
    /// Kid-readable date string (e.g. "June 24, 2026"). Derived once at
    /// composition time so the rendered image carries a stable date
    /// even if the kid saves later.
    public let dateLabel: String
    /// "5 of 5 beats" / "3 of 5 beats" — derived from the tale's
    /// in-tolerance beat count. Never frames < 5 as deficient — the
    /// kid completed the arc they completed.
    public let beatBadge: String
    /// Bramble-register one-liner. Pure-function derived; never names a
    /// shame token (locked by tests). The line names something the kid
    /// DID, not something they missed.
    public let headline: String

    public init(
        title: String,
        moodLabel: String,
        dateLabel: String,
        beatBadge: String,
        headline: String
    ) {
        self.title = title
        self.moodLabel = moodLabel
        self.dateLabel = dateLabel
        self.beatBadge = beatBadge
        self.headline = headline
    }
}

extension PublishedTaleCertificate {
    /// Compose a certificate from a saved tale. Pure-function — no
    /// dependencies on environment, locale defaults to current, no
    /// I/O. Callers can substitute a custom `Calendar` + `Locale` for
    /// deterministic test fixtures.
    nonisolated public static func compose(
        from tale: VoiceTaleEntry,
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> PublishedTaleCertificate {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.calendar = calendar
        dateFormatter.dateStyle = .long
        let dateLabel = dateFormatter.string(from: tale.recordedAt)
        let inTolerance = tale.beatTimeline.filter(\.isWithinTolerance).count
        let total = tale.beatTimeline.count
        // Defensive empty-timeline guard — never divide-by-zero on
        // certificate composition.
        let beatBadge = total > 0 ? "\(inTolerance) of \(total) beats" : "Held tale"
        return PublishedTaleCertificate(
            title: tale.title,
            moodLabel: tale.mood.displayLabel,
            dateLabel: dateLabel,
            beatBadge: beatBadge,
            headline: headline(forMood: tale.mood, inToleranceBeats: inTolerance)
        )
    }

    /// Bramble-register one-liner for the certificate. Returns a
    /// mood-specific recognition that names the act of telling without
    /// grading the result. Pure-function + `nonisolated` so callers
    /// can unit-test the matrix without spinning up the SwiftUI host.
    nonisolated public static func headline(
        forMood mood: VoiceTaleMood,
        inToleranceBeats: Int
    ) -> String {
        // Five-beat tales (every beat in tolerance) get a slightly
        // warmer "you held the arc" register. Shorter tales get a
        // mood-specific recognition that honors the telling without
        // naming the missed beats.
        if inToleranceBeats >= 5 {
            switch mood {
            case .funny:  return "A told tale, hook through close — and you carried the laugh."
            case .scary:  return "A told tale, hook through close — and the room leaned in."
            case .tender: return "A told tale, hook through close — and the quiet stayed."
            case .wild:   return "A told tale, hook through close — and the wild had a shape."
            }
        }
        switch mood {
        case .funny:  return "You told something funny — that takes timing."
        case .scary:  return "You told something scary — that takes nerve."
        case .tender: return "You told something tender — that takes care."
        case .wild:   return "You told something wild — that takes voice."
        }
    }
}
