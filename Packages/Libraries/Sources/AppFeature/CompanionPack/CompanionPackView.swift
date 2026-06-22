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
    @State private var selectedCover: BookCoverCatalog.Tier?
    @State private var selectedChapter: ChapterIllustrationCatalog.Chapter?

    private let bookCovers: [(tier: BookCoverCatalog.Tier, url: URL)] = BookCoverCatalog.availableCovers()
    private let chapterIllustrations: [(chapter: ChapterIllustrationCatalog.Chapter, variant: ChapterIllustrationCatalog.Variant, url: URL)] = ChapterIllustrationCatalog.availableIllustrations()

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("For Parents & Educators")
                .onAppear(perform: load)
                .sheet(item: previewBinding) { wrapper in
                    PreviewSheet(url: wrapper.url)
                }
                .sheet(item: $selectedCover) { tier in
                    BookCoverDetailSheet(tier: tier)
                }
                .sheet(item: $selectedChapter) { chapter in
                    ChapterIllustrationDetailSheet(chapter: chapter)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !entries.isEmpty {
            ScrollView {
                VStack(spacing: 12) {
                    intro
                    if !bookCovers.isEmpty {
                        booksSection
                    }
                    if !chapterOpeners.isEmpty {
                        chaptersSection
                    }
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

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Featured books")
                .font(.title3.weight(.semibold))
            Text("Two reading-level editions of the VoiceTale chapter book. Read online at spark-and-anvil.com.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(bookCovers, id: \.tier) { entry in
                    Button {
                        selectedCover = entry.tier
                    } label: {
                        coverThumbnail(tier: entry.tier, url: entry.url)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Show the \(entry.tier.displayTitle) cover and reading-tier info.")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func coverThumbnail(tier: BookCoverCatalog.Tier, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverImage(url: url)
                .aspectRatio(2 / 3, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
            Text(tier.rawValue.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Text(tier.audienceLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
    }

    /// Chapter openers, in canonical (Lean / Pivot / Refrain / Slow) order.
    /// Empty list = the chapter WebPs aren't bundled yet, which gates the
    /// section's render so the surface gracefully degrades.
    private var chapterOpeners: [(chapter: ChapterIllustrationCatalog.Chapter, url: URL)] {
        chapterIllustrations.filter { $0.variant == .opener }.map { ($0.chapter, $0.url) }
    }

    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DN-S chapter book")
                .font(.title3.weight(.semibold))
            Text("Each cast friend gets a chapter that teaches one oral-craft primitive. Tap a cover to read the chapter primer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(chapterOpeners, id: \.chapter) { entry in
                        Button {
                            selectedChapter = entry.chapter
                        } label: {
                            chapterThumbnail(chapter: entry.chapter)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Open the \(entry.chapter.displayName) chapter primer.")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func chapterThumbnail(chapter: ChapterIllustrationCatalog.Chapter) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ChapterIllustrationView(chapter: chapter, variant: .opener)
                .aspectRatio(3 / 4, contentMode: .fit)
                .frame(width: 132)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
            Text(chapter.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(width: 132, alignment: .leading)
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

/// Loads a bundled WebP cover via `AsyncImage`-equivalent file-URL path so
/// it works inside SPM test runs and SwiftUI previews.
private struct CoverImage: View {
    let url: URL

    var body: some View {
        #if canImport(UIKit)
        if let image = UIImage(contentsOfFile: url.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
        #else
        placeholder
        #endif
    }

    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "book.closed.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
    }
}

/// Modal sheet that shows the full-resolution book cover + reading-tier
/// context + a `Link` out to the spark-and-anvil.com PDF for the same tier.
/// Per `Docs/HANDOFF_FROM_HUB_BOOK_COVERS.md`, the PDFs live on the website
/// and aren't bundled in-app yet; the app surfaces the covers as a teaser.
private struct BookCoverDetailSheet: View {
    let tier: BookCoverCatalog.Tier

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let url = BookCoverCatalog.coverURL(tier: tier) {
                        CoverImage(url: url)
                            .aspectRatio(2 / 3, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tier.displayTitle)
                            .font(.title3.weight(.semibold))
                        Text(tier.audienceLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(tier.description)
                        .font(.body)
                    if let webURL = URL(string: "https://spark-and-anvil.com\(tier.websitePath)") {
                        Link(destination: webURL) {
                            Label("Read on spark-and-anvil.com", systemImage: "safari.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityHint("Opens the chapter book PDF in your default web browser.")
                    }
                    Text("PDF books live on the website for now — read online or print at home. The covers ship inside the app so you can preview what you're heading to.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Featured book")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Modal sheet showing the full-resolution chapter opener + spot illustration
/// + the craft-primitive text per chapter. Links out to the spark-and-anvil.com
/// chapter book PDF — same pattern as `BookCoverDetailSheet`.
private struct ChapterIllustrationDetailSheet: View {
    let chapter: ChapterIllustrationCatalog.Chapter

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ChapterIllustrationView(chapter: chapter, variant: .opener, cornerRadius: 16)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.quaternary, lineWidth: 1)
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapter.displayName)
                            .font(.title2.weight(.semibold))
                        Text(chapter.craftPrimitive)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    if ChapterIllustrationCatalog.illustrationURL(chapter: chapter, variant: .spot) != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("In the chapter")
                                .font(.subheadline.weight(.semibold))
                            ChapterIllustrationView(chapter: chapter, variant: .spot, cornerRadius: 12)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    if let webURL = URL(string: "https://spark-and-anvil.com/cast/voicetale/\(chapter.rawValue)") {
                        Link(destination: webURL) {
                            Label("Read the full chapter", systemImage: "safari.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityHint("Opens \(chapter.displayName)'s chapter on spark-and-anvil.com in your default browser.")
                    }
                    Text("Chapter text lives on the website (and inside the dual-tier PDF book) — these illustrations are the in-app primer that introduces what each friend teaches.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Chapter primer")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
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
