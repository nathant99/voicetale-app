import Foundation
import ForgeAudio
#if canImport(UIKit)
import UIKit
#endif

/// `@Observable @MainActor` bridge that owns the canonical
/// ``ForgeAudioEngine`` instance for VoiceTale + maps system accessibility
/// signals onto the engine's `AccessibilityAudioMode`.
///
/// VoiceTale's Phase 1 surface doesn't yet play background music — the kid's
/// voice IS the audio. The engine is wired here so that:
///   1. ``AnthologyAudioPlayer`` can call ``duckForSpeechIfNeeded`` /
///      ``unduckIfNeeded`` whenever tale playback starts/stops; any future
///      Phase 2 ambient music ducks under the kid's voice automatically.
///   2. VoiceOver / Reduce Audio system settings flow through the engine
///      via ``refreshAccessibilityMode`` (called from `AppRootView` on
///      scenePhase transitions) so Phase 2 ambient music respects the
///      user's accommodations from the moment it lands.
///
/// Per `@.claude/rules/forgekit.md` § ForgeAudio — the engine is the
/// canonical background-music + ambient surface; SFXLibrary is the
/// short-clip path. User-recorded voice playback (AnthologyView) uses a
/// raw ``AVAudioPlayer`` because neither ForgeAudio module targets
/// Documents-directory file playback. This bridge keeps the two paths
/// coordinated.
@Observable @MainActor
public final class ForgeAudioBridge {
    public let engine: ForgeAudioEngine

    /// Tracks whether ``duckForSpeechIfNeeded`` has actually applied a duck
    /// during the current playback session. Used to keep ``unduckIfNeeded``
    /// idempotent across nested calls.
    public private(set) var hasActiveDuck: Bool = false

    public init(volumeProfile: ForgeVolumeProfile = .balanced) {
        self.engine = ForgeAudioEngine(volumeProfile: volumeProfile)
    }

    /// Apply the right `AccessibilityAudioMode` for the current system
    /// settings. Called at app launch + on every scene activation so a
    /// VoiceOver toggle in Settings is picked up next time VoiceTale comes
    /// to the foreground.
    public func refreshAccessibilityMode() {
        let mode: AccessibilityAudioMode
        #if canImport(UIKit)
        if UIAccessibility.isVoiceOverRunning {
            mode = .voiceOver
        } else if UIAccessibility.isReduceMotionEnabled {
            // Reduced-motion is a reasonable proxy for "the kid is in a
            // distraction-sensitive session"; the engine's `.adhd` band
            // softens music + ambient by 50% / 75% respectively.
            mode = .adhd
        } else {
            mode = .standard
        }
        #else
        mode = .standard
        #endif
        engine.applyAccessibilityMode(mode)
    }

    /// Duck any background music under the kid's voice playback. Idempotent.
    /// Called by ``AnthologyAudioPlayer`` when a tale starts playing.
    public func duckForSpeechIfNeeded() {
        guard !hasActiveDuck else { return }
        engine.duckForSpeech()
        hasActiveDuck = true
    }

    /// Restore pre-duck volumes once the kid's playback ends. Idempotent.
    public func unduckIfNeeded() {
        guard hasActiveDuck else { return }
        engine.unduck()
        hasActiveDuck = false
    }
}
