import SwiftUI
import Models

/// Phase Delight & Polish — per-collection visual axis. Renders an
/// ``AnthologyCoverDesign`` as a kid-readable SwiftUI glyph layout. No
/// AI image gen per ADR-016; the cover is pure-SwiftUI + can be
/// rasterized to a `UIImage` via `ImageRenderer` for share / save-to-
/// Photos flows (parallels `PublishedTaleCertificateSheet` PR #109).
struct AnthologyCoverView: View {
    let design: AnthologyCoverDesign
    let collectionName: String
    let mood: VoiceTaleMood?
    let firstTaleTitle: String?
    /// Cover size — defaults to 88pt square (chip-sized). The published-
    /// share path renders at 512pt via ImageRenderer; tests render
    /// at any size to verify the layout doesn't trap on minimum sizes.
    var size: CGFloat = 88

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            backgroundLayer
            foregroundLayer
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    // MARK: - Layers

    @ViewBuilder
    private var backgroundLayer: some View {
        switch design {
        case .autoGlyph:
            LinearGradient(
                colors: [primaryTint, primaryTint.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .concentric:
            // Solid base + concentric rings = abstract motion-free design.
            ZStack {
                primaryTint
                ForEach(0..<3, id: \.self) { idx in
                    Circle()
                        .stroke(Color.white.opacity(0.55 - Double(idx) * 0.12), lineWidth: 2)
                        .frame(width: size * (0.85 - CGFloat(idx) * 0.22))
                }
            }
        case .quilt:
            // 4-square mood checkerboard: each quadrant tinted slightly
            // differently so the cover reads as ensemble even when the
            // collection.mood is nil.
            quiltLayer
        case .lantern:
            // Warm gradient suitable for tender register; never saturated.
            LinearGradient(
                colors: [primaryTint, primaryTint.opacity(0.45), .black.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .stage:
            // Two horizontal bands evoking a proscenium arch (deeper top,
            // lighter bottom). Anti-shame: no specific cultural register.
            VStack(spacing: 0) {
                primaryTint
                primaryTint.opacity(0.55)
            }
        }
    }

    @ViewBuilder
    private var foregroundLayer: some View {
        VStack(spacing: 4) {
            switch design {
            case .autoGlyph, .concentric, .quilt, .stage:
                Text(AnthologyCoverDesign.coverTitle(forCollectionName: collectionName))
                    .font(.system(size: size * 0.15, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                Text(AnthologyCoverDesign.coverSubtitle(firstTaleTitle: firstTaleTitle))
                    .font(.system(size: size * 0.10, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            case .lantern:
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: size * 0.30))
                    .foregroundStyle(.white)
                Text(AnthologyCoverDesign.coverTitle(forCollectionName: collectionName))
                    .font(.system(size: size * 0.13, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            }
        }
    }

    @ViewBuilder
    private var quiltLayer: some View {
        let cellSize = size * 0.5
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle().fill(primaryTint).frame(width: cellSize, height: cellSize)
                Rectangle().fill(primaryTint.opacity(0.7)).frame(width: cellSize, height: cellSize)
            }
            HStack(spacing: 0) {
                Rectangle().fill(primaryTint.opacity(0.7)).frame(width: cellSize, height: cellSize)
                Rectangle().fill(primaryTint).frame(width: cellSize, height: cellSize)
            }
        }
    }

    // MARK: - Helpers

    /// Mood-keyed cover tint. Anti-shame: lacks high-saturation reds for
    /// scary / wild — leans toward warm-but-readable hues per the
    /// MoodRetrospective register-cohesion rule (PR #88).
    private var primaryTint: Color {
        switch mood {
        case .funny:  return Color(red: 1.00, green: 0.78, blue: 0.30)     // warm gold
        case .scary:  return Color(red: 0.32, green: 0.30, blue: 0.55)     // dusk indigo
        case .tender: return Color(red: 0.92, green: 0.61, blue: 0.68)     // soft rose
        case .wild:   return Color(red: 0.36, green: 0.66, blue: 0.49)     // forest green
        case .none:   return Color(red: 0.52, green: 0.49, blue: 0.66)     // ensemble dusk
        }
    }

    private var accessibilityLabel: String {
        let moodLabel = mood?.displayLabel ?? "Any mood"
        return "Cover for \(collectionName), \(moodLabel)"
    }
}

#Preview {
    HStack(spacing: 12) {
        AnthologyCoverView(
            design: .autoGlyph,
            collectionName: "Bedtime spooks",
            mood: .scary,
            firstTaleTitle: "The whisper under the bed"
        )
        AnthologyCoverView(
            design: .lantern,
            collectionName: "Tender ones for Gran",
            mood: .tender,
            firstTaleTitle: "Walking on the trail"
        )
        AnthologyCoverView(
            design: .quilt,
            collectionName: "Mixed",
            mood: nil,
            firstTaleTitle: nil
        )
    }
    .padding()
}
