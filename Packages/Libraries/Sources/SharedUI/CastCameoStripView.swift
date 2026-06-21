import SwiftUI
import Models

/// Horizontal strip of cast-member cameos for a single ``QuestionKit``. Renders
/// each `CastCameo` as a small bubble carrying the slug + cameo line. The kit's
/// `anchorCharacterSlug` (when supplied) gets a subtle accent so the kid sees
/// who the kit's primary voice is, while still hearing the other three.
///
/// Phase 1 DN-S Move B surface per
/// `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` (and the kit JSON
/// schema in `@Docs/IMPLEMENTATION_HANDOFF.md` § 6). Cameos are static text
/// for now; Phase 1.1 will upgrade Bramble's listening-coach session to
/// dispatch through `ForgeAI.CastDialog` so the same cameo lines can be
/// extended into live voicing.
public struct CastCameoStripView: View {
    public let cameos: [CastCameo]
    public let anchorSlug: String?
    public let kitTitle: String?

    public init(cameos: [CastCameo], anchorSlug: String? = nil, kitTitle: String? = nil) {
        self.cameos = cameos
        self.anchorSlug = anchorSlug
        self.kitTitle = kitTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(cameos) { cameo in
                        bubble(for: cameo)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.wave.2.fill")
                .foregroundStyle(.secondary)
                .font(.caption.weight(.semibold))
            Text(headerLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var headerLabel: String {
        if let kitTitle, !kitTitle.isEmpty {
            return "Around the fire — \(kitTitle)"
        }
        return "Around the fire"
    }

    @ViewBuilder
    private func bubble(for cameo: CastCameo) -> some View {
        let isAnchor = cameo.slug == anchorSlug
        VStack(alignment: .leading, spacing: 6) {
            Text(displayName(for: cameo.slug))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isAnchor ? Color.accentColor : .secondary)
            Text(cameo.line)
                .font(.callout)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(width: 240, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isAnchor ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName(for: cameo.slug)) — \(cameo.line)")
    }

    /// Display-name resolution for VoiceTale's 4 named cast members. Slugs
    /// match the `dnCast.members[]` entries in `spark-anvil-site` +
    /// `Resources/Cast/cast.json`. Unknown slugs fall through to title-cased
    /// slug so future cast members render without an explicit update here.
    private func displayName(for slug: String) -> String {
        switch slug {
        case "lean":    return "Lean"
        case "slow":    return "Slow"
        case "pivot":   return "Pivot"
        case "refrain": return "Refrain"
        default:        return slug.prefix(1).uppercased() + slug.dropFirst()
        }
    }
}

#Preview {
    CastCameoStripView(
        cameos: [
            CastCameo(slug: "lean", line: "I leaned forward at the second the room got specific. You felt it too."),
            CastCameo(slug: "slow", line: "Hook fast. You had ten seconds and you used eight. Good shape."),
            CastCameo(slug: "pivot", line: "A hook is not yet a turn — but it has to promise that a turn is coming."),
            CastCameo(slug: "refrain", line: "Whatever short, slightly mysterious phrase your hook used — save it.")
        ],
        anchorSlug: "lean",
        kitTitle: "The Hook"
    )
    .padding()
}
