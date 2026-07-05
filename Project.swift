import ProjectDescription
import ProjectDescriptionHelpers

let modules: [Target] =
    Module.framework(name: "SortEngineKit") +
    Module.framework(name: "AlgorithmKit", dependencies: [.target(name: "SortEngineKit")]) +
    Module.framework(name: "VisualizationKit", dependencies: [.target(name: "SortEngineKit")]) +
    Module.framework(name: "ScriptingKit", dependencies: [
        .target(name: "AlgorithmKit"), .target(name: "VisualizationKit"),
    ]) +
    Module.framework(name: "BuiltInAlgorithms", dependencies: [.target(name: "AlgorithmKit")]) +
    Module.framework(name: "BuiltInVisualizers", dependencies: [.target(name: "VisualizationKit")]) +
    Module.framework(name: "AudioEngineKit", dependencies: [
        .external(name: "AudioKit"), .external(name: "AudioKitUI"), .external(name: "SoundpipeAudioKit"),
    ]) +
    Module.framework(name: "PersistenceKit", dependencies: [
        .external(name: "DeviceKit"), .target(name: "SortEngineKit"), .target(name: "AlgorithmKit"),
    ]) +
    Module.framework(name: "SettingsKit", dependencies: [.target(name: "VisualizationKit")]) +
    Module.framework(name: "DesignSystemKit") +
    Module.framework(name: "MathRenderingKit", dependencies: [.external(name: "SwiftMath")]) +
    Module.framework(name: "SortFeature", dependencies: [
        .target(name: "SortEngineKit"), .target(name: "AlgorithmKit"), .target(name: "VisualizationKit"),
        .target(name: "AudioEngineKit"), .target(name: "SettingsKit"), .target(name: "DesignSystemKit"),
        .target(name: "PersistenceKit"),
    ]) +
    Module.framework(name: "SettingsFeature", dependencies: [
        .target(name: "SettingsKit"), .target(name: "VisualizationKit"),
        .target(name: "AudioEngineKit"), .target(name: "DesignSystemKit"),
    ]) +
    Module.framework(name: "HomeFeature", dependencies: [.target(name: "DesignSystemKit")]) +
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
        .glob(pattern: "App/Resources/**", excluding: ["App/Resources/Algorithms/**", "App/Resources/Shuffles/**"]),
        // Real folder references, not globs — the script loaders (§2.4/§2A.4) look up
        // `Bundle.main.url(forResource:withExtension: nil)` expecting an actual subdirectory,
        // which a glob of loose files wouldn't preserve.
        .folderReference(path: "App/Resources/Algorithms"),
        .folderReference(path: "App/Resources/Shuffles"),
    ],
    entitlements: .file(path: "App/Resources/Sort Symphony.entitlements"),
    dependencies: [
        .target(name: "SortFeature"), .target(name: "SettingsFeature"),
        .target(name: "HomeFeature"), .target(name: "BenchmarkFeature"),
        .target(name: "MathRenderingKit"),
        // Temporary, direct composition-root wiring for Phase 4/5's debug entry point — Phase 9
        // replaces this with data-driven navigation off AlgorithmRegistry/VisualizerRegistry.
        // `BuiltInAlgorithms` is empty again (§2.6 — quicksort is scripted now too) and never
        // referenced directly by the App target; `BuiltInVisualizers` still is (Sort2App wires its
        // concrete Visualizer conformances into VisualizerRegistry, which has no visibility into
        // that module itself).
        .target(name: "BuiltInVisualizers"),
        // Composition-root registry wiring (AlgorithmKit's Algorithm/ShuffleRegistry,
        // ScriptingKit's Script*Loader) needs both directly — neither is re-exported by any of the
        // above.
        .target(name: "AlgorithmKit"), .target(name: "ScriptingKit"),
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
