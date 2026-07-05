// swift-tools-version: 5.10
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "AudioKit": .framework,
        "AudioKitUI": .framework,
        "SoundpipeAudioKit": .framework,
        // Soundpipe is an internal C target (not an SPM product) that SoundpipeAudioKit and
        // CSoundpipeAudioKit both link — as a Tuist-synthesized framework it gets a "Copy Module
        // Map" script phase that races against its own module-readiness gate under Xcode's new
        // build system ("Cycle inside Soundpipe"). It has no Swift-facing API of its own (only
        // consumed via C interop from CSoundpipeAudioKit), so it doesn't need a Clang module at
        // all — building it as a static library instead removes the module map phase entirely.
        "Soundpipe": .staticLibrary,
    ]
)
#endif

let package = Package(
    name: "SortSymphonyDependencies",
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit.git", branch: "main"),
        .package(url: "https://github.com/AudioKit/AudioKitUI.git", branch: "main"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit.git", branch: "main"),
        .package(url: "https://github.com/devxoul/Then", from: "3.0.0"),
        .package(url: "https://github.com/nhubbard/CollectionConcurrencyKit", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.6.0"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.7.1"),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.4.1"),
        // swift-atomics intentionally omitted — §5.3: operation counting in RecordingEngine is a
        // plain Int now that there's no concurrent writer to protect against. Re-add only if a
        // real need for ManagedAtomic shows up later.
        // AudioKitEX intentionally omitted, per the already-landed
        // "fix(audio): Replace AudioKitEX dependency" commit (AudioKit/AudioKitEX#33).
    ]
)
