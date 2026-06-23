import Foundation
import SwiftData
import Models
import ForgeSpotlight

/// Phase 2 saved-tale Spotlight indexing per `@.claude/rules/forgekit.md`
/// § ForgeSpotlight. Surfaces the kid's anthology to iOS Spotlight so a
/// saved tale can be discovered from the OS search surface without the
/// kid having to navigate the app's tabs.
///
/// CoreSpotlight indexing is permission-less (no Info.plist entry / no
/// runtime prompt). The indexer is COPPA-safe by construction: the only
/// payload that travels is the kid-chosen title + mood label + recorded
/// date — the transcript NEVER leaves the persistence layer, and audio
/// stays on-device.
///
/// The actor-backed `ForgeSpotlightIndexer` lives in ForgeKit; this thin
/// wrapper converts ``VoiceTaleEntry`` rows into `SpotlightIndexable`
/// payloads + provides idempotent batch indexing.
public enum VoiceTaleSpotlightIndexer {
    /// Stable Spotlight domain — used so a full `deindexDomain` can clear
    /// every previously-indexed VoiceTale entry in one call (e.g., when
    /// the kid taps "Erase all saved tales" in a future parent surface).
    public static let domainIdentifier = "com.sparkanvil.voicetale.tales"

    /// Index every saved tale in the kid's anthology. Idempotent — repeated
    /// calls overwrite the prior `CSSearchableItem` for the same id.
    ///
    /// Per `@.claude/rules/swiftdata.md` § "ModelContext injection — Pass
    /// from view's onAppear to ViewModel, NOT in init", callers pass the
    /// context per call rather than at init.
    public static func indexAllTales(in context: ModelContext) async {
        let tales = VoiceTaleStore.fetchTales(in: context)
        let items = tales.map(TaleSpotlightItem.init(tale:))
        do {
            let indexer = ForgeSpotlightIndexer(domainIdentifier: domainIdentifier)
            try await indexer.index(items)
            DebugLog.state(
                "VoiceTaleSpotlightIndexer.indexAllTales — indexed \(items.count) tale(s)"
            )
        } catch {
            DebugLog.data(
                "VoiceTaleSpotlightIndexer.indexAllTales — failed",
                error: error
            )
        }
    }

    /// Drop a single tale from the index. Called when the kid deletes a
    /// tale so the Spotlight surface stays in sync with the anthology.
    public static func deindex(taleID: UUID) async {
        do {
            let indexer = ForgeSpotlightIndexer(domainIdentifier: domainIdentifier)
            try await indexer.deindex(ids: [taleID.uuidString])
        } catch {
            DebugLog.data(
                "VoiceTaleSpotlightIndexer.deindex — failed for id=\(taleID)",
                error: error
            )
        }
    }

    /// Clear every saved-tale entry from the kid's Spotlight surface.
    /// Reserved for an erase-all surface (parent control). Currently
    /// unused but kept on the public API so a future settings affordance
    /// can wire it without a re-roll.
    public static func deindexAllTales() async {
        do {
            let indexer = ForgeSpotlightIndexer(domainIdentifier: domainIdentifier)
            try await indexer.deindexDomain(domainIdentifier)
        } catch {
            DebugLog.data(
                "VoiceTaleSpotlightIndexer.deindexAllTales — failed",
                error: error
            )
        }
    }
}

/// Value-type projection of ``VoiceTaleEntry`` for Spotlight indexing.
/// Built from the kid-facing fields ONLY — transcript stays in the
/// SwiftData store, audio stays on disk. Mood + recorded date land in
/// `spotlightKeywords` so a Spotlight search for "tender" or "tonight"
/// can surface the right tale.
nonisolated public struct TaleSpotlightItem: SpotlightIndexable {
    public let id: UUID
    public let title: String
    public let mood: VoiceTaleMood
    public let recordedAt: Date

    public init(id: UUID, title: String, mood: VoiceTaleMood, recordedAt: Date) {
        self.id = id
        self.title = title
        self.mood = mood
        self.recordedAt = recordedAt
    }

    public init(tale: VoiceTaleEntry) {
        self.init(
            id: tale.id,
            title: tale.title,
            mood: tale.mood,
            recordedAt: tale.recordedAt
        )
    }

    public var spotlightID: String { id.uuidString }

    public var spotlightTitle: String { title }

    public var spotlightDescription: String {
        let dateText = Self.dateFormatter.string(from: recordedAt)
        return "VoiceTale \u{2022} \(mood.displayLabel) \u{2022} \(dateText)"
    }

    public var spotlightKeywords: [String] {
        [
            "VoiceTale",
            "tale",
            "story",
            mood.rawValue,
            mood.displayLabel,
        ]
    }

    public var spotlightThumbnailName: String? { nil }

    /// Module-scoped formatter so the Spotlight description format stays
    /// stable across reindex calls (and is testable independently).
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
