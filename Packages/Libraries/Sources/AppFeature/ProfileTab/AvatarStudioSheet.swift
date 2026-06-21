import SwiftUI
import ForgeAvatar
import ForgeModels
import ForgeSync

/// VoiceTale's avatar editor host. Writing-craft cluster pattern per
/// `@.claude/rules/forgekit.md` § Avatar Edit Authority — R3 segmented
/// `.lite`+`.full` toggle (best-in-class; matches the QuillSpell reference impl).
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
    public let catalog: AvatarAssetCatalog
    public let onDismiss: () -> Void

    @State private var presentation: AvatarStudioView.Presentation = .lite
    @State private var initialConfig: AvatarConfig = .default
    @State private var baselineEditedAt: Date?
    @State private var didSeed: Bool = false

    public init(
        appGroupStore: AppGroupStore = AppGroupStore(),
        catalog: AvatarAssetCatalog = AvatarAssetCatalog(appBundles: []),
        onDismiss: @escaping () -> Void
    ) {
        self.appGroupStore = appGroupStore
        self.catalog = catalog
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Customize", selection: $presentation) {
                    Text("Simple").tag(AvatarStudioView.Presentation.lite)
                    Text("All options").tag(AvatarStudioView.Presentation.full)
                }
                .pickerStyle(.segmented)
                .padding()

                AvatarStudioView(
                    initialConfig: initialConfig,
                    baselineEditedAt: baselineEditedAt,
                    catalog: catalog,
                    presentation: presentation,
                    appGroupStore: appGroupStore,
                    onSaved: { _ in onDismiss() },
                    onCancelled: { onDismiss() }
                )
                .id(presentation)
            }
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
