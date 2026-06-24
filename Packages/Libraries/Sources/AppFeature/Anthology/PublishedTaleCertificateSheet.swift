import SwiftUI
import Models

/// Delight & Polish "Share-worthy moments" — sheet that renders a
/// published-tale certificate from a saved ``VoiceTaleEntry``. The
/// certificate composition is a pure SwiftUI card (no AI image gen per
/// ADR-016). The sheet hands the kid two affordances:
///
/// 1. Read the certificate visually
/// 2. Save / share via the system share sheet — `ShareLink` plus
///    `ImageRenderer` rasterizes the card to a PNG for AirDrop / Photos /
///    Messages.
///
/// Per @Docs/FEATURE_PLAN.md § Phase Delight & Polish — Share-worthy
/// moments — published-tale certificates carry-over.
struct PublishedTaleCertificateSheet: View {
    let tale: VoiceTaleEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    certificateCard
                        .padding(.top, 24)
                    shareAffordance
                    Text(
                        "This certificate is rendered on this device. Save it to your camera roll, or share via AirDrop / Messages."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Certificate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// The certificate composition — pure SwiftUI; rasterized via
    /// ``ImageRenderer`` for the share affordance. Composition driven by
    /// ``PublishedTaleCertificate``'s pure-function `compose(from:)`.
    private var certificateCard: some View {
        let certificate = PublishedTaleCertificate.compose(from: tale)
        return VStack(spacing: 14) {
            Image(systemName: "rosette")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.tint)
            Text("Published Tale")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .tracking(2)
            Text(certificate.title)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            HStack(spacing: 10) {
                badge(certificate.moodLabel, systemImage: "leaf.fill")
                badge(certificate.beatBadge, systemImage: "circle.dotted")
            }
            Divider().padding(.horizontal, 32)
            Text(certificate.headline)
                .font(.body.italic())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .foregroundStyle(.primary)
            Text(certificate.dateLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .padding(28)
        .frame(maxWidth: 340)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.tint.opacity(0.4), lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                "Certificate for \(certificate.title), a \(certificate.moodLabel) tale. \(certificate.headline) Recorded \(certificate.dateLabel)."
            )
        )
    }

    private func badge(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.tint.opacity(0.15), in: Capsule())
    }

    /// Renders the certificate card to a PNG and exposes it via
    /// ``ShareLink``. Falls back to a placeholder image link when
    /// rasterization yields nil (defensive — `ImageRenderer.uiImage`
    /// returns Optional). The system share sheet handles save-to-Photos,
    /// AirDrop, Messages, etc.
    private var shareAffordance: some View {
        let image = renderedImage()
        return Group {
            if let image {
                ShareLink(
                    item: image,
                    preview: SharePreview("\(tale.title) certificate", image: image)
                ) {
                    Label("Save or Share", systemImage: "square.and.arrow.up")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Save not available right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func renderedImage() -> Image? {
        let renderer = ImageRenderer(content: certificateCard)
        renderer.scale = displayScale
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

extension VoiceTaleEntry {
    /// Sheet identity — the sheet uses `.sheet(item: $certificateTale)`
    /// which requires `Identifiable`. ``VoiceTaleEntry`` already conforms
    /// via its `id: UUID` field.
    public var certificateID: UUID { id }
}
