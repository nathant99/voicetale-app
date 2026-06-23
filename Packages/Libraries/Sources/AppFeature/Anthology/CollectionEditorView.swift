import SwiftUI
import Models

/// Phase 2 — kid-facing sheet for creating a new mood collection. Two
/// fields: a kid-chosen name (length-bounded via the persistence layer)
/// + an optional mood tag. Tapping Save delegates to the parent via
/// ``onSave``; the parent handles the actual `VoiceTaleStore.createCollection`
/// + analytics emission so the sheet stays free of side effects.
struct CollectionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedMood: VoiceTaleMood?
    @State private var errorMessage: String?

    /// Returns whether the save succeeded so the sheet can dismiss only
    /// on a clean save (e.g., not on `nameEmpty` / `atCapacity`).
    let onSave: (_ name: String, _ mood: VoiceTaleMood?) -> Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Bedtime spooks", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .accessibilityHint("Name your collection — like 'Friday-funny' or 'Tender ones for Gran'.")
                }
                Section("Mood (optional)") {
                    Picker("Mood", selection: $selectedMood) {
                        Text("Any mood").tag(VoiceTaleMood?.none)
                        ForEach(VoiceTaleMood.allCases, id: \.self) { mood in
                            Text(mood.displayLabel).tag(VoiceTaleMood?.some(mood))
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityHint("Pick a mood theme for this shelf, or leave it for any mood.")
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Couldn't save: \(errorMessage)")
                    }
                }
            }
            .navigationTitle("New collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityHint("Close without creating a collection.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: handleSave)
                        .disabled(trimmedName.isEmpty)
                        .accessibilityHint(
                            trimmedName.isEmpty
                                ? Text("Enter a name first.")
                                : Text("Create this collection and add it to your Anthology shelves.")
                        )
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleSave() {
        errorMessage = nil
        let didSave = onSave(trimmedName, selectedMood)
        if didSave {
            dismiss()
        } else {
            errorMessage = "Couldn't save that collection. You may have reached the limit."
        }
    }
}
