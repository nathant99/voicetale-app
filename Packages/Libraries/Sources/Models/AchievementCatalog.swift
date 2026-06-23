import Foundation
import ForgeModels

/// Canonical Phase-1 achievement catalog for VoiceTale. Each entry is a
/// pure value-type ``AchievementDefinition`` consumed by
/// ``ForgeGamification.AchievementEngine`` and the
/// ``Services.GamificationService`` evaluation pipeline.
///
/// The criteria each entry rewards are NOT encoded here — the catalog only
/// declares display data + XP rewards + curriculum standard. The runtime
/// criteria check lives in ``Services.GamificationService.evaluateAchievements``
/// so that the catalog stays loadable from anywhere (Models target) without
/// pulling in Services/persistence dependencies.
///
/// Per `@.claude/rules/distributed-narrative.md` § "the cast IS the
/// curriculum", achievement copy is voiced as Bramble's recognition of the
/// kid's craft, not as gamified-points language.
public enum VoiceTaleAchievementCatalog {
    public static let phase1: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_tale",
            title: "First tale told",
            description: "You told your first VoiceTale. Bramble heard every word.",
            iconAssetName: "achievement_first_tale",
            xpValue: 50,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "prolific_storyteller_5",
            title: "Five tales strong",
            description: "Five tales in the anthology. Your voice is finding its shape.",
            iconAssetName: "achievement_prolific_5",
            xpValue: 75,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "prolific_storyteller_10",
            title: "Ten tales kept",
            description: "Ten tales told and saved. Bramble is keeping count.",
            iconAssetName: "achievement_prolific_10",
            xpValue: 125,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "mood_funny",
            title: "Funny on purpose",
            description: "A funny tale, told with timing. Bramble laughed in the right place.",
            iconAssetName: "achievement_mood_funny",
            xpValue: 40,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "mood_scary",
            title: "A little bit scared",
            description: "A scary tale, paced like a held breath.",
            iconAssetName: "achievement_mood_scary",
            xpValue: 40,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "mood_tender",
            title: "Quiet and true",
            description: "A tender tale. The smallest details did the heaviest work.",
            iconAssetName: "achievement_mood_tender",
            xpValue: 40,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "mood_wild",
            title: "Off the rails",
            description: "A wild tale. You let it run and it ran.",
            iconAssetName: "achievement_mood_wild",
            xpValue: 40,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "tradition_explorer",
            title: "Listened to lineage",
            description: "You sat with a tradition. Bramble bowed too.",
            iconAssetName: "achievement_tradition_explorer",
            xpValue: 30,
            standard: nil
        ),
        AchievementDefinition(
            id: "tradition_world_traveler",
            title: "Around the fire",
            description: "All five traditions visited. The world is wider for it.",
            iconAssetName: "achievement_tradition_world",
            xpValue: 100,
            standard: nil
        ),
        AchievementDefinition(
            id: "streak_three_days",
            title: "Three days running",
            description: "Three days in a row. Bramble's perked an ear.",
            iconAssetName: "achievement_streak_three",
            xpValue: 60,
            standard: nil
        ),

        // MARK: - Phase 1.1 — voice-character chooser
        // Authored per `@Docs/FEATURE_PLAN.md` § Phase 1.1 — the chooser
        // ships 4 voice-character-specific achievements. Each one rewards
        // a kind of voice-craft attention: the first try, the breadth,
        // the kit completion, and the per-tale variation.
        AchievementDefinition(
            id: "voice_first_swap",
            title: "First voice change",
            description: "You picked a voice that wasn't your own. Bramble heard the room change.",
            iconAssetName: "achievement_voice_first_swap",
            xpValue: 30,
            standard: nil
        ),
        AchievementDefinition(
            id: "voice_all_five_presets",
            title: "Five voices, one teller",
            description: "Across your tales, you've spoken as every voice character. The room keeps shifting around you.",
            iconAssetName: "achievement_voice_all_five",
            xpValue: 75,
            standard: nil
        ),
        AchievementDefinition(
            id: "voice_kit_05_completed",
            title: "Voice character craft",
            description: "You walked through kit 5. Bramble took notes.",
            iconAssetName: "achievement_voice_kit_05",
            xpValue: 40,
            standard: nil
        ),
        AchievementDefinition(
            id: "voice_variation_tale",
            title: "Two voices, one tale",
            description: "A single tale carried more than one voice. The shift did the work.",
            iconAssetName: "achievement_voice_variation_tale",
            xpValue: 50,
            standard: nil
        ),

        // MARK: - Phase 2 — kits 06-09 + craft-breadth recognition
        // Authored per `@Docs/FEATURE_PLAN.md` § Phase 2 (round 2026-06-23).
        // Each Phase-2 kit gets its own recognition AND there's one
        // catch-all for completing the whole Phase-2 set + one for telling
        // a tale in each of the four moods (mood-breadth across the
        // anthology, not within a single tale). Per `@.claude/rules/
        // distributed-narrative.md`, copy stays in Bramble's grandmother
        // register — recognition of craft, not points language.
        AchievementDefinition(
            id: "mood_explorer_all_four",
            title: "Four corners of the fire",
            description: "Funny, scary, tender, wild — you've told one of each. Bramble's seen the full room.",
            iconAssetName: "achievement_mood_explorer_all_four",
            xpValue: 80,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
        AchievementDefinition(
            id: "kit_06_mood_completed",
            title: "Mood-shape craft",
            description: "You walked through kit 6. Bramble noticed the shape your tales leave behind.",
            iconAssetName: "achievement_kit_06_mood",
            xpValue: 40,
            standard: nil
        ),
        AchievementDefinition(
            id: "kit_07_pacing_completed",
            title: "Pacing-walk craft",
            description: "You walked through kit 7. Where to hold, where to run — the room felt the choice.",
            iconAssetName: "achievement_kit_07_pacing",
            xpValue: 40,
            standard: nil
        ),
        AchievementDefinition(
            id: "kit_08_surprise_completed",
            title: "Surprise-move craft",
            description: "You walked through kit 8. The seed planted in the Hook came back at the Turn.",
            iconAssetName: "achievement_kit_08_surprise",
            xpValue: 40,
            standard: nil
        ),
        AchievementDefinition(
            id: "kit_09_closing_completed",
            title: "Closing-hold craft",
            description: "You walked through kit 9. Your last sentence stayed in the room.",
            iconAssetName: "achievement_kit_09_closing",
            xpValue: 40,
            standard: nil
        ),
        AchievementDefinition(
            id: "phase2_complete_set",
            title: "Four crafts deeper",
            description: "Mood, pacing, surprise, closing — all four kits done. The room hears the difference.",
            iconAssetName: "achievement_phase2_complete_set",
            xpValue: 120,
            standard: StandardAlignment(
                standard: .ccss,
                code: "ELA-Literacy.SL.6.4",
                description: "Present claims and findings, sequencing ideas logically and using pertinent descriptions, facts, and details."
            )
        ),
    ]
}
