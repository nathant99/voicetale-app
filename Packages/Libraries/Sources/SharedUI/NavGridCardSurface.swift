import SwiftUI

/// Category-C "nav-grid card" Liquid Glass surface per the portfolio
/// `@.claude/rules/liquid-glass.md` § Portfolio Hybrid Liquid Glass policy.
///
/// Nav-grid cards (Adventure mode-cards, Progress "Practice with Bramble"
/// drill-down, future hub-contribution surfaces) drill INTO deeper content
/// — they are navigation affordances per Apple HIG "glass = nav layer," not
/// content-display surfaces. Content-display cards (hero, joke, anthology,
/// stat) stay solid via `.thinMaterial`.
///
/// `accessibilityReduceTransparency` collapses the glass to a solid tint so
/// WCAG AA contrast is preserved when the user has the system setting on.
/// Both branches keep the `RoundedRectangle(cornerRadius: 16)` shape.
public struct NavGridCardSurface: ViewModifier {
    public let tint: Color
    public let reduceTransparency: Bool
    public let cornerRadius: CGFloat

    public init(tint: Color, reduceTransparency: Bool, cornerRadius: CGFloat = 16) {
        self.tint = tint
        self.reduceTransparency = reduceTransparency
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .glassEffect(
                    .regular.tint(tint.opacity(0.22)).interactive(),
                    in: .rect(cornerRadius: cornerRadius)
                )
        }
    }
}

extension View {
    /// Convenience for category-C nav-grid card surfaces. Reads
    /// `@Environment(\.accessibilityReduceTransparency)` from the caller —
    /// callers must pass it explicitly so the modifier stays a pure value
    /// type usable in any context.
    public func navGridCardSurface(
        tint: Color,
        reduceTransparency: Bool,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(NavGridCardSurface(
            tint: tint,
            reduceTransparency: reduceTransparency,
            cornerRadius: cornerRadius
        ))
    }
}
