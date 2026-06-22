import Testing
import SwiftUI
import Models
@testable import SharedUI

@Suite("CrisisResourceListView")
@MainActor
struct CrisisResourceListViewTests {
    @Test func viewInitializesWithResources() {
        let view = CrisisResourceListView(
            resources: [
                CrisisResource(name: "988", phone: "988", text: nil, url: nil)
            ],
            header: "Help"
        )
        #expect(view.resources.count == 1)
        #expect(view.header == "Help")
    }

    @Test func viewHandlesEmptyResources() {
        let view = CrisisResourceListView(resources: [])
        #expect(view.resources.isEmpty)
        #expect(view.header == nil)
    }

    @Test func viewSurfacesEveryResourceField() {
        let view = CrisisResourceListView(
            resources: [
                CrisisResource(
                    name: "Crisis Text Line",
                    phone: nil,
                    text: "Text HOME to 741741",
                    url: "https://crisistextline.org"
                )
            ]
        )
        let resource = view.resources.first!
        #expect(resource.text == "Text HOME to 741741")
        #expect(resource.url == "https://crisistextline.org")
        #expect(resource.phone == nil)
    }
}
