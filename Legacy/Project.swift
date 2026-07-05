import ProjectDescription

// Helper function to create plugin targets dynamically
func createPluginTarget(name: String, dependencies: [TargetDependency] = []) -> Target {
    let pluginName = "\(name)Plugin"
    return .target(
        name: pluginName,
        destinations: [.iPhone, .iPad],
        product: .framework,
        bundleId: "com.nhubbard.sort-symphony.\(pluginName)",
        sources: ["Plugins/\(pluginName)/**"],
        dependencies: dependencies,
        settings: .settings(configurations: [
            .debug(name: "Debug", xcconfig: "./xcconfigs/\(pluginName).xcconfig"),
            .release(name: "Release", xcconfig: "./xcconfigs/\(pluginName).xcconfig")
        ])
    )
}

func createPluginTestTarget(pluginName: String) -> Target {
    let testTargetName = "\(pluginName)PluginTests"
    return .target(
        name: testTargetName,
        destinations: [.iPhone, .iPad],
        product: .unitTests,
        bundleId: "com.nhubbard.sort-symphony.\(testTargetName)",
        sources: ["Plugin Tests/\(testTargetName)/**"],
        dependencies: [
            .target(name: "\(pluginName)Plugin"),
            .target(name: "SortAlgorithmCore")
        ],
        settings: .settings(configurations: [
            .debug(name: "Debug", xcconfig: "./xcconfigs/\(testTargetName).xcconfig"),
            .release(name: "Release", xcconfig: "./xcconfigs/\(testTargetName).xcconfig")
        ])
    )
}

let project = Project(
    name: "Sort Symphony-Tuist",
    settings: .settings(configurations: [
        .debug(name: "Debug", xcconfig: "./xcconfigs/SortSymphony-Project.xcconfig"),
        .release(name: "Release", xcconfig: "./xcconfigs/SortSymphony-Project.xcconfig")
    ]),
    targets: [
        // Core framework that all plugins depend on
        .target(
            name: "SortAlgorithmCore",
            destinations: [.iPhone, .iPad],
            product: .framework,
            bundleId: "com.nhubbard.sort-symphony.SortAlgorithmCore",
            sources: ["Plugins/SortAlgorithmCore/**"],
            dependencies: [
                .external(name: "CollectionConcurrencyKit")
            ],
            settings: .settings(configurations: [
                .debug(name: "Debug", xcconfig: "./xcconfigs/SortAlgorithmCore.xcconfig"),
                .release(name: "Release", xcconfig: "./xcconfigs/SortAlgorithmCore.xcconfig")
            ])
        ),

        // Plugin targets - using helper function
        createPluginTarget(name: "QuickSort", dependencies: [.target(name: "SortAlgorithmCore")]),
        createPluginTarget(name: "MergeSort", dependencies: [.target(name: "SortAlgorithmCore")]),
        createPluginTarget(name: "HeapSort", dependencies: [.target(name: "SortAlgorithmCore")]),

        // Plugin test targets
        createPluginTestTarget(pluginName: "QuickSort"),
        createPluginTestTarget(pluginName: "MergeSort"),
        createPluginTestTarget(pluginName: "HeapSort"),

        // Main app target
        .target(
            name: "SortSymphony-iOS",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.nhubbard.sort-symphony",
            infoPlist: .file(path: "Sort Symphony--iOS--Info.plist"),
            sources: [
                .glob("Shared/**/*.swift", excluding: ["Shared/IosMathView+UIKit.swift"]),
                "iOS/**"
            ],
            resources: [
                .folderReference(path: "Shared/Assets.xcassets"),
                .folderReference(path: "Shared/Resources"),
                .folderReference(path: "en.lproj"),
                .glob(pattern: "PrivacyInfo.xcprivacy")
            ],
            entitlements: "Sort Symphony (iOS).entitlements",
            dependencies: [
                .target(name: "SortAlgorithmCore"),
                .target(name: "QuickSortPlugin"),
                .target(name: "MergeSortPlugin"),
                .target(name: "HeapSortPlugin"),
                .external(name: "AudioKit"),
                .external(name: "AudioKitEX"),
                .external(name: "AudioKitUI"),
                .external(name: "SoundpipeAudioKit"),
                .external(name: "Controls"),
                .external(name: "DeviceKit"),
                .external(name: "MarkdownUI"),
                .external(name: "NetworkImage"),
                .external(name: "SwiftMath"),
                .external(name: "Then"),
                .external(name: "Algorithms"),
                .external(name: "Atomics")
            ],
            settings: .settings(configurations: [
                .debug(name: "Debug", xcconfig: "./xcconfigs/SortSymphony-iOS.xcconfig"),
                .release(name: "Release", xcconfig: "./xcconfigs/SortSymphony-iOS.xcconfig")
            ])
        )
    ]
)
