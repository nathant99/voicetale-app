import SwiftUI
import ForgeAvatar
import ForgeModels
import ForgeSync

/// VoiceTale's avatar editor host. ForgeKit 1.0.0-rc.1 simplified
/// ``ForgeAvatar`` to an Apple Contacts-style single-presentation
/// editor per labsmith ADR-022 — the prior `.lite`/`.full` toggle +
/// `AvatarAssetCatalog` are removed. The editor now ships tint +
/// initial/symbol/emoji glyph picking only; cosmetic accessory layers
/// are gone portfolio-wide.
///
/// **App Group note**: in-app-only by default — the `AppGroupStore(suiteName: nil)`
/// init falls back to standard `UserDefaults` when the App Group entitlement is
/// absent. Cross-portfolio avatar propagation requires the user to wire the
/// `group.spark-anvil.shared` App Group entitlement in Xcode (Target →
/// Signing & Capabilities). See `Docs/HANDOFF_TO_USER_APP_GROUP_ENTITLEMENT.md`
/// when filed.
///
/// **Load-bearing gotcha** per `@.claude/rules/forgekit.md` § Common Gotchas:
/// `AvatarStudioView`'s Save flow calls `AppGroupStore.setAvatar(_:editedAt:)`
/// which throws `.forgeIDMissing` ("error 0") unless an identity has been
/// seeded first. We seed via `getOrCreateForgeID(displayName:)` in `.task`
/// before the user can tap Save.
public struct AvatarStudioSheet: View {
    public let appGroupStore: AppGroupStore
    public let onDismiss: () -> Void

    @State private var initialConfig: AvatarConfig = .default
    @State private var baselineEditedAt: Date?
    @State private var didSeed: Bool = false

    public init(
        appGroupStore: AppGroupStore = AppGroupStore(),
        onDismiss: @escaping () -> Void
    ) {
        self.appGroupStore = appGroupStore
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            AvatarStudioView(
                initialConfig: initialConfig,
                baselineEditedAt: baselineEditedAt,
                displayName: "Storyteller",
                appGroupStore: appGroupStore,
                onSaved: { _ in onDismiss() },
                onCancelled: { onDismiss() }
            )
            .navigationTitle("Avatar")
        }
        .task {
            await seedIdentityIfNeeded()
            await refreshBaselineConfig()
        }
    }

    /// Seeds the shared `ForgeID` so `AvatarStudioView.Save` doesn't throw
    /// `.forgeIDMissing`. Idempotent: subsequent `.task` invocations skip via
    /// `didSeed`.
    private func seedIdentityIfNeeded() async {
        guard !didSeed else { return }
        _ = await appGroupStore.getOrCreateForgeID(displayName: "Storyteller")
        didSeed = true
    }

    /// Re-read the latest avatar config + edited-at timestamp BEFORE opening
    /// the editor — the player may have edited in another app since this app
    /// last looked, per `@.claude/rules/forgekit.md` § Avatar Edit Authority.
    private func refreshBaselineConfig() async {
        if let existing = await appGroupStore.currentForgeID()?.avatar {
            initialConfig = existing
        }
        baselineEditedAt = await appGroupStore.currentForgeID()?.avatarEditedAt
    }
}
