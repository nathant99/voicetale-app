import Testing
@testable import AppFeature

/// Locks the ``IntentTabCoordinator`` bridge surface. The intent perform()
/// is exercised indirectly — the coordinator is the seam the intent posts
/// to, and the AppRootView observes. Tests below lock the seam itself so
/// the intent + view layers can change independently.
@MainActor
@Suite("IntentTabCoordinator")
struct IntentTabCoordinatorTests {
    @Test func requestDestinationSetsTabAndLatchesDestination() {
        let coordinator = IntentTabCoordinator.shared
        coordinator.clearRequest()  // ensure clean slate from any prior test
        coordinator.request(destination: .tell)
        #expect(coordinator.requestedTab == .tell)
        #expect(coordinator.lastRequestedDestination == .tell)
    }

    @Test func clearRequestNilsTabButKeepsLastDestination() {
        let coordinator = IntentTabCoordinator.shared
        coordinator.request(destination: .progress)
        coordinator.clearRequest()
        #expect(coordinator.requestedTab == nil)
        // `lastRequestedDestination` survives clear so AppRootView's
        // analytics dispatch can still read the typed destination after
        // it has consumed the tab.
        #expect(coordinator.lastRequestedDestination == .progress)
    }

    @Test func requestTraditionMapsToAdventureTab() {
        let coordinator = IntentTabCoordinator.shared
        coordinator.clearRequest()
        coordinator.request(destination: .tradition)
        #expect(coordinator.requestedTab == .adventure)
    }

    @Test func requestAnthologyMapsToTellTab() {
        // Current router shape (per VoiceTaleIntentRouterTests). Locks
        // the bridge so a router-only change doesn't silently break
        // intent routing — the coordinator translates via the same
        // pure-function mapper.
        let coordinator = IntentTabCoordinator.shared
        coordinator.clearRequest()
        coordinator.request(destination: .anthology)
        #expect(coordinator.requestedTab == .tell)
    }

    @Test func requestProgressMapsToProgressTab() {
        let coordinator = IntentTabCoordinator.shared
        coordinator.clearRequest()
        coordinator.request(destination: .progress)
        #expect(coordinator.requestedTab == .progress)
    }

    @Test func subsequentRequestsOverwriteTabAndLatch() {
        // The coordinator carries the LATEST request only; intents posted
        // in rapid succession (e.g., kid invokes Siri twice quickly) land
        // on the most-recent destination — same intent semantics as
        // SwiftUI `.onChange` of a single `@State` var.
        let coordinator = IntentTabCoordinator.shared
        coordinator.clearRequest()
        coordinator.request(destination: .tell)
        coordinator.request(destination: .tradition)
        #expect(coordinator.requestedTab == .adventure)
        #expect(coordinator.lastRequestedDestination == .tradition)
    }

    @Test func sharedSingletonIsStableAcrossAccessors() {
        // The shared instance is process-singleton — multiple `.shared`
        // reads return the same identity. Sanity-check the contract
        // (`ObjectIdentifier`) so tests don't accidentally compare two
        // distinct instances.
        let a = IntentTabCoordinator.shared
        let b = IntentTabCoordinator.shared
        #expect(ObjectIdentifier(a) == ObjectIdentifier(b))
    }

    @Test func clearWithoutPriorRequestIsIdempotent() {
        // Defensive: clear-on-empty is a no-op. Used by AppRootView's
        // unboarded-kid drop path which clears defensively.
        let coordinator = IntentTabCoordinator.shared
        coordinator.clearRequest()
        coordinator.clearRequest()
        #expect(coordinator.requestedTab == nil)
    }
}

/// Locks the new analytics event landed alongside the coordinator. The
/// event vocabulary is the canonical wire surface — name + properties
/// stay categorical (destination rawValue only; no PII).
@Suite("IntentDestinationRequestedAnalytics")
struct IntentDestinationRequestedAnalyticsTests {
    @Test func eventNameIsIntentDestinationRequested() {
        let event = VoiceTaleAnalyticsEvent.intentDestinationRequested(destination: "tell")
        #expect(event.name == "intent_destination_requested")
    }

    @Test func propertiesCarryDestinationOnly() {
        let event = VoiceTaleAnalyticsEvent.intentDestinationRequested(destination: "progress")
        #expect(event.properties == ["destination": "progress"])
    }

    @Test func everyDestinationRawValueRoundTripsThroughEvent() {
        for destination in VoiceTaleIntentDestination.allCases {
            let event = VoiceTaleAnalyticsEvent.intentDestinationRequested(destination: destination.rawValue)
            #expect(event.properties["destination"] == destination.rawValue,
                    "destination \(destination.rawValue) lost in event property bag")
        }
    }

    @Test func propertiesNeverIncludeRawTabOrPII() {
        // Privacy guard — confirm the property bag is exactly one key
        // ("destination") + the categorical raw value. No tab name, no
        // display label, no user-facing copy.
        let event = VoiceTaleAnalyticsEvent.intentDestinationRequested(destination: "tradition")
        #expect(event.properties.count == 1)
        #expect(event.properties.keys.contains("destination"))
        #expect(event.properties["destination"] == "tradition")
        // Belt-and-suspenders: ensure the property value matches a
        // known-categorical destination (no free text leaked).
        let allowed = Set(VoiceTaleIntentDestination.allCases.map(\.rawValue))
        let value = event.properties["destination"] ?? ""
        #expect(allowed.contains(value), "destination value \(value) is not a valid enum case")
    }
}
