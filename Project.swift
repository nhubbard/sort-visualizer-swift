import ProjectDescription
import ProjectDescriptionHelpers

let modules: [Target] =
    Module.framework(name: "SortEngineKit") +
    Module.framework(name: "AlgorithmKit", dependencies: [.target(name: "SortEngineKit")]) +
    Module.framework(name: "VisualizationKit", dependencies: [.target(name: "SortEngineKit")]) +
    Module.framework(
        name: "ScriptingKit",
        dependencies: [
            .target(name: "AlgorithmKit"), .target(name: "VisualizationKit"),
        ],
        // Same real files the app bundles, referenced directly (no duplication) — lets
        // ScriptingKitTests verify every bundled algorithm/shuffle actually sorts/shuffles
        // correctly via ScriptAlgorithmLoader/ScriptShuffleLoader, the exact code path the real
        // app uses, rather than a hand-picked sample.
        testResources: [
            .folderReference(path: "App/Resources/Algorithms"),
            .folderReference(path: "App/Resources/Shuffles"),
        ]
    ) +
    Module.framework(name: "BuiltInAlgorithms", dependencies: [.target(name: "AlgorithmKit")]) +
    Module.framework(name: "BuiltInVisualizers", dependencies: [.target(name: "VisualizationKit")]) +
    Module.framework(name: "SettingsKit", dependencies: [.target(name: "VisualizationKit"), .target(name: "AlgorithmKit")]) +
    Module.framework(name: "AudioEngineKit", dependencies: [
        .external(name: "AudioKit"), .external(name: "AudioKitUI"), .external(name: "SoundpipeAudioKit"),
        // AudioService imports AudioKitEX directly for Fader — Tuist needs this link edge even
        // though SoundpipeAudioKit already pulls AudioKitEX in transitively for the app target as
        // a whole; a module's own compilation unit still needs to link what it directly imports.
        .external(name: "AudioKitEX"),
        .target(name: "SettingsKit"),
    ]) +
    Module.framework(name: "PersistenceKit", dependencies: [
        .external(name: "DeviceKit"), .target(name: "SortEngineKit"), .target(name: "AlgorithmKit"),
    ]) +
    Module.framework(name: "DesignSystemKit", dependencies: [
        .external(name: "Then"), .target(name: "SettingsKit"),
    ]) +
    Module.framework(name: "MathRenderingKit", dependencies: [
        .external(name: "SwiftMath"), .target(name: "AlgorithmKit"),
    ]) +
    Module.framework(name: "SortFeature", dependencies: [
        .target(name: "SortEngineKit"), .target(name: "AlgorithmKit"), .target(name: "VisualizationKit"),
        .target(name: "AudioEngineKit"), .target(name: "SettingsKit"), .target(name: "DesignSystemKit"),
        .target(name: "PersistenceKit"), .target(name: "MathRenderingKit"), .external(name: "MarkdownUI"),
    ]) +
    Module.framework(name: "SettingsFeature", dependencies: [
        .target(name: "SettingsKit"), .target(name: "VisualizationKit"), .target(name: "AlgorithmKit"),
        .target(name: "AudioEngineKit"), .target(name: "DesignSystemKit"),
    ]) +
    Module.framework(name: "HomeFeature", dependencies: [
        .target(name: "DesignSystemKit"), .external(name: "MarkdownUI"),
    ]) +
    Module.framework(name: "BenchmarkFeature", dependencies: [
        .target(name: "SortEngineKit"), .target(name: "AlgorithmKit"), .target(name: "PersistenceKit"),
    ])

let app = Target.target(
    name: "Sort Symphony",
    destinations: Module.destinations,
    product: .app,
    bundleId: "com.nhubbard.Sort2.mobile",
    deploymentTargets: Module.deploymentTargets,
    infoPlist: .extendingDefault(with: [
        "UIUserInterfaceStyle": "Dark",
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
        "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
        "LSApplicationCategoryType": "public.app-category.education",
        "UIApplicationSupportsIndirectInputEvents": true,
        "ITSAppUsesNonExemptEncryption": false,
        "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
        ],
    ]),
    sources: ["App/Sources/**"],
    resources: [
        .glob(pattern: "App/Resources/**", excluding: [
            "App/Resources/Algorithms/**", "App/Resources/Shuffles/**", "App/Resources/AlgorithmDetails/**",
        ]),
        // Real folder references, not globs — the script loaders (§2.4/§2A.4) look up
        // `Bundle.main.url(forResource:withExtension: nil)` expecting an actual subdirectory,
        // which a glob of loose files wouldn't preserve. Same story for AlgorithmDetails' nested
        // per-algorithm subdirectories (description.md + one .md per code sample language) —
        // Phase 9's detail section reads a specific algorithm's folder as a real subdirectory.
        .folderReference(path: "App/Resources/Algorithms"),
        .folderReference(path: "App/Resources/Shuffles"),
        .folderReference(path: "App/Resources/AlgorithmDetails"),
    ],
    entitlements: .file(path: "App/Resources/Sort Symphony.entitlements"),
    dependencies: [
        .target(name: "SortFeature"), .target(name: "SettingsFeature"),
        .target(name: "HomeFeature"), .target(name: "BenchmarkFeature"),
        .target(name: "MathRenderingKit"),
        // Sort2App wires each module's concrete conformances into its registry
        // (AlgorithmRegistry/VisualizerRegistry), which has no visibility into either module
        // itself — both need to be referenced directly by the App target for that.
        .target(name: "BuiltInAlgorithms"), .target(name: "BuiltInVisualizers"),
        // Composition-root registry wiring (AlgorithmKit's Algorithm/ShuffleRegistry,
        // ScriptingKit's Script*Loader) needs both directly — neither is re-exported by any of the
        // above. DesignSystemKit is needed directly too, for ContentView's CustomIconLabel sidebar
        // rows (Phase 9) — SortFeature/SettingsFeature/HomeFeature all depend on it already, but
        // don't re-export it.
        .target(name: "AlgorithmKit"), .target(name: "ScriptingKit"), .target(name: "DesignSystemKit"),
        .target(name: "SettingsKit"),
    ],
    settings: .settings(base: [
        "CODE_SIGN_ENTITLEMENTS": "App/Resources/Sort Symphony.entitlements",
        "MARKETING_VERSION": "1.4.2",
        "CURRENT_PROJECT_VERSION": "1",
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "676UP3S3AH",
        // Tuist's default template sets CODE_SIGN_IDENTITY[sdk=macosx*] to "-" (ad-hoc) on every
        // target, which silently overrides DEVELOPMENT_TEAM for Mac Catalyst specifically (it
        // builds against the macosx SDK) and breaks entitlements requiring a real certificate
        // (CloudKit, aps-environment). Override back to a real identity, matching the shipping
        // v1 project's explicit setting.
        "CODE_SIGN_IDENTITY": "Apple Development",
        "CODE_SIGN_IDENTITY[sdk=macosx*]": "Apple Development",
    ])
)

let appUITests = Target.target(
    name: "Sort SymphonyUITests",
    destinations: Module.destinations,
    product: .uiTests,
    bundleId: "com.nhubbard.Sort2.mobile.uitests",
    deploymentTargets: Module.deploymentTargets,
    sources: ["App/UITests/**"],
    dependencies: [.target(name: "Sort Symphony")],
    settings: .settings(base: Module.baseSettings)
)

let project = Project(
    name: "Sort Symphony",
    targets: modules + [app, appUITests]
)
