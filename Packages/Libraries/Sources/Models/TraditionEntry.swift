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
        contentWarning: String? = nil
    ) {
        self.slug = slug
        self.displayName = displayName
        self.region = region
        self.summary = summary
        self.craftPrimitive = craftPrimitive
        self.culturalCreditNote = culturalCreditNote
        self.audioSampleFilename = audioSampleFilename
        self.contentWarning = contentWarning
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
