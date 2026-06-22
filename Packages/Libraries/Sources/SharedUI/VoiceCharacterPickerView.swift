import SwiftUI
import Models

/// Horizontal chip strip picker for Phase 1.1 voice characters. Renders
/// every preset from ``VoiceCharacterCatalog/phase1`` as a tappable
/// capsule with the preset's SF Symbol + display name; the selected
/// capsule fills with the accent color.
///
/// Phase 1.1 foundation PR ships the picker UI; the next PR wires it to
/// the TellView per-beat selection + the AnthologyAudioPlayer playback
/// graph (`AVAudioUnitTimePitch`).
public struct VoiceCharacterPickerView: View {
    @Binding public var selection: VoiceCharacterPreset

    public init(selection: Binding<VoiceCharacterPreset>) {
        self._selection = selection
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(VoiceCharacterCatalog.phase1) { preset in
                    chip(for: preset)
                }
            }
            .padding(.horizontal)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Voice character"))
    }

    @ViewBuilder
    private func chip(for preset: VoiceCharacterPreset) -> some View {
        let isSelected = selection == preset
        Button {
            selection = preset
        } label: {
            HStack(spacing: 6) {
                Image(systemName: preset.symbolName)
                    .font(.callout)
                Text(preset.displayName)
                    .font(.callout.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected
                    ? Color.accentColor.opacity(0.18)
                    : Color.secondary.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(preset.displayName))
        .accessibilityHint(Text(preset.description))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
