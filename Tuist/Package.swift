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
        // These default to static products and are each linked from more than one target
        // (MarkdownUI from SortFeature + HomeFeature; NetworkImage transitively via MarkdownUI) —
        // Tuist warns "static product linked from multiple targets, may introduce unwanted side
        // effects" for each. Forcing them dynamic gives every target a single shared copy instead
        // of independently-duplicated static linkage. Both are pure-Swift targets, so this is safe.
        "MarkdownUI": .framework,
        "NetworkImage": .framework,
        //
        // AudioKitEX/CAudioKitEX/cmark-gfm/cmark-gfm-extensions are deliberately NOT overridden
        // here despite triggering the same warning — they're all C/C++ targets with a module map,
        // and forcing a C/C++-with-modulemap target to build as a dynamic framework breaks in two
        // different ways under this project's other new settings:
        //  - AudioKitEX/CAudioKitEX: their C++ classes (DSPBase et al.) aren't annotated for dynamic
        //    export, so the default framework visibility hides them and CSoundpipeAudioKit's link
        //    fails ("Undefined symbols ... DSPBase").
        //  - cmark-gfm/cmark-gfm-extensions: Tuist synthesizes a "Copy Module Map" Run Script phase
        //    for dynamic C-target frameworks (see Soundpipe's note above for the same pattern), and
        //    that script's plain `cp` isn't declared as a sandboxed output — with
        //    ENABLE_USER_SCRIPT_SANDBOXING on, Mac Catalyst builds fail with "Permission denied"
        //    copying module.modulemap.
        // Leaving all four static keeps the build working on every destination; the multiple-targets
        // warning for these four is an accepted tradeoff (see Project.swift generation notes).
    ]
)
#endif

let package = Package(
    name: "SortSymphonyDependencies",
    dependencies: [
        // Pinned to stable tagged releases, not branch: "main" — Phase 8 discovered that HEAD of
        // AudioKit/SoundpipeAudioKit's main branch crashes at Oscillator() construction
        // ("akGetParameterAddress: Fatal error: parameter map not initialized"), while AudioKitEX
        // (already pinned to the tagged 5.7.0 below) expects the parameter-registration contract
        // a stable, matching-vintage AudioKit/SoundpipeAudioKit release actually provides.
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.7.0"),
        .package(url: "https://github.com/AudioKit/AudioKitUI.git", from: "0.3.0"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit.git", from: "5.7.0"),
        .package(url: "https://github.com/devxoul/Then", from: "3.0.0"),
        .package(url: "https://github.com/nhubbard/CollectionConcurrencyKit", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.7.1"),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.4.1"),
        // swift-atomics intentionally omitted — §5.3: operation counting in RecordingEngine is a
        // plain Int now that there's no concurrent writer to protect against. Re-add only if a
        // real need for ManagedAtomic shows up later.
        // AudioKitEX intentionally omitted, per the already-landed
        // "fix(audio): Replace AudioKitEX dependency" commit (AudioKit/AudioKitEX#33).
    ]
)
