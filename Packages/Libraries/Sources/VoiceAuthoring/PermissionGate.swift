import Foundation
import AVFoundation
import Speech

/// Defensive gate around microphone-permission paths. Per
/// `@.claude/rules/warnings.md` § "Privacy-Gated Frameworks", iOS hard-crashes
/// the process the moment any audio-recording API is invoked without an
/// `NSMicrophoneUsageDescription` key in `Info.plist`. The cached static
/// check makes every entry point a no-op when the key is missing, so the
/// agent + app shell can ship before the user adds the description via
/// Xcode UI (per `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` Step 4).
nonisolated public enum PermissionGate {
    /// True if `NSMicrophoneUsageDescription` is present in the main bundle's
    /// `Info.plist`. Cached at first access; never changes for a given binary.
    public static let hasMicrophoneUsageDescription: Bool = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String,
            !value.isEmpty
        else { return false }
        return true
    }()

    /// Asks the OS for microphone permission via `AVAudioApplication`.
    /// Returns false (without prompting) when the usage description is
    /// missing, so the caller can gracefully degrade.
    public static func requestMicrophonePermission() async -> Bool {
        guard hasMicrophoneUsageDescription else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    /// Current authorization state without prompting. Returns `.undetermined`
    /// when the usage description is missing so the caller can route to the
    /// degraded-mode flow without ever touching the AVFAudio APIs.
    public static var currentMicrophoneAuthorization: AVAudioApplication.recordPermission {
        guard hasMicrophoneUsageDescription else { return .undetermined }
        return AVAudioApplication.shared.recordPermission
    }

    // MARK: - Speech recognition

    /// True if `NSSpeechRecognitionUsageDescription` is present in `Info.plist`.
    public static let hasSpeechRecognitionUsageDescription: Bool = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String,
            !value.isEmpty
        else { return false }
        return true
    }()

    /// Asks the OS for speech-recognition permission via `SFSpeechRecognizer`.
    /// Returns false (without prompting) when the usage description is missing.
    public static func requestSpeechRecognitionPermission() async -> Bool {
        guard hasSpeechRecognitionUsageDescription else { return false }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Current speech-recognition authorization state without prompting.
    /// Returns `.notDetermined` when the usage description is missing so the
    /// caller can degrade gracefully without ever touching the Speech APIs.
    public static var currentSpeechAuthorization: SFSpeechRecognizerAuthorizationStatus {
        guard hasSpeechRecognitionUsageDescription else { return .notDetermined }
        return SFSpeechRecognizer.authorizationStatus()
    }
}
