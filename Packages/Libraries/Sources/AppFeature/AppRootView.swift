import SwiftUI
import SwiftData
import Models
import Services
import ForgeAdventure

/// Environment slot for the shared ``GamificationService`` instance. Views
/// award XP / record sessions / evaluate achievements via this key per
/// `@.claude/rules/swiftui.md` § `@Entry` macro.
extension EnvironmentValues {
    @Entry public var gamificationService: GamificationService = GamificationService()
    @Entry public var analyticsService: AnalyticsService = AnalyticsService()
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
    /// into a separate constants file.
    public static let onboardingCompletedKey = "voicetale.hasCompletedOnboarding"

    @State private var selectedTab: AppTab = .tell
    @State private var gamification = GamificationService()
    @State private var analytics = AnalyticsService()
    @State private var hasBootstrapped = false
    @AppStorage(AppRootView.onboardingCompletedKey) private var hasCompletedOnboarding: Bool = false

    /// Shared registry the source-app's ``VoiceTaleHubContribution`` registers
    /// with on launch. Other portfolio surfaces (e.g., AdventureHub) read from
    /// the same registry once VoiceTale is opted-in cross-app. Stored as an
    /// actor reference so registration can happen off the main actor.
    private let hubRegistry = HubContributionRegistry()

    public init() {}

    public var body: some View {
        Group {
            if hasCompletedOnboarding {
                tabSurface
            } else {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .environment(\.gamificationService, gamification)
        .environment(\.analyticsService, analytics)
        .task {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            analytics.startSession()
            analytics.track(.sessionStarted)
            await hubRegistry.register(VoiceTaleHubContribution())
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
