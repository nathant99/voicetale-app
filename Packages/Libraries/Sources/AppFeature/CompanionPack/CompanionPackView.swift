import SwiftUI
import QuickLook
import Models
import Services
import SharedUI

/// "For Parents & Educators" surface. Renders the bundled companion-pack
/// PDFs (coloring sheets / cast poster / parent letter) as tappable cards.
/// Opens each PDF in a native `QLPreviewController`-backed sheet so the
/// grown-up can print / share via the system share sheet.
public struct CompanionPackView: View {
    @State private var entries: [CompanionPackPDF] = []
    @State private var loadError: String?
    @State private var previewURL: URL?

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("For Parents & Educators")
                .onAppear(perform: load)
                .sheet(item: previewBinding) { wrapper in
                    PreviewSheet(url: wrapper.url)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !entries.isEmpty {
            ScrollView {
                VStack(spacing: 12) {
                    intro
                    ForEach(entries) { entry in
                        card(for: entry)
                    }
                }
                .padding()
            }
        } else if let loadError {
            ContentUnavailableView(
                "Couldn't load the companion pack",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError)
            )
        } else {
            ProgressView().padding()
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Print + share")
                .font(.title3.weight(.semibold))
            Text("These pages print on standard letter paper. Use them as screen-free reinforcement, classroom posters, or send-home pages for your child.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(for entry: CompanionPackPDF) -> some View {
        Button {
            do {
                previewURL = try CompanionPackLoader.url(forPDF: entry.fileName)
            } catch {
                loadError = "Couldn't open \(entry.fileName): \(error)"
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.tint.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: entry.systemImage)
                        .font(.system(size: 24))
                        .foregroundStyle(.tint)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(entry.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Open \(entry.title) PDF in the preview sheet.")
    }

    private var previewBinding: Binding<PreviewWrapper?> {
        Binding(
            get: { previewURL.map(PreviewWrapper.init) },
            set: { previewURL = $0?.url }
        )
    }

    private func load() {
        guard entries.isEmpty else { return }
        do {
            entries = try CompanionPackLoader.loadEntries()
        } catch {
            loadError = "\(error)"
        }
    }
}

private struct PreviewWrapper: Identifiable {
    let url: URL
    var id: URL { url }
}

#if canImport(UIKit)

private struct PreviewSheet: View {
    let url: URL

    var body: some View {
        QuickLookPreview(url: url)
            .ignoresSafeArea()
    }
}

import UIKit

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {
        controller.reloadData()
    }

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

#else

private struct PreviewSheet: View {
    let url: URL
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 56))
            Text(url.lastPathComponent)
                .font(.headline)
            Link("Open in default viewer", destination: url)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#endif
