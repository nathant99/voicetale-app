import Foundation
import ForgeAccessibility

/// SwiftUI-friendly wrapper over ``ObservableSessionTimer`` with VoiceTale's
/// canonical limits baked in: 15-minute soft session cap + 30-minute daily
/// cap matching the FEATURE_PLAN § "Session targeting: 10-15 minute sessions"
/// + § "Parental controls — Daily session time limits (default 30 min)."
///
/// Per `@.claude/rules/forgekit.md` § ForgeAccessibility — the session timer
/// is the canonical COPPA surface for play-time observation; warnings fire
/// at 5 + 1 minutes remaining per session and 2 minutes before the daily cap.
@Observable @MainActor
public final class SessionTimerCoordinator {
    /// Underlying observable timer — re-exported for views that want to bind
    /// directly to the formatted-remaining string + boolean state.
    public let timer: ObservableSessionTimer

    /// Snapshot of the last-fired warning so consumers (e.g., ProgressTabView)
    /// can surface a "you're 5 minutes from your daily limit" line without
    /// re-emitting the warning every poll cycle. `nil` between thresholds.
    public private(set) var lastWarning: SessionTimerEvent?

    /// Tracks whether ``start`` has been invoked. AppRootView seeds the timer
    /// exactly once during its bootstrap task — re-invoking ``start`` would
    /// zero the elapsed-session counter mid-session.
    public private(set) var hasStarted: Bool = false

    public init(config: SessionTimerConfig = SessionTimerCoordinator.voiceTaleConfig) {
        let service = SessionTimerService(
            config: config,
            userDefaults: .standard,
            keyPrefix: "voicetale"
        )
        self.timer = ObservableSessionTimer(service: service)
    }

    /// Canonical VoiceTale session-timer configuration. 15-minute soft session
    /// cap + 30-minute daily cap; warnings at 5 + 1 minutes remaining within
    /// a session and 2 minutes before the daily cap is reached.
    public static let voiceTaleConfig = SessionTimerConfig(
        maxSessionMinutes: 15,
        warningAtMinutesRemaining: [5, 1],
        dailyTimeLimitMinutes: 30,
        dailyWarningThresholdMinutes: 2
    )

    /// Starts the underlying session timer if it hasn't been started yet.
    /// Safe to call multiple times — re-invocations after the first are
    /// no-ops so a scenePhase race doesn't zero the counter.
    public func startIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true
        await timer.startSession()
    }

    /// Pauses the timer on `scenePhase` background → no accidental clock
    /// accrual while the app is gone. Idempotent.
    public func pause() async {
        guard hasStarted else { return }
        await timer.pause()
    }

    /// Resumes the timer on `scenePhase` foreground. Idempotent.
    public func resume() async {
        guard hasStarted else { return }
        await timer.resume()
    }

    /// Ends the current session and stops polling. Called from
    /// `UIApplication.willTerminateNotification` paths — not normally needed
    /// during the steady-state app lifecycle.
    public func end() async {
        guard hasStarted else { return }
        hasStarted = false
        await timer.endSession()
    }
}
