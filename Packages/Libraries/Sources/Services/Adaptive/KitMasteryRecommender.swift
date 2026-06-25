import Foundation
import ForgeMasteryEngine
import Models

/// Phase C of the ForgeMasteryEngine integration per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase C. Wraps
/// `ForgeMasteryEngine.NextProblemPicker<KitID, KitID>` (problem IDs
/// are the same `KitID`s; VoiceTale has one "problem" per kit) and
/// projects each `Recommendation` into a kid-facing
/// `KitMasteryRecommendation` carrying the resolved Bramble copy from
/// ``KitMasteryCopyCatalog``.
///
/// The recommender is a pure value-type service — every method is
/// `nonisolated` so previews + tests can drive it without spinning up
/// a SwiftData host. It depends only on ``KitMasteryTopology.graph``
/// (a static value-type DAG) + the per-(kid, kit) state map fetched
/// from ``Services/Adaptive/KitMasteryStore.cachedStates``.
public nonisolated struct KitMasteryRecommender: Sendable {
    /// Underlying engine. Configured with the topology DAG + the
    /// trivial `problemsByTopic` map (one entry per kit; the value
    /// is the kit itself).
    public let engine: NextProblemPicker<KitID, KitID>

    /// Construct with the canonical 9-node topology + 9 single-
    /// problem topics. Callers don't customize this — every consumer
    /// shares the same engine shape per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`
    /// § Phase A's static-build invariant.
    public init(graph: MasteryGraph<KitID> = KitMasteryTopology.graph) {
        let problemsByTopic: [KitID: [KitID]] = Dictionary(
            uniqueKeysWithValues: KitID.allCases.map { ($0, [$0]) }
        )
        self.engine = NextProblemPicker<KitID, KitID>(
            graph: graph,
            problemsByTopic: problemsByTopic
        )
    }

    /// Resolve up to three kid-facing recommendations from the
    /// per-(kid, kit) state map. Returns `[]` when the engine surfaces
    /// nothing (cold launch / new kid / no kit crosses the mastery /
    /// consolidation / stretch bands). The consumer view branches on
    /// `isEmpty` to keep the existing single "Practice with Bramble"
    /// card on cold launch.
    public func recommendations(
        state: [KitID: TopicMasteryState],
        excluding recentKits: Set<KitID> = [],
        recentlyMastered: Set<KitID> = []
    ) -> [KitMasteryRecommendation] {
        engine
            .recommendations(
                state: state,
                excluding: recentKits,
                recentlyMasteredTopics: recentlyMastered
            )
            .compactMap(KitMasteryRecommendation.init(_:))
    }
}

/// Kid-facing projection of one `NextProblemPicker.Recommendation`.
/// Carries the resolved Bramble copy + the kit display name so the
/// view never reaches into the engine's `.extend` / `.consolidate` /
/// `.stretch` rationale strings (engine terms, not kid terms).
public nonisolated struct KitMasteryRecommendation: Sendable, Hashable, Identifiable {
    public let kit: KitID
    public let kind: KitMasteryCopyCatalog.Kind
    /// Pre-resolved Bramble line for `(kind, kit)`. Sourced from
    /// ``KitMasteryCopyCatalog/line(for:kit:)``; never authored at the
    /// consumer-view site so the anti-shame token blocklist stays
    /// enforced at the catalog seam.
    public let brambleCopy: String

    /// Hashable identifier — the kit-of-recommendation is the natural
    /// key (one recommendation per kit per surface).
    public var id: KitID { kit }

    /// Public initializer for callers that need to author a typed
    /// recommendation without going through the engine (previews,
    /// tests, parity with the engine's signature).
    public init(kit: KitID, kind: KitMasteryCopyCatalog.Kind) {
        self.kit = kit
        self.kind = kind
        self.brambleCopy = KitMasteryCopyCatalog.line(for: kind, kit: kit)
    }

    /// Failable adapter from a raw engine `Recommendation`. The engine
    /// never returns a kit that's outside `KitID.allCases` (the
    /// `problemsByTopic` is keyed on `KitID` itself), so the failable
    /// shape is defensive — never expected to return `nil` in
    /// production. Kept failable to absorb a future engine extension
    /// without changing the consumer API.
    public init?(_ raw: NextProblemPicker<KitID, KitID>.Recommendation) {
        let kind: KitMasteryCopyCatalog.Kind
        switch raw.rationale {
        case .extend:      kind = .extend
        case .consolidate: kind = .consolidate
        case .stretch:     kind = .stretch
        }
        self.init(kit: raw.topic, kind: kind)
    }
}
