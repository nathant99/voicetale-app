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
    ]
}
