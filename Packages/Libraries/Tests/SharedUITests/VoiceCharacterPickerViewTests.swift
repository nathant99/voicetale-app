import Testing
import SwiftUI
import Models
@testable import SharedUI

@Suite("VoiceCharacterPickerView")
@MainActor
struct VoiceCharacterPickerViewTests {
    @Test func pickerInitializesWithBoundSelection() {
        let binding = Binding<VoiceCharacterPreset>(
            get: { .narrator },
            set: { _ in }
        )
        let view = VoiceCharacterPickerView(selection: binding)
        // Smoke-test that the binding flows through unchanged on init —
        // the picker is value-type-only on the surface.
        #expect(view.selection == .narrator)
    }
}
