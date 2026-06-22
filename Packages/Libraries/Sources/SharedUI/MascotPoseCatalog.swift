import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Resolves bundled Bramble mascot pose WebP assets shipped by the hub. Five
/// poses are bundled, each surfacing a distinct emotional / functional moment
/// in the record → review → reflect flow:
///
/// | Pose | When to use |
/// |---|---|
/// | `thinking` | Awaiting-reflection state (Bramble is "listening back") |
/// | `working` | Active mid-task state (transcript pipeline running) |
/// | `demonstrating` | First-time onboarding / how-to surfaces |
/// | `encouraging` | Retell / brief-beat moments (gentle nudge, not a lecture) |
/// | `praising` | Save-to-anthology success + 5-beat-hit celebrations |
///
/// All five live under `Sources/SharedUI/Resources/Illustrations/mascots/` so
/// they ship inside the SharedUI SPM bundle (the canonical app-source-of-truth);
/// the repo-root `Resources/Illustrations/mascots/` copy is the
/// hub-distribution staging path and is kept in sync with this bundle copy.
///
/// Filename convention: `bramble_<pose>.webp` per `.claude/rules/forgekit.md`
/// § "Cast asset filename convention" — `<mascot_name>_<pose>.webp` for
/// mascots (distinct from the `cast_<character_slug>_<pose>.webp` prefix used
/// for DN cast members).
public enum MascotPoseCatalog {
    nonisolated public enum Pose: String, CaseIterable, Sendable, Identifiable {
        case thinking
        case working
        case demonstrating
        case encouraging
        case praising

        public var id: String { rawValue }

        /// File basename in the bundle (without extension). Per the portfolio
        /// mascot-naming convention: `<mascot>_<pose>`.
        public var fileName: String { "bramble_\(rawValue)" }

        /// Short caption useful for accessibility labels. Kid-readable register
        /// — not a clinical descriptor.
        public var accessibilityDescription: String {
            switch self {
            case .thinking:      return "Bramble is thinking quietly."
            case .working:       return "Bramble is working on something."
            case .demonstrating: return "Bramble is showing you how."
            case .encouraging:   return "Bramble is cheering you on."
            case .praising:      return "Bramble is celebrating your tale."
            }
        }
    }

    /// Resolves the WebP URL from the SharedUI SPM bundle. Returns `nil` if
    /// the asset is missing (e.g., the hub sync hasn't run since pose gen).
    public static func poseURL(for pose: Pose) -> URL? {
        Bundle.module.url(
            forResource: pose.fileName,
            withExtension: "webp",
            subdirectory: "Illustrations/mascots"
        ) ?? Bundle.module.url(forResource: pose.fileName, withExtension: "webp")
    }

    /// Convenience for diagnostics + tests — returns `(pose, url)` pairs in
    /// canonical order. Poses whose WebP is missing from the bundle are
    /// silently skipped so the surface gracefully degrades.
    public static func availablePoses() -> [(pose: Pose, url: URL)] {
        Pose.allCases.compactMap { pose in
            guard let url = poseURL(for: pose) else { return nil }
            return (pose, url)
        }
    }
}

/// Renders a Bramble mascot pose WebP from the SharedUI bundle. Falls back to
/// an SF-Symbol leaf icon when the WebP is missing (e.g., asset bundle hasn't
/// been distributed yet OR the pose enum doesn't resolve). Sized for the
/// `BrambleReflectionView` mascot header (~44pt) and scales for other usages.
public struct MascotPoseView: View {
    public let pose: MascotPoseCatalog.Pose
    public let dimension: CGFloat

    public init(pose: MascotPoseCatalog.Pose, dimension: CGFloat = 44) {
        self.pose = pose
        self.dimension = dimension
    }

    public var body: some View {
        Group {
            #if canImport(UIKit)
            if let url = MascotPoseCatalog.poseURL(for: pose),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let url = MascotPoseCatalog.poseURL(for: pose),
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
        .accessibilityLabel(pose.accessibilityDescription)
    }

    private var fallback: some View {
        Image(systemName: "leaf.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.tint)
    }
}
