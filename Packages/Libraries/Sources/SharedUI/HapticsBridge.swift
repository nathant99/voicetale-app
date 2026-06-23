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

    /// Subtle tap fired on each 5-beat boundary transition during recording.
    /// Part of the proportional-celebration trifecta (visual nudge in
    /// ``BeatTimerView`` + this haptic) per `@Docs/FEATURE_PLAN.md`
    /// § Delight & Polish → "Celebration system: subtle sparkle for beat
    /// hit". Lighter than ``fireRecordStart`` — the kid feels it without it
    /// pulling attention away from telling.
    public static func fireBeatBoundary() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.buttonTap)
    }

    /// Selection tap fired when the kid picks a mood chip, a voice-character
    /// preset chip, or any other chip-style selector. Part of the
    /// Delight & Polish "Juice layer" pass — visual + haptic land together
    /// on every interaction (the visual side is the chip's existing
    /// `isSelected` style change). Reuses ``ForgeHapticLibrary/buttonTap``
    /// — lightest tap in the library, designed so chip-strip scrubbing
    /// doesn't feel buzzy. Callers fire only on a real change of value
    /// (no-op self-taps don't get a haptic).
    public static func fireSelection() {
        ForgeHapticEngine.shared.playSync(ForgeHapticLibrary.buttonTap)
    }
}
