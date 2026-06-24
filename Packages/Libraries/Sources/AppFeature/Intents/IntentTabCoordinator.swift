import Foundation
import Observation

/// Single-process coordinator for tab requests originating from an
/// `AppIntent` perform. The intent posts to ``IntentTabCoordinator/shared``
/// from the App Intent runtime context (which Apple guarantees launches
/// the app + hops to MainActor before invoking `perform`); ``AppRootView``
/// observes ``requestedTab`` via `.onChange` + applies + clears.
///
/// Pattern parallels other portfolio apps (CuriosityQuest's
/// `IntentRouteCoordinator`). Lives in the SPM `AppFeature` target so the
/// app-shell intent structs (under `Apps/VoiceTale/VoiceTale/Intents/`) can
/// `import AppFeature` + post; the SwiftUI `AppRootView` (also in
/// AppFeature) observes the same singleton.
///
/// Why a process-singleton: an `AppIntent` does not have access to the
/// SwiftUI environment + does not run inside an existing view body. Storing
/// the requested tab on a shared `@Observable` class is the canonical way
/// to bridge the intent's perform() into the view layer.
@MainActor
@Observable
public final class IntentTabCoordinator {
    /// Process-wide singleton. The app-shell intents post to this;
    /// `AppRootView` observes it. Initialized lazily on first read.
    public static let shared = IntentTabCoordinator()

    /// Last-requested tab. Non-nil from the moment an intent posts until
    /// ``AppRootView`` clears it on apply. Always written on `@MainActor`
    /// (the App Intent runtime hops to MainActor before invoking
    /// `perform` when the intent declares `openAppWhenRun = true`).
    public var requestedTab: AppRootView.AppTab?

    /// Latched "raw destination" for downstream analytics + diagnostics.
    /// Captures the typed destination the intent posted, not just the
    /// derived tab — useful when the future router gains finer mapping
    /// (e.g., `.anthology` → its own tab when one ships) so analytics
    /// don't lose the original intent shape.
    public private(set) var lastRequestedDestination: VoiceTaleIntentDestination?

    /// `private` initializer enforces the singleton contract — call
    /// ``IntentTabCoordinator/shared`` instead. Allows zero-state
    /// construction for tests via `@testable import` if needed.
    private init() {}

    /// Post a destination from an `AppIntent.perform`. Translates via the
    /// pure-function ``VoiceTaleIntentRouter/tab(for:)`` so the routing
    /// surface stays in one place.
    public func request(destination: VoiceTaleIntentDestination) {
        let tab = VoiceTaleIntentRouter.tab(for: destination)
        lastRequestedDestination = destination
        requestedTab = tab
    }

    /// Clear the pending request after ``AppRootView`` has applied it.
    /// Idempotent — repeat calls are safe.
    public func clearRequest() {
        requestedTab = nil
    }
}
