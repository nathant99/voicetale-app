import Testing
import Foundation
@testable import Models

@Suite("TaleTrialPromptCatalog")
struct TaleTrialPromptCatalogTests {
    @Test func phase2ShipsEightPrompts() {
        #expect(TaleTrialPromptCatalog.phase2.count == 8)
    }

    @Test func phase2SlugsAreUnique() {
        let slugs = TaleTrialPromptCatalog.phase2.map(\.slug)
        #expect(Set(slugs).count == slugs.count)
    }

    @Test func phase2TextsAreNonEmpty() {
        for prompt in TaleTrialPromptCatalog.phase2 {
            #expect(prompt.text.isEmpty == false)
            #expect(prompt.slug.isEmpty == false)
        }
    }

    @Test func promptLookupResolvesKnownSlug() {
        let prompt = try? #require(TaleTrialPromptCatalog.prompt(forSlug: "hungry_clock"))
        #expect(prompt?.slug == "hungry_clock")
    }

    @Test func promptLookupReturnsNilForUnknownSlug() {
        #expect(TaleTrialPromptCatalog.prompt(forSlug: "not_a_real_slug") == nil)
    }

    @Test func codableRoundTrips() throws {
        let original = TaleTrialPrompt(slug: "test", text: "Tell about a thing.")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaleTrialPrompt.self, from: encoded)
        #expect(decoded == original)
    }
}
