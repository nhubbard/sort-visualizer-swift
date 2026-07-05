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
    Module.framework(name: "PersistenceKit", dependencies: [.external(name: "DeviceKit")]) +
    Module.framework(name: "SettingsKit") +
    Module.framework(name: "DesignSystemKit") +
    Module.framework(name: "MathRenderingKit", dependencies: [.external(name: "SwiftMath")]) +
    Module.framework(name: "SortFeature", dependencies: [
        .target(name: "SortEngineKit"), .target(name: "AlgorithmKit"), .target(name: "VisualizationKit"),
        .target(name: "AudioEngineKit"), .target(name: "SettingsKit"), .target(name: "DesignSystemKit"),
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
    resources: ["App/Resources/**"],
    entitlements: .file(path: "App/Resources/Sort Symphony.entitlements"),
    dependencies: [
        .target(name: "SortFeature"), .target(name: "SettingsFeature"),
        .target(name: "HomeFeature"), .target(name: "BenchmarkFeature"),
        .target(name: "MathRenderingKit"),
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

let project = Project(
    name: "Sort Symphony",
    targets: modules + [app]
)
