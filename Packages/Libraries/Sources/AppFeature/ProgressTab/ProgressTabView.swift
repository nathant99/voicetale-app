import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeGamification
import ForgeMasteryEngine

/// Phase 1 Progress tab — surfaces XP / level / streak / counted tales /
/// per-mood breakdown. Reads value-type caches from ``VoiceTaleStore`` per
/// `@.claude/rules/swiftdata.md`.
public struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @Environment(\.sessionTimer) private var sessionTimer
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    /// ForgeMasteryEngine Phase C — read the per-(kid, kit) mastery
    /// snapshot to drive the recommendation-first practice surface.
    /// `nil` until ``AppRootView.task`` boots the store; consumer
    /// branches on `nil` to fall back to the single-card surface.
    @Environment(\.kitMasteryStore) private var kitMasteryStore
    @State private var progress: PlayerProgressData = PlayerProgressData()
    @State private var moods: [AnthologyMoodData] = []
    @State private var totalTales: Int = 0
    @State private var earnedBadges: [EarnedBadgeData] = []
    @State private var isPracticePresented: Bool = false
    /// ForgeMasteryEngine Phase C — when set, the upcoming `.sheet`
    /// presents ``QuizView`` with `preselectedKit:` instead of the
    /// week-of-year rotation. Cleared on dismiss so the next tap
    /// re-evaluates against the latest mastery snapshot.
    @State private var pendingPreselectedKit: KitID?

    private let xpEngine = XPEngine(config: GamificationConfig())
    private let recommender = KitMasteryRecommender()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    xpCard
                    streakCard
                    listeningTimeCard
                    practiceSurface
                    badgeShelf
                    moodBreakdown
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Progress")
            .onAppear(perform: reload)
            .sheet(
                isPresented: $isPracticePresented,
                onDismiss: {
                    pendingPreselectedKit = nil
                    reload()
                }
            ) {
                QuizView(preselectedKit: pendingPreselectedKit)
            }
        }
    }

    /// ForgeMasteryEngine Phase C — branches between the legacy single
    /// "Practice with Bramble" card (cold launch / empty engine state)
    /// and the three-card extend / consolidate / stretch surface
    /// (engine has signal). Per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase C.
    @ViewBuilder
    private var practiceSurface: some View {
        let recs = currentRecommendations()
        if recs.isEmpty {
            practiceCard
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Practice with Bramble")
                    .font(.headline)
                    .padding(.horizontal, 4)
                ForEach(recs) { rec in
                    recommendationCard(rec)
                }
            }
        }
    }

    /// Resolve the current three-card recommendations from the
    /// store's cached snapshot. Returns `[]` when the store hasn't
    /// been bootstrapped (preview, unbootstrapped tests, fresh
    /// install before AppRootView.task lands) or when the engine
    /// surfaces nothing.
    private func currentRecommendations() -> [KitMasteryRecommendation] {
        guard let store = kitMasteryStore else { return [] }
        return recommender.recommendations(state: store.cachedStates)
    }

    /// Single recommendation card. Tap surfaces the practice sheet
    /// with the recommended kit preselected. The Bramble copy is
    /// resolved at the catalog seam — never authored inline so the
    /// anti-shame token blocklist stays enforced.
    private func recommendationCard(_ rec: KitMasteryRecommendation) -> some View {
        Button {
            pendingPreselectedKit = rec.kit
            isPracticePresented = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: rec.kind.symbolName)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.kit.displayName)
                        .font(.headline)
                    Text(rec.brambleCopy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .navGridCardSurface(tint: .accentColor, reduceTransparency: reduceTransparency)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Open the \(rec.kit.displayName) practice kit. Four questions; no grades."))
    }

    /// Phase 1.1 entry point — opens ``QuizView`` as a sheet so the kid
    /// can walk through the rotating practice kit. The kit rotates by
    /// week-of-year per ``QuizView`` defaults.
    private var practiceCard: some View {
        Button {
            isPracticePresented = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice with Bramble")
                        .font(.headline)
                    Text("Walk through this week's listening kit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .navGridCardSurface(tint: .accentColor, reduceTransparency: reduceTransparency)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Open this week's practice kit. Four questions; no grades."))
    }

    private var xpCard: some View {
        let level = xpEngine.level(for: progress.xpTotal)
        let progressFraction = xpEngine.xpProgress(currentXP: progress.xpTotal)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.tint)
                Text("Level \(level)")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(progress.xpTotal) XP")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progressFraction)
                .tint(.accentColor)
            Text("Every tale you tell earns Bramble's attention.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    /// COPPA-aligned "today's listening time" surface — reads from the
    /// shared ``SessionTimerCoordinator`` so a single source-of-truth drives
    /// both the daily-cap warnings (5/1 min) and this informational row.
    /// Surface is intentionally low-stakes — kid-readable, no number bigger
    /// than the 30-minute daily cap. Per `@.claude/rules/forgekit.md`
    /// § ForgeAccessibility § session timer.
    private var listeningTimeCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "ear.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's listening time")
                    .font(.headline)
                Text(listeningTimeSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(sessionTimer.timer.formattedRemaining)
                .font(.callout.monospacedDigit())
                .foregroundStyle(sessionTimer.timer.isApproachingLimit ? .orange : .secondary)
                .accessibilityLabel(Text("\(sessionTimer.timer.formattedRemaining) remaining today"))
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var listeningTimeSubtitle: String {
        if sessionTimer.timer.shouldEndSession {
            return "You've reached today's cap. Try again tomorrow."
        }
        if sessionTimer.timer.isApproachingLimit {
            return "Almost at today's cap — wrap up soon."
        }
        return "Daily cap is 30 minutes; you can pause anytime."
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("\(progress.currentStreakDays)-day streak", systemImage: "flame.fill")
                    .font(.headline)
                Text(progress.currentStreakDays == 0
                     ? "Start a streak by telling one tale today."
                     : "Longest so far: \(progress.maxStreakDays) days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("\(totalTales) tales")
                    .font(.headline)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var moodBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Anthology by mood")
                .font(.headline)
            if moods.isEmpty {
                Text("Tag your first tale to start the breakdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(moods) { entry in
                    HStack {
                        Text(entry.displayLabel)
                        Spacer()
                        Text("\(entry.taleCount)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var badgeShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Badges earned")
                .font(.headline)
            if earnedBadges.isEmpty {
                Text("Tell your first tale to earn your first badge.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(earnedBadges) { badge in
                            VStack(spacing: 6) {
                                Image(systemName: "rosette")
                                    .font(.title)
                                    .foregroundStyle(.tint)
                                    .frame(width: 64, height: 64)
                                    .background(.thinMaterial, in: Circle())
                                Text(badge.title)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 96)
                            .accessibilityLabel(Text(badge.title))
                            .accessibilityHint(Text(badge.description))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func reload() {
        progress = VoiceTaleStore.progressSnapshot(in: modelContext)
        moods = VoiceTaleStore.fetchAnthologyMoods(in: modelContext)
        totalTales = moods.reduce(0) { $0 + $1.taleCount }
        // Re-run achievement evaluation on every reload so the shelf
        // reflects badges that were earned out-of-band (e.g., reaching a
        // streak threshold on the next day).
        _ = gamification.evaluateAchievements(in: modelContext)
        earnedBadges = gamification.fetchEarnedBadges(in: modelContext)
    }
}
