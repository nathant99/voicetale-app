import Foundation
import ForgeAccessibility

/// Static facade over ``ForgeHapticEngine`` so the rest of the app fires
/// haptics through a named seam rather than constructing patterns inline.
/// Per `@.claude/rules/workflow.md` § Service Architecture — *"HapticService
/// static methods for feedback — call from ViewModel, not views."*
///
/// ``ForgeHapticEngine`` silently no-ops on devices without a Taptic Engine
/// (iPad, Simulator). Callers don't gate at the call site — this facade is
/// safe to fire unconditionally on every supported platform.
public enum HapticsBridge {
    /// Light tap when the kid starts a recording — confirms the mic engaged
    /// without ducking the audio session.
    public static func fireRecordStart() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.buttonTap)
    }

    /// Achievement-grade double tap when a tale lands in the anthology. This
    /// is the canonical "you did the thing" feedback per the Phase 1 delight
    /// pass — louder than `buttonTap`, lighter than `levelUp`.
    public static func fireTaleSaved() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.achievement)
    }

    /// Transient + sustained ramp + final accent for level-up celebrations.
    /// Fires alongside ``ForgeCelebration`` level-up surfaces so the visual
    /// + haptic land together.
    public static func fireLevelUp() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.levelUp)
    }

    /// Escalating cascade for streak milestones (saved-tale-streak hits 3 /
    /// 7 / 30 / etc. days). Reserved for the next gamification pass.
    public static func fireStreakMilestone() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.streakMilestone)
    }

    /// Sustained buzz used by the session timer when the kid approaches the
    /// configured daily cap. Fires once per crossing — the timer event
    /// surface handles dedupe.
    public static func fireSessionWarning() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.warning)
    }
}
