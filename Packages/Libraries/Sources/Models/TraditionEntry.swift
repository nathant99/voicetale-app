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
