import Testing
import Foundation
import SwiftUI
@testable import AppFeature
import ForgeAvatar
import ForgeModels
import ForgeSync

@Suite("AvatarStudioSheet")
struct AvatarStudioSheetTests {
    @Test func sheetInitializesWithDefaults() {
        // The sheet must compose against `AppGroupStore` with default
        // arguments so the call site in `ProfileTabView` stays a
        // one-liner. ForgeKit 1.0.0-rc.1 removed the `AvatarAssetCatalog`
        // surface — the editor is single-presentation now.
        let sheet = AvatarStudioSheet(onDismiss: {})
        _ = sheet.body
    }

    @Test func sheetAcceptsExplicitStore() {
        // Explicit-injection path covers per-app testing setups (e.g.,
        // future SnapshotTest harnesses or fake stores).
        let store = AppGroupStore(suiteName: "test-\(UUID().uuidString)")
        let sheet = AvatarStudioSheet(
            appGroupStore: store,
            onDismiss: {}
        )
        _ = sheet.body
    }

    @Test func seedingForgeIDIsIdempotent() async {
        // AvatarStudioView.Save throws AppGroupStoreError.forgeIDMissing
        // (= "error 0") unless an identity has been seeded first per
        // `@.claude/rules/forgekit.md` § Common Gotchas. Verify that
        // `getOrCreateForgeID` from AppGroupStore is safe to call repeatedly
        // without producing a different identity each time — the sheet calls
        // it on every `.task` invocation; that path must be a no-op once seeded.
        let store = AppGroupStore(suiteName: "test-seeding-\(UUID().uuidString)")
        let first = await store.getOrCreateForgeID(displayName: "Storyteller")
        let second = await store.getOrCreateForgeID(displayName: "Storyteller")
        #expect(first.id == second.id)
    }
}
