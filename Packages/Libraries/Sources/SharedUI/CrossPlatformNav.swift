import SwiftUI

/// Tiny cross-platform shim — `navigationBarTitleDisplayMode` is iOS-only per
/// `@.claude/rules/warnings.md` § Platform Availability. Wrapping the call
/// behind this extension lets the same view tree compile on macOS without a
/// scatter of `#if os(iOS)` checks.
public extension View {
    @ViewBuilder
    func voiceTaleNavigationTitle(_ title: String, large: Bool = true) -> some View {
        #if os(iOS) || os(tvOS) || os(visionOS)
        self.navigationTitle(title)
            .navigationBarTitleDisplayMode(large ? .large : .inline)
        #else
        self.navigationTitle(title)
        #endif
    }
}
