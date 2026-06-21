import Testing
@testable import AppFeature

@MainActor
@Suite("OnboardingFlowView")
struct OnboardingFlowViewTests {
    @Test func phase1ShipsFivePages() {
        #expect(OnboardingFlowView.pages.count == 5)
    }

    @Test func everyPageHasNonEmptyCopy() {
        for (index, page) in OnboardingFlowView.pages.enumerated() {
            #expect(!page.title.isEmpty, "Empty title for page \(index)")
            #expect(!page.body.isEmpty, "Empty body for page \(index)")
        }
    }

    @Test func micPermissionPageFlagsParentHandoff() {
        // The Phase-1 micrhone permission page is the only parent-handoff
        // surface — every other page is kid-facing.
        let parentPages = OnboardingFlowView.pages.filter { $0.isParentHandoff }
        #expect(parentPages.count == 1)
        let micPage = parentPages.first
        #expect(micPage?.title.lowercased().contains("mic") == true)
    }

    @Test func everyPageHasASFSymbolHero() {
        // Phase 1 uses SF Symbol heroes — no Lottie / illustration assets yet.
        // This pins the contract so the labsmith mascot-illustration pipeline
        // landing later doesn't silently break the fallback hero.
        for page in OnboardingFlowView.pages {
            #expect(page.imageName != nil, "Missing SF Symbol hero for: \(page.title)")
        }
    }

    @Test func welcomePageMentionsBramble() {
        let welcome = OnboardingFlowView.pages.first
        #expect(welcome?.body.localizedCaseInsensitiveContains("bramble") == true)
    }

    @Test func appRootStorageKeyIsStable() {
        // Pin the AppStorage key so a rename never silently re-onboards
        // returning users.
        #expect(AppRootView.onboardingCompletedKey == "voicetale.hasCompletedOnboarding")
    }
}
