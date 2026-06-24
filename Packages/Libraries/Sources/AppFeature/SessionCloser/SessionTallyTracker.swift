import Foundation
import Models
import Observation

/// Tracks per-sitting engagement counters so ``SessionCloserView`` can render
/// an honest recap when the session soft-cap fires. Lives at AppRootView
/// scope; reset implicitly on cold launch (the `@State` storage starts fresh
/// every time the app process boots) and explicitly when the kid dismisses
/// the closer sheet.
///
/// Per `@Docs/FEATURE_PLAN.md` § Engagement Foundation → "Session targeting:
/// 10-15 minute sessions with gentle ending summary".
///
/// Anti-shame guard: the tally NEVER scolds — zero-tale sittings are valid;
/// the recap copy in ``SessionCloserView.openingLine(for:)`` honors them.
@Observable @MainActor
public final class SessionTallyTracker {
    public private(set) var talesSavedThisSession: Int = 0
    public private(set) var badgesEarnedThisSession: [String] = []
    /// Mood-register slugs the kid has dwelled on in the tradition gallery
    /// during the current sitting. Populated when ``TraditionGalleryView``
    /// expands a card (via ``recordTraditionExpanded(slug:)``); read by
    /// ``TellView.deriveSurpriseMomentIfAny()`` so the
    /// ``SurpriseMoment/traditionEchoSameSession`` archetype fires when
    /// today's tale mood's register matches one of the dwelled-on
    /// traditions. Reset on closer dismiss alongside the other counters.
    public private(set) var traditionRegisterSlugsSeen: Set<String> = []

    public init() {}

    public func recordTaleSaved() {
        talesSavedThisSession += 1
    }

    public func recordBadgeEarned(title: String) {
        // De-dup — a single celebration session may re-fire identical badges
        // when the kid trips multiple thresholds in one save. Keep the recap
        // honest: one line per unique badge.
        guard badgesEarnedThisSession.contains(title) == false else { return }
        badgesEarnedThisSession.append(title)
    }

    /// Records the kid's expansion of a tradition card in the gallery.
    /// Unions the tradition's mood-register slugs (per
    /// ``TraditionEntry/moodRegisterSlugs(forSlug:)``) into the seen
    /// set so the within-session echo signal becomes detectable.
    /// Unknown slugs are a silent no-op — the tracker never errors on
    /// catalog drift.
    public func recordTraditionExpanded(slug: String) {
        let registerSlugs = TraditionEntry.moodRegisterSlugs(forSlug: slug)
        guard registerSlugs.isEmpty == false else { return }
        traditionRegisterSlugsSeen.formUnion(registerSlugs)
    }

    /// Pure-function helper for the within-session tradition-echo signal.
    /// Returns `true` when ``traditionRegisterSlugsSeen`` contains the
    /// ``VoiceTaleMood/registerSlug`` of the just-finished tale.
    /// Read-only — callers must not mutate the tracker through this path.
    public func traditionEchoEligible(for mood: VoiceTaleMood) -> Bool {
        traditionRegisterSlugsSeen.contains(mood.registerSlug)
    }

    public func reset() {
        talesSavedThisSession = 0
        badgesEarnedThisSession.removeAll()
        traditionRegisterSlugsSeen.removeAll()
    }
}
