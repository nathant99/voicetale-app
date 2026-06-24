import SwiftUI
import Models

/// Phase Delight & Polish — focused cover-editing sheet for an EXISTING
/// kid-curated collection. Mirrors ``CollectionEditorView`` (the new-
/// collection sheet) but locks the name + mood fields so the kid can
/// re-style a collection without accidentally renaming it. Per
/// `@Docs/SESSION_HANDOFF_2026-06-24_TENTH_ROUND.md` § "Recommended
/// next-session priorities" → Anthology cover editing.
///
/// Reuses the same ``AnthologyCoverView`` preview + ``AnthologyCoverDesign``
/// picker as the new-collection sheet; the only difference is that
/// `name` + `mood` come from the existing collection and are not
/// editable here. The Save closure receives the new cover (or `nil` for
/// the auto-derived default) so the parent can persist via
/// ``VoiceTaleStore.updateCollectionCover``.
struct CollectionCoverEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCover: AnthologyCoverDesign

    let collection: MoodCollectionData
    /// Returns whether the save succeeded so the sheet can dismiss only
    /// on a clean save. Mirrors ``CollectionEditorView``'s onSave shape.
    let onSave: (_ cover: AnthologyCoverDesign?) -> Bool

    init(
        collection: MoodCollectionData,
        onSave: @escaping (_ cover: AnthologyCoverDesign?) -> Bool
    ) {
        self.collection = collection
        self.onSave = onSave
        _selectedCover = State(
            initialValue: AnthologyCoverDesign.resolve(slug: collection.coverArtSlug)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Collection") {
                    HStack(spacing: 12) {
                        Text(collection.name)
                            .font(.callout.weight(.semibold))
                        Spacer()
                        Text(moodSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(collection.name), \(moodSummary)"))
                }
                Section("Cover") {
                    coverPreviewRow
                    Picker("Style", selection: $selectedCover) {
                        ForEach(AnthologyCoverDesign.allCases, id: \.self) { design in
                            Label(design.displayLabel, systemImage: design.pickerSymbolName)
                                .tag(design)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityHint("Pick a different cover for this shelf.")
                }
            }
            .navigationTitle("Change cover")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityHint("Close without changing the cover.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: handleSave)
                        .accessibilityHint("Use this cover for the shelf.")
                }
            }
        }
    }

    private var moodSummary: String {
        collection.mood?.displayLabel ?? "Any mood"
    }

    private var coverPreviewRow: some View {
        HStack(spacing: 12) {
            AnthologyCoverView(
                design: selectedCover,
                collectionName: collection.name,
                mood: collection.mood,
                firstTaleTitle: nil
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedCover.displayLabel)
                    .font(.callout.weight(.medium))
                Text("Cover preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func handleSave() {
        // Mirror ``CollectionEditorView``: pass `nil` for the auto-derived
        // default so legacy + auto-derived covers share the same wire
        // shape — only kid-chosen non-default selections carry a slug.
        let coverSelection: AnthologyCoverDesign? = selectedCover == .autoGlyph ? nil : selectedCover
        if onSave(coverSelection) {
            dismiss()
        }
    }
}
