import Foundation
import SwiftData

/// Phase 2 — kid-curated mood-themed anthology shelf. One row per collection
/// the kid creates ("Bedtime spooks", "Friday-funny", "Tender ones for Gran").
/// Pre-App-Store additive `@Model` per `@.claude/rules/swiftdata.md`
/// § "Pre-App Store: don't create new VersionedSchema for unreleased models".
///
/// ``taleIDsRaw`` stores the tale identifiers as a flat `[UUID]` rather than
/// a SwiftData relationship — relationships are unordered + many-to-many is
/// 30× slower than Core Data per `@.claude/rules/swiftdata.md` § "Relationships".
/// Since collections are kid-sized (typically <50 entries) the scalar-array
/// shape is the simpler + faster choice.
@Model
public final class PersistentMoodCollection {
    /// Stable identity for the collection. Survives renames.
    public var id: UUID = UUID()
    /// Kid-chosen display name. Trimmed + length-bounded at the
    /// persistence layer (see ``VoiceTaleStore.createCollection``).
    public var name: String = ""
    /// Mood-theme for the shelf. Stored as the raw ``VoiceTaleMood``
    /// value; resolved back to the typed enum at the value-type cache
    /// boundary. Optional — a `nil` value means "any mood" so the kid
    /// can curate ensemble shelves across moods if they want.
    public var moodRaw: String?
    /// Ordered list of tale ids in this collection. Order is insertion
    /// order; the latest added tale lands at the END.
    public var taleIDsRaw: [UUID] = []
    /// Wall-clock creation timestamp. Used to surface collections in
    /// freshest-first order in the Anthology shelf.
    public var createdAt: Date = Date()

    /// Phase Delight & Polish — kid-chosen cover-design slug for the
    /// per-collection visual axis. `nil` (default) renders the
    /// auto-derived glyph cover (mood-keyed color + collection name)
    /// via ``AnthologyCoverDesign/autoGlyph``. Non-nil values address
    /// an ``AnthologyCoverDesign`` raw value. Additive Optional
    /// pre-App-Store per `@.claude/rules/swiftdata.md` § "Pre-App Store:
    /// don't create new VersionedSchema for unreleased models" —
    /// synthesized `decodeIfPresent` keeps legacy SwiftData back-compat.
    public var coverArtSlug: String?

    public init(
        id: UUID = UUID(),
        name: String = "",
        moodRaw: String? = nil,
        taleIDsRaw: [UUID] = [],
        createdAt: Date = Date(),
        coverArtSlug: String? = nil
    ) {
        self.id = id
        self.name = name
        self.moodRaw = moodRaw
        self.taleIDsRaw = taleIDsRaw
        self.createdAt = createdAt
        self.coverArtSlug = coverArtSlug
    }
}
