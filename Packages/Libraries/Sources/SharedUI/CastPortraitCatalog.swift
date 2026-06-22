import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Resolves bundled VoiceTale DN cast portrait WebP assets shipped by the hub
/// per `Docs/HANDOFF_FROM_HUB_CAST_PORTRAITS.md`. Four portraits ship — one per
/// cast member: Lean / Pivot / Refrain / Slow (256×256 webp with alpha).
///
/// All four live under `Sources/SharedUI/Resources/Cast/` so they ship inside
/// the SharedUI SPM bundle (the canonical app-source-of-truth); the repo-root
/// `Resources/Cast/` copy is the hub-distribution staging path and is kept in
/// sync with this bundle copy.
///
/// Per R-CAST-PORTRAIT-SLUG (`.claude/rules/spark-anvil-website.md`), the
/// portrait filename slug MUST match the DN-S chapter MD filename slug at
/// `Docs/dn-s/chapters/<char>.md` — this enum's `rawValue` is that slug.
///
/// Cast portraits are NOT avatar accessories — do NOT register them via
/// `AvatarAssetCatalog(appBundles:)`. They surface in the
/// `BrambleReflectionView` cast-voicing chip + DN-S chapter renderer + cast
/// cameo overlays. See `Docs/HANDOFF_FROM_HUB_CAST_PORTRAITS.md` § "How they're
/// used".
public enum CastPortraitCatalog {
    nonisolated public enum Slug: String, CaseIterable, Sendable, Identifiable {
        case lean
        case pivot
        case refrain
        case slow

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .lean:    return "Lean"
            case .pivot:   return "Pivot"
            case .refrain: return "Refrain"
            case .slow:    return "Slow"
            }
        }

        /// Initializes from the cast-member's canonical slug (matches the
        /// `CastVoiceRegistry.Slug` raw value in AIMentor). Returns `nil` for
        /// any string that isn't one of the four shipped slugs — callers use
        /// the nil-return as a "render the SF Symbol fallback" signal.
        public init?(slug: String?) {
            guard let slug, let s = Slug(rawValue: slug) else { return nil }
            self = s
        }
    }

    /// Resolves the WebP URL from the SharedUI SPM bundle. Returns `nil` if
    /// the asset is missing (e.g., the hub sync hasn't run since portrait gen).
    public static func portraitURL(for slug: Slug) -> URL? {
        Bundle.module.url(
            forResource: slug.rawValue,
            withExtension: "webp",
            subdirectory: "Cast"
        ) ?? Bundle.module.url(forResource: slug.rawValue, withExtension: "webp")
    }

    /// Convenience for UI code — returns `(slug, url)` pairs in canonical
    /// cast order (Lean / Pivot / Refrain / Slow). Slugs whose WebP is missing
    /// from the bundle are silently skipped so the surface gracefully degrades.
    public static func availablePortraits() -> [(slug: Slug, url: URL)] {
        Slug.allCases.compactMap { slug in
            guard let url = portraitURL(for: slug) else { return nil }
            return (slug, url)
        }
    }
}

/// Renders a cast portrait WebP from the SharedUI bundle. Falls back to an
/// SF-Symbol avatar shape when the WebP is missing (e.g., asset bundle hasn't
/// been distributed yet OR the slug doesn't resolve). Sized for the
/// "Hear from <name>" chip in `BrambleReflectionView` (~32-48pt round) and
/// scales for sidebar / cameo-strip usages too.
public struct CastPortraitView: View {
    public let slug: CastPortraitCatalog.Slug
    public let dimension: CGFloat

    public init(slug: CastPortraitCatalog.Slug, dimension: CGFloat = 36) {
        self.slug = slug
        self.dimension = dimension
    }

    public var body: some View {
        Group {
            #if canImport(UIKit)
            if let url = CastPortraitCatalog.portraitURL(for: slug),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let url = CastPortraitCatalog.portraitURL(for: slug),
               let image = NSImage(contentsOfFile: url.path) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
        .frame(width: dimension, height: dimension)
        .clipShape(Circle())
        .accessibilityLabel(slug.displayName)
    }

    private var fallback: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.tint)
    }
}
