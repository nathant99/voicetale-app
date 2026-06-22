import Foundation
import ForgeNavigation

/// Phase-based navigation enum for VoiceTale. Conforms to
/// ``ForgeNavigation.AppPhase`` so it composes with
/// ``ForgeNavigation.ForgePhaseRouter`` + ``StartupGate`` for the
/// onboarding-complete gate pipeline.
///
/// Phase 1 has two phases: ``onboarding`` (first-launch 5-step flow) and
/// ``tabs`` (the steady-state 4-tab surface). Future phases (parental gate
/// for camera permission / Apple Declared Age Range gate / etc.) will land
/// here as additional cases without changing the router shape.
public enum VoiceTalePhase: String, ForgeNavigation.AppPhase {
    case onboarding
    case tabs

    public var layoutStrategy: PhaseLayoutStrategy {
        switch self {
        case .onboarding: .fullScreen
        case .tabs: .adaptive
        }
    }

    /// VoiceTale ships compact for iPhone; sidebar surfacing is reserved for
    /// the steady-state tab phase only. The onboarding phase intentionally
    /// occupies the whole screen.
    public var showsInSidebar: Bool {
        self == .tabs
    }

    public var displayName: String {
        switch self {
        case .onboarding: return "Welcome"
        case .tabs:       return "VoiceTale"
        }
    }

    public var systemImage: String {
        switch self {
        case .onboarding: return "sparkles"
        case .tabs:       return "mic.circle.fill"
        }
    }
}
