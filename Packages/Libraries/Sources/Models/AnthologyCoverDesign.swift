import Foundation

/// Phase Delight & Polish — pure-function value enum that materializes a
/// per-collection cover design. Five predefined slugs; the canonical
/// auto-derived path (`.autoGlyph`) is what surfaces when the kid has not
/// explicitly picked a cover.
///
/// No AI image gen per ADR-016 — every cover is a kid-readable SwiftUI
/// glyph layout rasterized by `ImageRenderer` at render time (parallels
/// `PublishedTaleCertificate` PR #109's `ShareLink` rendering path).
///
/// New designs are added as enum cases (additive — safe pre-App-Store
/// per `@.claude/rules/swiftdata.md`). Slugs are stable (the raw value is
/// the wire-format), so a future label change for ``displayLabel``
/// doesn't change persistence.
nonisolated public enum AnthologyCoverDesign: String, Sendable, Hashable, Codable, CaseIterable {
    /// Default. Mood-keyed solid color + collection name + first-tale
    /// title snippet. Always usable — every collection has a name.
    case autoGlyph     = "auto_glyph"
    /// Geometric — concentric circles with mood-keyed gradient. Used by
    /// kids who prefer abstract.
    case concentric    = "concentric"
    /// Quilt — 4-square mood checkerboard. Used by ensemble collections
    /// (mood == nil) where no single mood drives the palette.
    case quilt         = "quilt"
    /// Lantern — single lantern glyph over a warm gradient. Used by
    /// tender collections per anti-shame mood register.
    case lantern       = "lantern"
    /// Stage — proscenium-arch frame with collection name centered.
    /// Used by performance-oriented collections.
    case stage         = "stage"

    /// Kid-readable label used in the cover-picker. Keep warm + short.
    public var displayLabel: String {
        switch self {
        case .autoGlyph:  return "Auto"
        case .concentric: return "Concentric"
        case .quilt:      return "Quilt"
        case .lantern:    return "Lantern"
        case .stage:      return "Stage"
        }
    }

    /// Symbol name (SF Symbol) used in picker chip previews. The actual
    /// cover render is the SwiftUI layout in `AnthologyCoverView`; this
    /// is only the picker's preview glyph.
    public var pickerSymbolName: String {
        switch self {
        case .autoGlyph:  return "rectangle.grid.1x2.fill"
        case .concentric: return "circle.circle.fill"
        case .quilt:      return "square.grid.2x2.fill"
        case .lantern:    return "lightbulb.fill"
        case .stage:      return "theatermasks.fill"
        }
    }

    /// Pure-function slug → design resolver. Returns ``autoGlyph`` for
    /// `nil` input and for unknown slugs (conservative-fallback: a
    /// renamed-then-removed slug never crashes the gallery).
    public static func resolve(slug: String?) -> AnthologyCoverDesign {
        guard let slug, let design = AnthologyCoverDesign(rawValue: slug) else {
            return .autoGlyph
        }
        return design
    }

    /// Pure-function title resolver used by the cover-render layer.
    /// Returns the kid-chosen collection name truncated to the cover's
    /// readable cap. Empty input collapses to a fallback so the cover
    /// always reads something — anti-shame surface, never blank.
    public static func coverTitle(forCollectionName name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Tales" }
        // 24-char cap matches the published-tale certificate headline cap
        // (PR #109) so the visual register stays consistent.
        if trimmed.count <= 24 { return trimmed }
        return String(trimmed.prefix(24))
    }

    /// Pure-function subtitle resolver — pulls the first tale title (if
    /// any) and returns a short snippet so the cover hints at what's
    /// inside. Anti-shame fallback for empty / new collections.
    public static func coverSubtitle(firstTaleTitle: String?) -> String {
        guard let raw = firstTaleTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else {
            return "Held by your collection"
        }
        // 28-char cap: short enough to fit alongside the title on a card
        // surface; long enough to surface a tale's title even when the
        // kid picked something descriptive.
        if raw.count <= 28 { return raw }
        return String(raw.prefix(28)) + "…"
    }
}
