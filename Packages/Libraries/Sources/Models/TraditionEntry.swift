import Foundation

/// Catalog-level representation of a tradition entry. Loaded from the bundled
/// `traditions.json` and surfaced via `TraditionView`. Per
/// `@.claude/rules/trauma-informed-content.md` § Cultural-sensitivity gates,
/// every entry carries an explicit ``culturalCreditNote`` and an optional
/// ``contentWarning`` so the kid-readable framing never elides the source
/// community.
nonisolated public struct TraditionEntry: Codable, Sendable, Hashable, Identifiable {
    public var id: String { slug }
    public let slug: String
    public let displayName: String
    public let region: String
    public let summary: String
    public let craftPrimitive: String
    public let culturalCreditNote: String
    public let audioSampleFilename: String?
    public let contentWarning: String?
    /// Easter-eggs Phase A scaffold (per `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md`
    /// § Schema additions). Optional + additive per the pre-App-Store rule
    /// (`@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new
    /// VersionedSchema for unreleased models" — the canonical `traditions.json`
    /// is a Codable JSON blob decoded into the bundled `TraditionCatalog`, so
    /// missing keys decode as `nil` via Swift's synthesized `decodeIfPresent`
    /// path). `nil` (the legacy-JSON case) is interpreted as ``TraditionTier/base``
    /// by callers — see ``effectiveTier``.
    public let tier: TraditionTier?
    /// Predicate identifier for the easter-egg unlock evaluator. Resolved
    /// via ``TraditionUnlockEvaluator`` (Phase B); a `nil` value means the
    /// entry is always visible (the base-tier case). Required when ``tier``
    /// is ``TraditionTier/easterEgg``; future Phase D submission gates on
    /// this. `nil` for every base-tier entry (and for legacy-JSON decodes).
    public let unlockCondition: String?
    /// Reviewer signoff metadata for easter-egg entries. Phase A scaffold
    /// only — the catalog ships ZERO easter-egg entries today (gated on
    /// Phase D external reviewer per ADR-016). For base-tier entries this
    /// is `nil` (and stays `nil`).
    public let reviewerSignoff: ReviewerSignoff?

    /// Mood-register slugs the kid's just-told tale can echo against when the
    /// tradition has been opened in the same sitting. Powers
    /// ``SurpriseMoment/traditionEchoSameSession`` via the tracker on
    /// ``SessionTallyTracker``. Each entry maps to one or more
    /// ``VoiceTaleMood`` slugs whose craft register parallels the
    /// tradition's. Mapping rationale:
    /// - **griot** (memory + responsibility) → `tender` (carrying a
    ///   family's truth back honors the same register as a tender tale)
    /// - **indigenous-american-oral-history** (lineage) → `tender` (the
    ///   weight of a thousand-year-carried story shares the tender register)
    /// - **seanchai** (rhythm + welcome) → `funny`, `wild` (hearth-room
    ///   stories that turn a hard winter into a long laugh sit in both)
    /// - **rakugo** (economy + control) → `scary` (every silence on
    ///   purpose — control over pause is the scary register's signature)
    /// - **slam-poetry** (honesty + presence) → `wild` (raw,
    ///   un-character-hidden voice is closest to the wild register)
    ///
    /// Unknown slugs return an empty set (caller treats as "no echo
    /// signal" — the tradition still renders fine; the surprise archetype
    /// just doesn't fire on it). Per `@.claude/rules/distributed-
    /// narrative.md` § Cultural-sensitivity gates, the mapping never
    /// equates a tradition with a mood — it identifies craft-register
    /// adjacency for a within-session recognition only.
    public var moodRegisterSlugs: Set<String> {
        Self.moodRegisterSlugs(forSlug: slug)
    }

    /// Pure-function variant of ``moodRegisterSlugs`` keyed by tradition
    /// slug. Public + `nonisolated` so unit tests can exercise the table
    /// without constructing a full ``TraditionEntry``.
    nonisolated public static func moodRegisterSlugs(forSlug slug: String) -> Set<String> {
        switch slug {
        case "griot", "indigenous-american-oral-history":
            return ["tender"]
        case "seanchai":
            return ["funny", "wild"]
        case "rakugo":
            return ["scary"]
        case "slam-poetry":
            return ["wild"]
        default:
            return []
        }
    }

    public init(
        slug: String,
        displayName: String,
        region: String,
        summary: String,
        craftPrimitive: String,
        culturalCreditNote: String,
        audioSampleFilename: String? = nil,
        contentWarning: String? = nil,
        tier: TraditionTier? = nil,
        unlockCondition: String? = nil,
        reviewerSignoff: ReviewerSignoff? = nil
    ) {
        self.slug = slug
        self.displayName = displayName
        self.region = region
        self.summary = summary
        self.craftPrimitive = craftPrimitive
        self.culturalCreditNote = culturalCreditNote
        self.audioSampleFilename = audioSampleFilename
        self.contentWarning = contentWarning
        self.tier = tier
        self.unlockCondition = unlockCondition
        self.reviewerSignoff = reviewerSignoff
    }

    /// Tier interpretation for legacy-JSON entries whose `tier` is `nil`.
    /// Legacy entries are treated as ``TraditionTier/base`` (always
    /// visible) by all consumers. Callers that need a non-Optional tier
    /// SHOULD use this helper instead of touching ``tier`` directly.
    public var effectiveTier: TraditionTier {
        tier ?? .base
    }

    /// `true` when the entry sits in the easter-egg tier (gated on Phase
    /// B evaluator + Phase D reviewer signoff).
    public var isEasterEgg: Bool {
        effectiveTier == .easterEgg
    }
}

/// Tier classification for tradition entries. ``base`` entries are always
/// visible in the gallery; ``easterEgg`` entries surface only after the
/// ``TraditionUnlockEvaluator`` predicate (Phase B) fires for the kid's
/// current snapshot. Phase A ships ZERO easter-egg entries — the gate is
/// the catalog content, not the schema. Per
/// `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` § Schema additions.
nonisolated public enum TraditionTier: String, Codable, Sendable, Hashable, CaseIterable {
    case base
    case easterEgg = "easter_egg"
}

/// Reviewer signoff metadata stamped on easter-egg entries before they
/// ship via PR (Phase E). Phase A scaffolds the type; Phase D gates
/// catalog additions on a non-nil instance per ADR-016. For base-tier
/// entries this stays `nil`.
nonisolated public struct ReviewerSignoff: Codable, Sendable, Hashable {
    /// External reviewer's name as it should appear in attribution.
    /// Format conventionally "Dr. <First Last>" or "<First Last>, <Title>".
    public let reviewerName: String
    /// ISO-8601 date the reviewer signed off on the cultural-credit
    /// note + summary text for the entry.
    public let reviewedAt: Date
    /// One-line scope summary — what the reviewer specifically
    /// approved (e.g. "Cultural-credit note for slam-poetry entry —
    /// Black, Latine, Indigenous, queer origin attribution.").
    public let scope: String

    public init(reviewerName: String, reviewedAt: Date, scope: String) {
        self.reviewerName = reviewerName
        self.reviewedAt = reviewedAt
        self.scope = scope
    }
}

/// Top-level shape of `traditions.json`.
nonisolated public struct TraditionCatalog: Codable, Sendable, Hashable {
    public let version: Int
    public let entries: [TraditionEntry]
    public let crisisResources: CrisisResources?

    public init(version: Int, entries: [TraditionEntry], crisisResources: CrisisResources? = nil) {
        self.version = version
        self.entries = entries
        self.crisisResources = crisisResources
    }

    private enum CodingKeys: String, CodingKey {
        case version, entries, crisisResources
    }
}

/// Crisis-resource list surfaced via Settings + (eventually) Bramble's
/// refer-up posture for distress signals. Per ADR-016 + the
/// `trauma-informed-content.md` rule.
nonisolated public struct CrisisResources: Codable, Sendable, Hashable {
    public let note: String?
    public let us: [CrisisResource]

    public init(note: String? = nil, us: [CrisisResource]) {
        self.note = note
        self.us = us
    }
}

nonisolated public struct CrisisResource: Codable, Sendable, Hashable, Identifiable {
    public var id: String { name }
    public let name: String
    public let phone: String?
    public let text: String?
    public let url: String?

    public init(name: String, phone: String?, text: String?, url: String?) {
        self.name = name
        self.phone = phone
        self.text = text
        self.url = url
    }
}
