import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeAdventure
import ForgeCelebration
import ForgeNavigation

/// Environment slot for the shared ``GamificationService`` instance. Views
/// award XP / record sessions / evaluate achievements via this key per
/// `@.claude/rules/swiftui.md` § `@Entry` macro.
extension EnvironmentValues {
    @Entry public var gamificationService: GamificationService = GamificationService()
    @Entry public var analyticsService: AnalyticsService = AnalyticsService()
    /// Shared ``CelebrationCoordinator`` for level-up / badge-earned / first-tale
    /// celebrations. The overlay is mounted at ``AppRootView`` so it floats
    /// above every tab. Call sites fire celebrations via
    /// `coordinator.levelUp(newLevel:)` / `coordinator.badgeEarned(title:)`.
    @Entry public var celebrationCoordinator: CelebrationCoordinator = CelebrationCoordinator()
    /// Shared ``SessionTimerCoordinator`` (ForgeAccessibility-backed) — daily
    /// + per-session play-time observation per
    /// `@.claude/rules/forgekit.md` § ForgeAccessibility. ProgressTabView reads
    /// the observable surface to render today's listening-time row; AppRootView
    /// drives `startIfNeeded` / `pause` / `resume` on `scenePhase`.
    @Entry public var sessionTimer: SessionTimerCoordinator = SessionTimerCoordinator()
    /// Shared ``ForgeAudioBridge`` — owns the canonical ``ForgeAudioEngine``
    /// instance + maps system accessibility signals onto the engine's mode.
    /// ``AnthologyAudioPlayer`` reaches through this to duck any future
    /// Phase 2 ambient music under user-recording playback.
    @Entry public var forgeAudio: ForgeAudioBridge = ForgeAudioBridge()
    /// Shared ``AnthologyAudioPlayer`` — wraps AVAudioPlayer for tale
    /// playback in AnthologyView. Lives at AppRootView scope so a single
    /// player drives all anthology rows (one tale plays at a time).
    @Entry public var anthologyAudioPlayer: AnthologyAudioPlayer = AnthologyAudioPlayer()
}

/// Top-level app shell. Hosts a 4-tab `TabView` (Tell / Adventure / Progress
/// / Profile) per `@Docs/TECHNICAL_DESIGN.md` § Home Screen & Navigation.
/// Liquid Glass adoption is automatic — no `toolbarBackground` overrides
/// per `@.claude/rules/liquid-glass.md`.
public struct AppRootView: View {
    public enum AppTab: String, Hashable, CaseIterable {
        case tell, adventure, progress, profile

        public var title: String {
            switch self {
            case .tell:      return "Tell"
            case .adventure: return "Adventure"
            case .progress:  return "Progress"
            case .profile:   return "Profile"
            }
        }

        public var systemImage: String {
            switch self {
            case .tell:      return "mic.circle.fill"
            case .adventure: return "map.fill"
            case .progress:  return "chart.bar.fill"
            case .profile:   return "person.circle.fill"
            }
        }
    }

    /// Persistence key for the onboarding-completion gate. Co-located here so
    /// tests + UI-test launch arguments can flip the state without reaching
    /// into a separate constants file. `nonisolated` so it can be read from
    /// the `@Sendable` startup-gate closure (per ``makeRouter``).
    public nonisolated static let onboardingCompletedKey = "voicetale.hasCompletedOnboarding"

    @State private var selectedTab: AppTab = .tell
    @State private var gamification = GamificationService()
    @State private var analytics = AnalyticsService()
    @State private var celebration = CelebrationCoordinator()
    @State private var sessionTimer = SessionTimerCoordinator()
    @State private var forgeAudio = ForgeAudioBridge()
    @State private var anthologyPlayer = AnthologyAudioPlayer()
    @State private var router: ForgePhaseRouter<VoiceTalePhase> = AppRootView.makeRouter()
    @State private var hasBootstrapped = false
    /// Engagement-Foundation welcome-back state. Populated once on
    /// bootstrap when ``LapsedReturnDetector`` confirms a ≥ 3-day gap.
    /// Cleared when the kid taps either CTA. Per `@Docs/FEATURE_PLAN.md`
    /// § Phase: Onboarding & Child Safety § "Return loop".
    @State private var welcomeBackContext: WelcomeBackContext?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppRootView.onboardingCompletedKey) private var hasCompletedOnboarding: Bool = false

    /// Shared registry the source-app's ``VoiceTaleHubContribution`` registers
    /// with on launch. Other portfolio surfaces (e.g., AdventureHub) read from
    /// the same registry once VoiceTale is opted-in cross-app. Stored as an
    /// actor reference so registration can happen off the main actor.
    private let hubRegistry = HubContributionRegistry()

    public init() {}

    /// Factory for the phase router + its onboarding-complete gate. Reads
    /// `UserDefaults` directly so the gate stays self-contained — the
    /// `@AppStorage` binding in the view is the canonical write seam, but
    /// reads from `UserDefaults` agree byte-for-byte.
    private static func makeRouter() -> ForgePhaseRouter<VoiceTalePhase> {
        let onboardingComplete = StartupGate(
            id: "onboarding-complete",
            condition: { @Sendable in
                UserDefaults.standard.bool(forKey: AppRootView.onboardingCompletedKey)
            },
            destination: VoiceTalePhase.onboarding
        )
        return ForgePhaseRouter<VoiceTalePhase>(
            initialPhase: .tabs,
            startupGates: [onboardingComplete]
        )
    }

    public var body: some View {
        Group {
            switch router.currentPhase {
            case .onboarding:
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                    router.navigate(to: .tabs)
                }
            case .tabs:
                tabSurface
            }
        }
        .environment(\.gamificationService, gamification)
        .environment(\.analyticsService, analytics)
        .environment(\.celebrationCoordinator, celebration)
        .environment(\.sessionTimer, sessionTimer)
        .environment(\.forgeAudio, forgeAudio)
        .environment(\.anthologyAudioPlayer, anthologyPlayer)
        .celebrationOverlay(celebration)
        .sheet(item: $welcomeBackContext) { context in
            WelcomeBackView(
                daysLapsed: context.daysLapsed,
                lastTale: context.lastTale,
                onTellAnother: {
                    welcomeBackContext = nil
                    selectedTab = .tell
                },
                onJustLooking: { welcomeBackContext = nil }
            )
        }
        .task {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            analytics.startSession()
            analytics.track(.sessionStarted)
            await sessionTimer.startIfNeeded()
            forgeAudio.refreshAccessibilityMode()
            // Run ForgeNavigation's startup-gate pipeline before settling on
            // the initial phase. If onboarding isn't yet complete the router
            // navigates to `.onboarding`; otherwise `isStartupComplete`
            // flips to true and we stay on `.tabs`. The view body re-reads
            // `router.currentPhase` since the router is @Observable.
            await router.runStartupGates()
            await hubRegistry.register(VoiceTaleHubContribution())
            evaluateWelcomeBack()
            // Phase 2 — index every saved tale into iOS Spotlight so the
            // anthology is discoverable from the OS search surface. Per
            // `@.claude/rules/forgekit.md` § ForgeSpotlight; permissionless
            // CoreSpotlight surface. Title + mood + recorded date only —
            // transcript never leaves persistence. Idempotent — repeated
            // calls overwrite the prior entries.
            await VoiceTaleSpotlightIndexer.indexAllTales(in: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Pause the COPPA session timer when the app backgrounds so the
            // clock doesn't accrue against the daily cap while the kid is
            // away. Resume on foreground. Idempotent in the coordinator.
            switch newPhase {
            case .background, .inactive:
                Task { @MainActor in
                    await sessionTimer.pause()
                    anthologyPlayer.pause()
                }
            case .active:
                Task { @MainActor in
                    await sessionTimer.resume()
                    forgeAudio.refreshAccessibilityMode()
                }
            @unknown default:
                break
            }
        }
    }

    /// Compute the welcome-back context on bootstrap. Reads
    /// `lastActiveDate` BEFORE the gamification service bumps it so the
    /// gap reflects the previous session's date; if the gap is ≥ 3 days,
    /// populates `welcomeBackContext` + emits an analytics event.
    /// Per `@Docs/FEATURE_PLAN.md` § "Return loop".
    private func evaluateWelcomeBack() {
        // Skip the welcome-back surface during onboarding — a kid who's
        // mid-onboarding hasn't yet "lapsed" in any meaningful sense.
        // Still seed retention milestones — they're install-anchored,
        // not session-anchored, so onboarding-day install is the canonical
        // D-0 marker even if the kid never reaches the tab surface.
        guard hasCompletedOnboarding else {
            _ = gamification.recordLastActive(in: modelContext)
            recordRetentionMilestones()
            return
        }
        let snapshot = VoiceTaleStore.progressSnapshot(in: modelContext)
        let priorActive = snapshot.lastActiveDate
        let days = LapsedReturnDetector.daysLapsed(lastActive: priorActive) ?? 0
        // Bump the active date AFTER we read it so the gap reflects the
        // previous session.
        _ = gamification.recordLastActive(in: modelContext)
        recordRetentionMilestones()
        guard days >= LapsedReturnDetector.lapsedDayThreshold else { return }
        // Surface the warm greeting + last-tale recap.
        let lastTale = VoiceTaleStore.fetchTales(in: modelContext).first
        welcomeBackContext = WelcomeBackContext(daysLapsed: days, lastTale: lastTale)
        analytics.track(.lapsedReturn(daysSinceActive: days))
    }

    /// Bridge from `GamificationService.recordRetention` to the analytics
    /// vocabulary. The service handles seeding + persistence; this method
    /// fans out one event per milestone crossed on the launch.
    private func recordRetentionMilestones() {
        let fired = gamification.recordRetention(in: modelContext)
        for milestone in fired {
            analytics.track(.retentionMilestoneHit(milestone: milestone.rawValue))
        }
    }

    private var tabSurface: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.tell.title, systemImage: AppTab.tell.systemImage, value: AppTab.tell) {
                TellView()
            }
            Tab(AppTab.adventure.title, systemImage: AppTab.adventure.systemImage, value: AppTab.adventure) {
                AdventureTabView()
            }
            Tab(AppTab.progress.title, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                AnthologyAndProgressTabView()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfileTabView()
            }
        }
    }
}

/// Identifiable wrapper carrying everything the welcome-back sheet needs.
/// Stored as `Identifiable` so `.sheet(item:)` can drive presentation
/// without a separate bool.
struct WelcomeBackContext: Identifiable, Sendable {
    let id = UUID()
    let daysLapsed: Int
    let lastTale: VoiceTaleEntry?
}

/// Composite Progress tab: anthology gallery + progress card. The original
/// 4-tab spec assigns one tab to "Progress" — for Phase 1 the anthology
/// gallery + XP/streak card share the tab via a segmented switcher so the
/// kid has one place to look at every tale they've told.
private struct AnthologyAndProgressTabView: View {
    enum Pane: String, CaseIterable, Hashable {
        case anthology = "Anthology"
        case progress = "Progress"
    }

    @State private var pane: Pane = .anthology

    var body: some View {
        VStack(spacing: 0) {
            Picker("Pane", selection: $pane) {
                ForEach(Pane.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            Group {
                switch pane {
                case .anthology: AnthologyView()
                case .progress:  ProgressTabView()
                }
            }
        }
    }
}
