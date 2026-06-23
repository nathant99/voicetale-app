// swift-tools-version: 6.2
// VoiceTale local Swift Package — App shell + Local Packages pattern per
// `.claude/rules/spm-architecture.md`. Open `VoiceTale.xcworkspace`; never
// the `.xcodeproj` directly.

import PackageDescription

let defaultSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-default-isolation", "MainActor"]),
    .enableExperimentalFeature("NonisolatedNonsendingByDefault"),
]

let package = Package(
    name: "VoiceTaleLibraries",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "VoiceAuthoring", targets: ["VoiceAuthoring"]),
        .library(name: "SharedUI", targets: ["SharedUI"]),
        .library(name: "AIMentor", targets: ["AIMentor"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
    ],
    dependencies: [
        // ForgeKit pinned per `.claude/rules/forgekit.md` § Versioning.
        // Bump major versions via Xcode (File > Packages > Update to Latest Package Versions),
        // NOT by editing this file.
        .package(url: "https://github.com/nathant99/forgekit.git", from: "0.99.0"),

        // SwiftLintPlugins SUSPENDED on Xcode 26 per `.claude/rules/swiftlint.md`.
        // Re-enable only after verifying compatibility against the toolchain in use.
        // .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.59.0"),
    ],
    targets: [
        // MARK: - Models
        // Domain types, SwiftData `@Model` classes, value-type cache structs.
        // Foundational target — no UI or service dependencies.
        .target(
            name: "Models",
            dependencies: [
                .product(name: "ForgeModels", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - Services
        // Persistence, audio session management, transcript pipeline, analytics.
        .target(
            name: "Services",
            dependencies: [
                "Models",
                .product(name: "ForgePersistence", package: "forgekit"),
                .product(name: "ForgeAnalytics", package: "forgekit"),
                .product(name: "ForgeAudio", package: "forgekit"),
                .product(name: "ForgeGamification", package: "forgekit"),
                // Phase 2 — saved-tale Spotlight indexing per
                // `@.claude/rules/forgekit.md` § ForgeSpotlight. CoreSpotlight
                // is permissionless; no Info.plist work needed.
                .product(name: "ForgeSpotlight", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - VoiceAuthoring
        // AVAudio capture (44.1 kHz mono 16-bit PCM → AAC/M4A) + 5-beat timeline.
        // Lives in its own target per TECHNICAL_DESIGN.md — replaces the
        // `GameEngine` slot that VoiceTale does not need (no SpriteKit surface).
        .target(
            name: "VoiceAuthoring",
            dependencies: [
                "Models",
                .product(name: "ForgeAudio", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - SharedUI
        // Reusable SwiftUI components, ForgeUI theme integration, beat-timer view.
        .target(
            name: "SharedUI",
            dependencies: [
                "Models",
                "Services",
                .product(name: "ForgeUI", package: "forgekit"),
                .product(name: "ForgeAccessibility", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - AIMentor
        // FoundationModels `@Generable` types, Bramble listening-coach session.
        .target(
            name: "AIMentor",
            dependencies: [
                "Models",
                .product(name: "ForgeAI", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - AppFeature
        // Root view, navigation, app coordinator. ForgeKit deps that span the
        // app (Adventure, Avatar, Celebration, etc.) live here only.
        .target(
            name: "AppFeature",
            dependencies: [
                "Models",
                "Services",
                "VoiceAuthoring",
                "SharedUI",
                "AIMentor",
                .product(name: "ForgeNavigation", package: "forgekit"),
                .product(name: "ForgeUI", package: "forgekit"),
                .product(name: "ForgePedagogy", package: "forgekit"),
                .product(name: "ForgeGamification", package: "forgekit"),
                .product(name: "ForgeAdventure", package: "forgekit"),
                .product(name: "ForgeAvatar", package: "forgekit"),
                .product(name: "ForgeCelebration", package: "forgekit"),
                .product(name: "ForgeModels", package: "forgekit"),
                .product(name: "ForgeSync", package: "forgekit"),
                .product(name: "ForgeAnalytics", package: "forgekit"),
                .product(name: "ForgeProgression", package: "forgekit"),
                .product(name: "ForgeAccessibility", package: "forgekit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: defaultSwiftSettings
        ),

        // MARK: - Tests
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "VoiceAuthoringTests",
            dependencies: ["VoiceAuthoring"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUI"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "AIMentorTests",
            dependencies: ["AIMentor"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"],
            swiftSettings: defaultSwiftSettings
        ),
        .testTarget(
            name: "ForgeKitIntegrationTests",
            dependencies: [
                "Models",
                .product(name: "ForgeModels", package: "forgekit"),
                .product(name: "ForgeGamification", package: "forgekit"),
                .product(name: "ForgeUI", package: "forgekit"),
            ],
            swiftSettings: defaultSwiftSettings
        ),
    ]
)
