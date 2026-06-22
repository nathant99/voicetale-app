import Testing
@testable import SharedUI

/// ``HapticsBridge`` is a thin facade over ``ForgeHapticEngine``; the
/// underlying engine silently no-ops on devices without a Taptic Engine
/// (iPad, Simulator) so we can call every entry point unconditionally and
/// only verify they don't trap. The semantic guarantee is *the bridge exists
/// + every entry point is callable* — pattern fidelity is owned by ForgeKit.
@Suite("HapticsBridge facade")
struct HapticsBridgeTests {
    @Test func everyEntryPointIsCallableWithoutTrapping() {
        HapticsBridge.fireRecordStart()
        HapticsBridge.fireTaleSaved()
        HapticsBridge.fireLevelUp()
        HapticsBridge.fireStreakMilestone()
        HapticsBridge.fireSessionWarning()
        // Reaching this line proves none of the call sites trapped on this
        // process / simulator surface.
        #expect(Bool(true))
    }
}
