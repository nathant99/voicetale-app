import SwiftUI
import Models
import SharedUI
import AIMentor

public struct AppRootView: View {
    public enum AppTab: String, Hashable, CaseIterable {
        case tell, adventure, progress, profile

        public var title: String {
            switch self {
            case .tell:      return "Tell"
            case .adventure: return "Adventure"
            case .progress:  return "Progress"
            case .profile:   return "Profile"
            }
        }

        public var systemImage: String {
            switch self {
            case .tell:      return "mic.circle.fill"
            case .adventure: return "map.fill"
            case .progress:  return "chart.bar.fill"
            case .profile:   return "person.circle.fill"
            }
        }
    }

    @State private var selectedTab: AppTab = .tell

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.tell.title, systemImage: AppTab.tell.systemImage, value: AppTab.tell) {
                TellPlaceholderView()
            }
            Tab(AppTab.adventure.title, systemImage: AppTab.adventure.systemImage, value: AppTab.adventure) {
                AdventurePlaceholderView()
            }
            Tab(AppTab.progress.title, systemImage: AppTab.progress.systemImage, value: AppTab.progress) {
                ProgressPlaceholderView()
            }
            Tab(AppTab.profile.title, systemImage: AppTab.profile.systemImage, value: AppTab.profile) {
                ProfilePlaceholderView()
            }
        }
    }
}

struct TellPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Tell a tale",
            systemImage: "mic.circle",
            description: Text("Phase 1 record-a-tale loop lands here.")
        )
    }
}

struct AdventurePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Word Workshop",
            systemImage: "map",
            description: Text("Phase 1 Word Workshop hub mode-cards land here.")
        )
    }
}

struct ProgressPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Progress",
            systemImage: "chart.bar",
            description: Text("XP, streak, and oral-craft attunement chart land here.")
        )
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Profile",
            systemImage: "person.circle",
            description: Text("AvatarStudioView (R3 segmented .lite + .full) lands here.")
        )
    }
}
