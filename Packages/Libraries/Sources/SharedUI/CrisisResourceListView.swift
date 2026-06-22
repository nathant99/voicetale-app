import SwiftUI
import Models

/// Canonical crisis-resource list surface. Used by:
/// - ``SettingsView`` — the formal grown-ups-tab list
/// - ``BrambleReflectionView`` distress chip — when
///   ``DistressSignalDetector`` surfaces a non-`nil` axis on the tale
///
/// Per `@.claude/rules/trauma-informed-content.md` § "refer up" + ADR-016:
/// the list MUST be available at every surface where Bramble holds space
/// for distress, AND from the parent-facing settings. Centralizing the
/// rendering here keeps the layout + accessibility + Reduce-Motion
/// posture consistent.
public struct CrisisResourceListView: View {
    public let resources: [CrisisResource]
    public let header: String?
    public let footer: String?

    public init(
        resources: [CrisisResource],
        header: String? = nil,
        footer: String? = nil
    ) {
        self.resources = resources
        self.header = header
        self.footer = footer
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let header {
                Text(header)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ForEach(resources) { resource in
                resourceRow(resource)
            }
            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(header ?? "Crisis resources"))
    }

    @ViewBuilder
    private func resourceRow(_ resource: CrisisResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(resource.name)
                .font(.body.weight(.semibold))
            if let phone = resource.phone, !phone.isEmpty {
                Label(phone, systemImage: "phone.fill")
                    .font(.caption)
                    .accessibilityLabel(Text("Phone: \(phone)"))
            }
            if let text = resource.text, !text.isEmpty {
                Label(text, systemImage: "message.fill")
                    .font(.caption)
                    .accessibilityLabel(Text("Text: \(text)"))
            }
            if let url = resource.url, !url.isEmpty {
                Label(url, systemImage: "globe")
                    .font(.caption)
                    .accessibilityLabel(Text("Web: \(url)"))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CrisisResourceListView(
        resources: [
            CrisisResource(name: "988 Suicide & Crisis Lifeline", phone: "988", text: nil, url: nil),
            CrisisResource(name: "Crisis Text Line", phone: nil, text: "Text HOME to 741741", url: nil),
        ],
        header: "If a tale brings something up",
        footer: "These resources are available in the United States."
    )
    .padding()
}
