// swift-tools-version: 5.10
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        // These default to static products and are each linked from more than one target
        // (MarkdownUI from SortFeature + HomeFeature; NetworkImage transitively via MarkdownUI) —
        // Tuist warns "static product linked from multiple targets, may introduce unwanted side
        // effects" for each. Forcing them dynamic gives every target a single shared copy instead
        // of independently-duplicated static linkage. Both are pure-Swift targets, so this is safe.
        "MarkdownUI": .framework,
        "NetworkImage": .framework
        //
        // cmark-gfm/cmark-gfm-extensions are deliberately NOT overridden here despite triggering
        // the same warning — they're C targets with a module map, and Tuist synthesizes a "Copy
        // Module Map" Run Script phase for dynamic C-target frameworks whose plain `cp` isn't a
        // declared sandboxed output. With ENABLE_USER_SCRIPT_SANDBOXING on, Mac Catalyst builds
        // then fail with "Permission denied" copying module.modulemap, so both stay static.
    ]
)
#endif

let package = Package(
    name: "SortSymphonyDependencies",
    dependencies: [
        .package(url: "https://github.com/devxoul/Then", from: "3.0.0"),
        .package(url: "https://github.com/nhubbard/CollectionConcurrencyKit", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.7.1"),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.4.1")
        // swift-atomics intentionally omitted — operation counting in RecordingEngine is a plain
        // Int now that there's no concurrent writer to protect against.
        // AudioKit/AudioKitUI/AudioKitEX/SoundpipeAudioKit intentionally omitted — the whole audio
        // stack is now Modules/ToneKit, a local target with no external package dependency at all
        // (see its NOTICE.md).
    ]
)
