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
    /// Shared ``SessionTallyTracker`` — counts tales saved + badges earned
    /// per sitting so ``SessionCloserView`` can render an honest recap when
    /// the session soft-cap fires. Reset implicitly on cold launch via
    /// AppRootView's `@State` storage; reset explicitly on closer dismiss.
    @Entry public var sessionTally: SessionTallyTracker = SessionTallyTracker()
    /// ForgeReflection Phase B — shared ``VoiceTaleReflectionStore``
    /// instance backing the `.reflectionPrompt` modifier surfaced inside
    /// ``BrambleReflectionView``. `nil` until ``AppRootView.task`` boots
    /// it against the shared `ModelContainer`; consumers branch on the
    /// `nil` state to hide the affordance (preserves the listening-back
    /// register on previews + unbootstrapped tests). Per
    /// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase B.
    @Entry public var voiceTaleReflectionStore: VoiceTaleReflectionStore? = nil
    /// ForgeMasteryEngine Phase B — shared ``KitMasteryStore`` instance
    /// reading + writing per-(kid, kit) `TopicMasteryState` snapshots on
    /// `PersistentPlayerProgress.encodedMasteryState`. Bootstrapped in
    /// ``AppRootView.task``; consumers (e.g., `QuizView.handleChoice`)
    /// branch on the `nil` env state to skip recording when the store
    /// hasn't been wired yet. Per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B.
    @Entry public var kitMasteryStore: KitMasteryStore? = nil
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

    /// ForgeReflection Phase C — persistence keys for the weekly retention
    /// purge cadence. `lastPurgeAtKey` carries the
    /// `timeIntervalSinceReferenceDate` of the last successful purge run;
    /// `retentionDaysKey` carries the grown-up-overridable horizon (90 /
    /// 180 / 365 days; default 180 per
    /// ``ReflectionRetentionPolicy.defaultRetentionDays``). Both keyed
    /// off `@AppStorage` so tests + `SettingsView` agree on the canonical
    /// shape. Per `@.claude/rules/age-assurance.md` § "2026 FTC COPPA
    /// Rule Amendments" (defined retention period requirement).
    public nonisolated static let reflectionPurgeLastRunKey = "voicetale.reflection.purge.last_run"
    public nonisolated static let reflectionRetentionDaysKey = "voicetale.reflection.retention_days"

    @State private var selectedTab: AppTab = .tell
    @State private var gamification = GamificationService()
    @State private var analytics = AnalyticsService()
    @State private var celebration = CelebrationCoordinator()
    @State private var sessionTimer = SessionTimerCoordinator()
    @State private var forgeAudio = ForgeAudioBridge()
    @State private var anthologyPlayer = AnthologyAudioPlayer()
    @State private var sessionTally = SessionTallyTracker()
    /// ForgeReflection Phase B — process-wide store for the "Answer
    /// Bramble" surface. Bootstrapped once in `.task` against the shared
    /// `ModelContainer`; injected into the environment so
    /// ``BrambleReflectionView`` (and any future consumer) reads via
    /// `@Environment(\.voiceTaleReflectionStore)`. The store is
    /// `@MainActor @Observable` and the cached `entries` snapshot drives
    /// SwiftUI updates without re-querying the underlying actor.
    @State private var reflectionStore = VoiceTaleReflectionStore()
    @State private var hasBootstrappedReflectionStore = false
    /// ForgeMasteryEngine Phase B — process-wide store backing
    /// ``QuizView.handleChoice``'s `MasteryUpdater.recordAttempt` call.
    /// Bootstrapped once in `.task` against the canonical
    /// ``PersistentPlayerProgress`` row (fetched / created via
    /// ``VoiceTaleStore.fetchOrCreateProgress``) so the JSON snapshot
    /// on `encodedMasteryState` round-trips across launches.
    @State private var kitMasteryStore = KitMasteryStore()
    @State private var hasBootstrappedKitMasteryStore = false
    @State private var router: ForgePhaseRouter<VoiceTalePhase> = AppRootView.makeRouter()
    @State private var hasBootstrapped = false
    /// Engagement-Foundation welcome-back state. Populated once on
    /// bootstrap when ``LapsedReturnDetector`` confirms a ≥ 3-day gap.
    /// Cleared when the kid taps either CTA. Per `@Docs/FEATURE_PLAN.md`
    /// § Phase: Onboarding & Child Safety § "Return loop".
    @State private var welcomeBackContext: WelcomeBackContext?
    /// Engagement-Foundation session-closer state. Populated when the
    /// 15-minute soft-cap fires on the underlying ``ObservableSessionTimer``
    /// (via the `.isSessionExpired` published property). Cleared on dismiss.
    /// Per `@Docs/FEATURE_PLAN.md` § "Session targeting".
    @State private var sessionCloserRecap: SessionCloserRecapWrapper?
    /// Latched flag — once the soft-cap fires for this sitting, surface the
    /// closer exactly once. Cleared on cold launch (fresh `@State`) so the
    /// next sitting starts the cycle over.
    @State private var hasShownSessionCloserThisSitting = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppRootView.onboardingCompletedKey) private var hasCompletedOnboarding: Bool = false
    /// ForgeReflection Phase C — last-run timestamp for the weekly retention
    /// purge cadence. Stored as `Double` (timeIntervalSinceReferenceDate);
    /// `0` means "never run", which ``ReflectionRetentionPolicy.shouldPurge``
    /// treats as "always fire" so the first eligible launch triggers a
    /// purge. The default `Double = 0` shape is `@AppStorage`-compatible
    /// without resorting to a custom Optional encoding.
    @AppStorage(AppRootView.reflectionPurgeLastRunKey) private var reflectionPurgeLastRunSinceReference: Double = 0
    /// ForgeReflection Phase C — grown-up-overridable retention horizon.
    /// Default 180 days per ``ReflectionRetentionPolicy.defaultRetentionDays``;
    /// ``SettingsView`` exposes the three-point picker (90 / 180 / 365).
    /// Clamped via ``ReflectionRetentionPolicy.clampedRetentionDays(_:)`` at
    /// every read so a corrupt write (future migration drift) degrades to
    /// the safe default rather than skipping the COPPA-mandated purge.
    @AppStorage(AppRootView.reflectionRetentionDaysKey) private var reflectionRetentionDays: Int = ReflectionRetentionPolicy.defaultRetentionDays

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
        .environment(\.sessionTally, sessionTally)
        .environment(\.voiceTaleReflectionStore, reflectionStore)
        .environment(\.kitMasteryStore, kitMasteryStore)
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
        .sheet(item: $sessionCloserRecap) { recap in
            SessionCloserView(recap: recap.payload) {
                sessionCloserRecap = nil
                sessionTally.reset()
            }
            .interactiveDismissDisabled(false)
        }
        .onChange(of: IntentTabCoordinator.shared.requestedTab) { _, requested in
            // AppIntent runtime → singleton coordinator → here. The intent
            // posts via `IntentTabCoordinator.shared.request(destination:)`
            // from `Apps/VoiceTale/VoiceTale/Intents/*.swift`; we apply +
            // clear so the next request triggers another apply. Per
            // `@.claude/rules/forgekit.md` § ForgeIntents (registry-routed
            // App Intents) the perform method opens the app + hops to
            // MainActor before posting.
            guard let requested else { return }
            // Honor the intent only after the kid has cleared onboarding —
            // dropping an unboarded kid straight into the Tell tab would
            // skip the COPPA / mic-permission gates. The coordinator hangs
            // on to the destination via `lastRequestedDestination` so the
            // onboarding-completion handler could replay it; for now we
            // simply drop the request when onboarding is incomplete.
            guard hasCompletedOnboarding else {
                IntentTabCoordinator.shared.clearRequest()
                return
            }
            selectedTab = requested
            IntentTabCoordinator.shared.clearRequest()
            // Categorical analytics — the destination travels (not the
            // tab) so future fine-grained routing keeps the analytics
            // surface stable.
            if let destination = IntentTabCoordinator.shared.lastRequestedDestination {
                analytics.track(.intentDestinationRequested(destination: destination.rawValue))
            }
        }
        .onChange(of: sessionTimer.timer.isSessionExpired) { _, expired in
            guard expired, hasShownSessionCloserThisSitting == false else { return }
            hasShownSessionCloserThisSitting = true
            let snapshot = VoiceTaleStore.progressSnapshot(in: modelContext)
            let payload = SessionCloserView.Recap(
                talesSavedThisSession: sessionTally.talesSavedThisSession,
                badgesEarnedThisSession: sessionTally.badgesEarnedThisSession,
                currentStreakDays: snapshot.currentStreakDays,
                nextSessionInvite: AppRootView.nextSessionInvite(streakDays: snapshot.currentStreakDays)
            )
            sessionCloserRecap = SessionCloserRecapWrapper(payload: payload)
            analytics.track(.sessionCloserShown(talesSavedThisSession: sessionTally.talesSavedThisSession))
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
            // ForgeReflection Phase B — boot the shared
            // ``VoiceTaleReflectionStore`` once against the shared
            // `ModelContainer`. Idempotent guard via
            // `hasBootstrappedReflectionStore` mirrors the existing
            // `hasBootstrapped` pattern; second `.task` invocations
            // (scene-phase rehydration) re-fetch the entry list via
            // `refresh()` without recreating the storage actor.
            if !hasBootstrappedReflectionStore {
                hasBootstrappedReflectionStore = true
                await reflectionStore.bootstrap(container: modelContext.container)
            }
            // ForgeReflection Phase C — weekly retention purge cadence.
            // Reads the `@AppStorage`-backed last-run timestamp + grown-up
            // retention horizon, asks the pure-function policy whether
            // to fire, and persists the next last-run timestamp on
            // success. The purge is no-op when nothing crosses the
            // cutoff. Per `@.claude/rules/age-assurance.md` § "2026 FTC
            // COPPA Rule Amendments" (defined retention period
            // requirement).
            await runReflectionPurgeIfDue()
            // ForgeMasteryEngine Phase B — boot the shared
            // ``KitMasteryStore`` against the canonical
            // ``PersistentPlayerProgress`` row. Idempotent guard via
            // `hasBootstrappedKitMasteryStore` mirrors the existing
            // pattern. `fetchOrCreateProgress` already seeds the row
            // on first launch; the store decodes
            // `encodedMasteryState` to hydrate prior FSRS state.
            if !hasBootstrappedKitMasteryStore {
                hasBootstrappedKitMasteryStore = true
                let progress = VoiceTaleStore.fetchOrCreateProgress(in: modelContext)
                kitMasteryStore.bootstrap(progress: progress)
            }
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

    /// ForgeReflection Phase C — read the cadence inputs, ask the
    /// pure-function policy whether to fire, run the purge when due, and
    /// persist the next last-run timestamp. The bucketed analytics event
    /// fires whether or not anything was deleted so cohort engagement
    /// signal includes "the purge ran and removed zero entries this
    /// week" (which is the expected steady state for active kids).
    private func runReflectionPurgeIfDue(now: Date = .now) async {
        let lastPurgeAt: Date? = reflectionPurgeLastRunSinceReference > 0
            ? Date(timeIntervalSinceReferenceDate: reflectionPurgeLastRunSinceReference)
            : nil
        let inputs = ReflectionRetentionInputs(
            lastPurgeAt: lastPurgeAt,
            retentionDays: reflectionRetentionDays
        )
        guard ReflectionRetentionPolicy.shouldPurge(inputs: inputs, now: now) else { return }
        let cutoff = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        do {
            let removed = try await reflectionStore.purgeOlderThan(cutoff)
            reflectionPurgeLastRunSinceReference = now.timeIntervalSinceReferenceDate
            analytics.track(.reflectionsPurged(removed: removed))
        } catch {
            // Phase A scaffold contract — degrade quietly when the
            // storage actor fails. The next eligible launch retries via
            // the same cadence check. No analytics event fires on
            // failure so the wire surface stays "purge succeeded with
            // bucketed count" only.
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

    /// Kid-readable next-session invitation. Calibrated to the current
    /// streak so the line escalates naturally — anti-shame on zero-day
    /// (no streak) variants.
    nonisolated static func nextSessionInvite(streakDays: Int) -> String {
        switch streakDays {
        case ..<1: return "Tomorrow Bramble will be here when you are."
        case 1...2: return "Same time tomorrow keeps the streak warm."
        case 3...6: return "Keep the shape — Bramble will hold your spot."
        default: return "A real streak. See you when the sun's up again."
        }
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

/// Identifiable wrapper carrying the SessionCloserView recap so `.sheet(item:)`
/// can drive presentation. Stored as a separate type rather than reusing the
/// Recap struct because Recap is a `Sendable` value type without `Identifiable`
/// conformance — keeps the public Recap API minimal.
struct SessionCloserRecapWrapper: Identifiable, Sendable {
    let id = UUID()
    let payload: SessionCloserView.Recap
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
