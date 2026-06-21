import SwiftUI
import ForgeUI

/// Phase-1 onboarding sequence shown on first launch. Wraps
/// ``ForgeOnboardingFlow`` with the 5-step VoiceTale-specific page set per
/// `@Docs/FEATURE_PLAN.md` § Onboarding:
///
/// 1. Welcome (Bramble intro — warm grandmother register)
/// 2. Microphone permission (parent-handoff page; flagged via `isParentHandoff`)
/// 3. The 5-beat arc (Hook 10s / Setup 20s / Rising 30s / Turn 30s / Close 20s)
/// 4. Transcript review (kid can edit the on-device transcript before Bramble listens)
/// 5. Bramble's first reflection (aha-moment framing — listener-stance, never grades)
///
/// `onComplete` is the canonical entry point — `AppRootView` writes
/// `voicetale.hasCompletedOnboarding = true` in response so the user sees the
/// 4-tab `TabView` on every subsequent launch.
public struct OnboardingFlowView: View {
    private let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ForgeOnboardingFlow(
            pages: Self.pages,
            onComplete: onComplete
        )
    }

    /// The 5 Phase-1 pages — public so the tests can verify shape + copy
    /// without re-instantiating the SwiftUI view tree.
    public static var pages: [ForgeOnboardingFlow.Page] {
        [
            ForgeOnboardingFlow.Page(
                title: "Welcome to VoiceTale",
                body: "Bramble is a quiet listener. You tell the tale; Bramble pays close attention and reflects back what they heard.",
                imageName: "leaf.circle.fill"
            ),
            ForgeOnboardingFlow.Page(
                title: "VoiceTale needs the mic",
                body: "We capture your tale on-device — nothing leaves your phone. A grown-up should approve the mic the first time so you can keep telling without interruptions.",
                imageName: "mic.circle.fill",
                isParentHandoff: true
            ),
            ForgeOnboardingFlow.Page(
                title: "A tale has five beats",
                body: "Hook · Setup · Rising · Turn · Close. About a minute and a half all together — but you can pace each beat however the story wants to be told.",
                imageName: "waveform.path"
            ),
            ForgeOnboardingFlow.Page(
                title: "You'll see your words",
                body: "Right after you stop, VoiceTale will show you the words you said — on-device, in your beats. You can fix anything that didn't come through right.",
                imageName: "text.bubble"
            ),
            ForgeOnboardingFlow.Page(
                title: "Bramble listens back",
                body: "Bramble will share one or two small things they noticed — and ask you a single open question. There are no grades and there's no wrong way to tell a tale.",
                imageName: "ear"
            ),
        ]
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
