import SwiftUI
import SpriteKit
import ForgeModels
import ForgeAdventure

/// Level-2 AdventureHub overlay for VoiceTale's Word Workshop zone contribution.
/// Per `@Docs/TECHNICAL_DESIGN.md` § Adventure Mode + `Docs/AMENDMENTS_ADVENTUREHUB_SOURCE_OWNED_UI.md`,
/// the Level-1 baseline JSON lives upstream at `labsmith/Resources/HubContributions/voicetale.json`;
/// this conformer ships the source-app-owned challenge view that shadows the baseline.
///
/// Engines supported in Phase 1: `.quest` (Tell a Hook). Future engines
/// (`.builder` for hook-builder drills, `.collection` for anthology growth)
/// land in Phase 1.1 + Phase 2 per the Adventure Mode roadmap.
public struct VoiceTaleHubContribution: HubContribution {
    public init() {}

    public nonisolated var sourceAppID: String { "voicetale" }
    public nonisolated var sourceAppDisplayName: String { "VoiceTale" }
    public nonisolated var zone: ZoneID { .wordWoods }
    public nonisolated var supportedEngines: [GameModeType] { [.quest] }
    public nonisolated var preferredPresentation: HubPresentation { .fullScreen }

    public nonisolated var themeAccent: Color { Color(red: 0.11, green: 0.48, blue: 0.55) } // Ocean teal #1B7B8C

    public nonisolated var mentorPersona: MentorPersona {
        MentorPersona(
            id: "bramble",
            displayName: "Bramble",
            avatarAssetName: "bramble_demonstrating",
            voiceProfile: .warmMid,
            systemPromptHeader: """
            You are Bramble — a warm grandmother-register thornbush sprite who is a perfect listener.
            You never grade. You never comment on accent, fluency, or articulation.
            You reflect back what you heard the teller do — never lecture, always one open question.
            """
        )
    }

    public nonisolated var kitResources: [HubKitResource] {
        [
            HubKitResource(
                kitID: "kit_01_hook",
                resourceName: "kit_01_hook",
                bloomBand: .apply,
                gradeBand: .middle
            ),
            HubKitResource(
                kitID: "kit_02_sensory_detail",
                resourceName: "kit_02_sensory_detail",
                bloomBand: .apply,
                gradeBand: .middle
            ),
            HubKitResource(
                kitID: "kit_03_arc_completeness",
                resourceName: "kit_03_arc_completeness",
                bloomBand: .analyze,
                gradeBand: .middle
            ),
            HubKitResource(
                kitID: "kit_04_mood",
                resourceName: "kit_04_mood",
                bloomBand: .analyze,
                gradeBand: .middle
            ),
        ]
    }

    @MainActor
    public func makeChallengeView(
        engine: GameModeType,
        kit: HubQuestionKit,
        context: HubChallengeContext
    ) -> AnyView {
        switch engine {
        case .quest:
            return AnyView(VoiceTaleHubChallengeView(kit: kit, context: context, accent: themeAccent))
        default:
            return AnyView(
                ContentUnavailableView(
                    "Coming to the Word Workshop",
                    systemImage: "leaf",
                    description: Text("VoiceTale supports the Tell-a-Hook quest engine in Phase 1. More engines on the way.")
                )
            )
        }
    }

    /// VoiceTale stays SwiftUI-only — no SpriteKit canvas required for the
    /// hub challenge. Default protocol implementation returns nil; we restate
    /// it here so the compiler's existential erasure is unambiguous.
    @MainActor
    public func makeSpriteKitScene(
        engine: GameModeType,
        kit: HubQuestionKit,
        context: HubChallengeContext
    ) -> SKScene? {
        nil
    }
}

/// Source-app-owned challenge view for the Word Workshop quest engine. A
/// quiet pre-record screen that names the kit's craft primitive + the
/// anchor cast member, then hands off to ``TellView`` for the actual record.
struct VoiceTaleHubChallengeView: View {
    let kit: HubQuestionKit
    let context: HubChallengeContext
    let accent: Color

    @State private var showingTellSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Spacer(minLength: 24)
            primaryAction
        }
        .padding()
        .sheet(isPresented: $showingTellSheet) {
            TellView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Word Workshop")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            Text(kit.title)
                .font(.title.weight(.semibold))
            Text("Tell a 60-to-120-second tale. Bramble will listen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var primaryAction: some View {
        Button {
            showingTellSheet = true
        } label: {
            Label("Start telling", systemImage: "mic.circle.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
        .controlSize(.large)
        .accessibilityHint("Open the Tell tab to record this kit's tale.")
    }
}
