# Sort Symphony v2 — Implementation Plan

This is the "how to actually write it, in what order" companion to `ARCHITECTURE_V2.md`. That
document is the target design (the tape architecture, the marker model, the scripting system, the
visualization plugin layer, the module graph, the resolved decisions). This document turns it into
an ordered sequence of phases, each one independently buildable and testable, starting from a real
Tuist project on day one rather than bolting Tuist on at the end.

Read `ARCHITECTURE_V2.md` first — this document assumes its types (`SortOperation`, `Marker`,
`RecordingEngine`, `ReplayEngine`, `SortAlgorithm`, `Visualizer`, `SortSession`, etc.) and just
says when to build each one and what to check before moving on. Section references below (§1, §2A,
etc.) point back into that document.

## Ground rules for every phase

- **This is a rewrite, not a side-by-side migration.** Phase 0 creates a new branch and moves every
  existing file into a `Legacy/` folder before a single new Tuist file is written (§0.1–§0.2) — the
  repository root belongs to Tuist alone from that point on. `Legacy/` stays fully intact and
  buildable throughout (open `Legacy/Sort Symphony.xcodeproj` directly whenever you want to compare
  v1 behavior side-by-side), but it is reference material, not a second thing you maintain — nothing
  in later phases needs to delete files out of it piecemeal (see the note in Phase 8/9), and Phase 11
  removes the whole folder at once.
- **Tuist regenerates cleanly at the end of every phase.** `tuist generate` (or `tuist build`) is
  the acceptance bar, not "the code compiles inside a hand-edited `.xcodeproj`." The graph in §5/§6
  of `ARCHITECTURE_V2.md` exists in skeleton form from Phase 0 — later phases fill modules in, they
  never restructure the graph.
- **Commit at the end of every phase — including Phase 0's own two sub-steps.** A phase isn't done
  until its commit lands: this is what makes `git log`/`git bisect` a meaningful record of the
  rewrite, and it means a phase that goes sideways can be rolled back with `git reset`/`git revert`
  without losing everything after it. Each phase section below ends with the commit(s) to make;
  don't batch multiple phases into one commit even if they land in the same sitting.
- **Tests are part of the phase, not a follow-up.** A phase isn't "done" until its own checkpoint
  passes — most phases end with a `swift test`/`tuist test` run, not just "it builds."
- **Scripted-by-default (§2.6) applies from the first algorithm you port**, not after some native
  bootstrapping period — Phase 2 deliberately does one native proof-of-concept algorithm to validate
  the *engine*, then Phase 3 immediately proves the *scripting* path before you invest in porting
  anything else, so you're not tempted to keep writing native Swift out of momentum.

---

## Phase 0 — New branch, archive v1, and Tuist bootstrap

**Goal:** a fresh, real Tuist project — every module from §5.2/§6 exists as a target with the right
dependency edges, the app target boots to a blank screen, entitlements/CloudKit/bundle ID/deployment
target all match the current shipping app exactly. Nothing has real logic yet. This directly
satisfies "make sure it's powered by Tuist so we can keep a clean Xcode structure from the outset" —
everything after this phase is additive within a structure that's already correct. This phase has
three sub-steps and, per the ground rules, its own two commits (§0.1+§0.2 together, then §0.3).

### 0.1 New branch

```
git checkout -b v2-rewrite
```

Branching off `dev` (the current branch) — adjust the base/name if you'd rather cut it from `main`.
Everything from here through Phase 11 happens on this branch; nothing lands on `dev`/`main` until
the rewrite is actually in a shippable state.

### 0.2 Archive everything that currently exists

Move every existing top-level item into `Legacy/`, via `git mv` (never a plain `mv` + re-add — that
throws away rename tracking and makes the archive step look like a mass delete-and-recreate in
`git log` instead of what it actually is, a move). Leave only the design docs and repo-level
dotfiles at the root:

```
mkdir Legacy
git mv "Sort Symphony.xcodeproj" Legacy/
git mv "Sort Symphony (iOS).entitlements" Legacy/
git mv Shared Legacy/
git mv macOS Legacy/                                   # the vestigial AppKit file, ARCHITECTURE_V2.md §9
git mv Plugins Legacy/                                 # abandoned one-framework-per-algorithm WIP
git mv RawResources Legacy/
git mv xcconfigs Legacy/
git mv Project.swift Legacy/
git mv Tuist.swift Legacy/
git mv Tuist Legacy/
git mv "Sort Symphony-Tuist.xcodeproj" Legacy/
git mv "Sort Symphony-Tuist.xcworkspace" Legacy/
```

Run `git ls-files` first and treat the list above as illustrative, not authoritative — the rule is
"everything except `ARCHITECTURE_V2.md`, `IMPLEMENTATION_PLAN.md`, `README.md`, `LICENSE`, and repo
dotfiles (`.gitignore`, `.git/`) ends up under `Legacy/`," not "exactly these paths." Build artifacts
and IDE/tooling state that shouldn't be tracked at all (`Derived/`, `.idea/`) belong in `.gitignore`,
not `Legacy/` — this is a good moment to add that if it isn't already there.

Note what this replaces from an earlier draft of this plan: the abandoned WIP Tuist scaffolding
(`Plugins/`, `RawResources/quicksort/QuickSortPlugin/`, `xcconfigs/*Plugin*.xcconfig`, the old
`Project.swift`/`Tuist.swift`/`Tuist/`, `Sort Symphony-Tuist.xcodeproj`/`.xcworkspace`) was previously
slated for outright deletion right here. Now it simply rides along into `Legacy/` with everything
else — it's inert there (nothing in the new Tuist graph below references it) and disappears for good
in Phase 11 when the whole `Legacy/` folder goes away. No reason to special-case deleting it earlier.

**Commit:**
```
git add -A
git commit -m "Archive v1 source under Legacy/ ahead of the v2 Tuist rewrite"
```

Every later phase's "port from"/"reference" paths mean `Legacy/<path>` from here on — e.g. Phase 2
ports from `Legacy/Shared/Data/Implementations/**`, Phase 8 references `Legacy/Shared/Data/Primary/SortViewModel.swift`.
That renaming is already reflected in the phases below.

### 0.3 Tuist bootstrap (the whole module graph, empty)

### Files to create

```
Tuist.swift
Tuist/Package.swift
Tuist/ProjectDescriptionHelpers/Module.swift
Project.swift
Modules/SortEngineKit/{Sources,Tests}/.gitkeep
Modules/AlgorithmKit/{Sources,Tests}/.gitkeep
Modules/VisualizationKit/{Sources,Tests}/.gitkeep
Modules/ScriptingKit/{Sources,Tests}/.gitkeep
Modules/BuiltInAlgorithms/{Sources,Tests}/.gitkeep
Modules/BuiltInVisualizers/{Sources,Tests}/.gitkeep
Modules/AudioEngineKit/{Sources,Tests}/.gitkeep
Modules/PersistenceKit/{Sources,Tests}/.gitkeep
Modules/SettingsKit/{Sources,Tests}/.gitkeep
Modules/DesignSystemKit/{Sources,Tests}/.gitkeep
Modules/MathRenderingKit/{Sources,Tests}/.gitkeep
Modules/SortFeature/{Sources,Tests}/.gitkeep
Modules/SettingsFeature/{Sources,Tests}/.gitkeep
Modules/HomeFeature/{Sources,Tests}/.gitkeep
Modules/BenchmarkFeature/{Sources,Tests}/.gitkeep
App/Sources/Sort2App.swift            // minimal: WindowGroup { Text("Sort Symphony v2") }
App/Sources/ContentView.swift         // placeholder, replaced for real in Phase 9
App/Resources/Sort Symphony.entitlements
App/Resources/Info.plist              // only the keys not already covered by Tuist's generated Info.plist
```

### `Tuist.swift`

```swift
import ProjectDescription

let tuist = Tuist()
```

Nothing project-specific belongs here in current Tuist versions — organization/handle config if you
later adopt Tuist's remote cache/registry, otherwise this file can stay this small indefinitely.

### `Tuist/Package.swift` — pinning the real SPM graph

Grounded in the actual `repositoryURL`s from `Legacy/Sort Symphony.xcodeproj/project.pbxproj`, with one
deliberate removal: **`AudioKitEX` is dropped**, matching the already-landed
`fix(audio): Replace AudioKitEX dependency` commit — do not re-add it.

```swift
// swift-tools-version: 5.10
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "AudioKit": .framework,
        "AudioKitUI": .framework,
        "SoundpipeAudioKit": .framework,
    ]
)
#endif

let package = Package(
    name: "SortSymphonyDependencies",
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/AudioKitUI.git", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit.git", from: "5.6.0"),
        .package(url: "https://github.com/devxoul/then", from: "6.0.0"),
        .package(url: "https://github.com/nhubbard/CollectionConcurrencyKit", branch: "main"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.0.0"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", from: "1.0.0"),
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.3.0"),
        // swift-atomics intentionally omitted — §5.3: operation counting in RecordingEngine is a
        // plain Int now that there's no concurrent writer to protect against. Re-add only if a
        // real need for ManagedAtomic shows up later.
    ]
)
```

Pin actual version numbers to whatever `Package.resolved` in the current project already has —
the numbers above are placeholders for "a recent 5.x/1.x/2.x release," not verified pins.

### `Tuist/ProjectDescriptionHelpers/Module.swift` — the one helper that replaces 32 xcconfigs

```swift
import ProjectDescription

public enum Module {
    public static let deploymentTargets: DeploymentTargets = .iOS("26.0")
    public static let destinations: Destinations = [.iPhone, .iPad, .macCatalyst]

    /// A framework + its test target, sharing one bundle-ID/settings convention. This is the
    /// entire replacement for the current per-target `xcconfigs/*.xcconfig` files (§5.3).
    public static func framework(
        name: String,
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil
    ) -> [Target] {
        [
            .target(
                name: name,
                destinations: destinations,
                product: .framework,
                bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased())",
                deploymentTargets: deploymentTargets,
                sources: ["Modules/\(name)/Sources/**"],
                resources: resources,
                dependencies: dependencies,
                settings: .settings(base: baseSettings)
            ),
            .target(
                name: "\(name)Tests",
                destinations: destinations,
                product: .unitTests,
                bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased()).tests",
                deploymentTargets: deploymentTargets,
                sources: ["Modules/\(name)/Tests/**"],
                dependencies: [.target(name: name)],
                settings: .settings(base: baseSettings)
            ),
        ]
    }

    static let baseSettings: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
    ]
}
```

### `Project.swift` — assembling the graph

Every module is one line; the app target carries the real bundle ID, entitlements, and Info.plist
keys read off `Legacy/Sort Symphony.xcodeproj` (moved there in §0.2).

```swift
import ProjectDescription

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
        "UISupportedInterfaceOrientations~iphone": [
            "UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight",
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
    ])
)

let project = Project(
    name: "Sort Symphony",
    targets: modules + [app]
)
```

### `App/Resources/Sort Symphony.entitlements`

Copied verbatim from `Legacy/Sort Symphony (iOS).entitlements` (moved there in §0.2) — CloudKit
retention (§9) means this doesn't change at all, just moves location:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>production</string>
    <key>com.apple.developer.aps-environment</key>
    <string>production</string>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.nhubbard.Sort2.mobile</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

### Checkpoint

```
tuist install   # resolves Tuist/Package.swift
tuist generate  # produces Sort Symphony.xcworkspace with every module target, zero errors
tuist build     # empty app builds and runs, showing the placeholder ContentView
tuist test      # 16 empty-but-valid test targets report "0 tests, 0 failures" — proves the graph is wired, not broken
```

Once this passes, every subsequent phase is "add files under `Modules/<X>/Sources`," never "touch
`Project.swift`'s structure" — new algorithms/visualizations/shuffles (the actual point of the
scripting system) never require a project edit at all, only new modules do, and you're done adding
modules after this phase.

**Commit:**
```
git add -A
git commit -m "Bootstrap Tuist v2 project skeleton: empty module graph, app target"
```

---

## Phase 1 — `SortEngineKit`: the tape, for real

**Goal:** `SortOperation`, `Marker`, `AuxHandle`, `TapeHeader`, `Tape`, `RecordingEngine`,
`ReplayEngine` (§1.1, §1.2, §1.4) exist, are unit-tested, and are used by nothing else yet.

**Files:** `Modules/SortEngineKit/Sources/{SortOperation,Marker,Tape,RecordingEngine,ReplayEngine,SortValue,SortGate}.swift`,
mirrored `Modules/SortEngineKit/Tests/*Tests.swift`.

**How to write it:** transcribe §1.1/§1.2/§1.4 directly — these sections are already
implementation-ready Swift, not just sketches. The one piece of real design work in this phase is
`ReplayEngine`'s checkpoint ladder (`private let checkpoints: [(step: Int, frame: [BarState])]`):
build it by replaying the full tape once at `init` time, snapshotting `frame`/`auxArrays` every
~500 operations, so `seek(to:)` never replays more than ~500 ops from the nearest checkpoint.

**Tests:**
- `RecordingEngine`: `compare`/`swap` produce the expected `Marker.primary`/`.secondary` mark
  operations in order; `createAuxArray`/`writeAux`/`deleteAuxArray` round-trip correctly;
  `finish()`'s counts match a hand-computed expectation for a fixed sequence of calls.
- `ReplayEngine`: build a tape from a **hand-written** `[SortOperation]` fixture (no algorithm
  involved yet), assert `stepForward()` N times produces the expected `frame`, assert
  `seek(to:)` then continuing to step matches uninterrupted stepping to the same index, assert
  `stepBackward()` from various points matches re-deriving from scratch.

**Checkpoint:** `tuist test` — `SortEngineKitTests` all green. Nothing user-visible yet; that's
expected and correct for this phase.

**Commit:**
```
git add -A
git commit -m "Phase 1: SortEngineKit — tape, RecordingEngine, ReplayEngine, unit tests"
```

---

## Phase 2 — `AlgorithmKit` + one native algorithm, proving the tape idea

**Goal:** `SortAlgorithm`/`AlgorithmID`/`AlgorithmMetadata`/`AlgorithmRegistry` (§1.3, §2.4) exist;
**Quick Sort only**, ported natively, proves recording actually produces a correct, replayable tape
before you touch JavaScriptCore at all.

**Files:** `Modules/AlgorithmKit/Sources/{SortAlgorithm,AlgorithmMetadata,AlgorithmRegistry}.swift`;
temporarily, `Modules/BuiltInAlgorithms/Sources/QuickSort.swift` (this native copy is deleted in
Phase 3 once the scripted-by-default policy, §2.6, takes over — it's scaffolding, not a keeper).

**How to write it:** `AlgorithmRegistry.discover()` for now just does `algorithms = builtIns` (the
script-loading half comes in Phase 3). Port Quick Sort from `Legacy/Shared/Data/Implementations/**`
by replacing every `await`/`enforceRunning()`/`playNote`/`changeColor` call with the matching
`RecordingEngine` call (`engine.compare(i, j)`, `engine.swap(i, j)`) and deleting everything else —
audio, delay, and color are no longer the algorithm's problem.

**Validate visually, not just with a unit test** — this is the phase where you should actually look
at bars moving, even with throwaway plumbing: write a tiny SwiftUI preview or scratch view that
records a tape via `QuickSort().record(into:)`, feeds it straight into `ReplayEngine`, and renders
`frame` as plain `Rectangle()`s (not the real `VisualizationCanvas` — that's Phase 4). The goal is
building confidence that record-then-replay actually looks like sorting before more machinery goes
on top of it.

**Checkpoint:** unit test asserts `RecordingEngine(values: input)` run through Quick Sort produces
`values == input.sorted()`; the scratch preview visibly animates a correct sort.

**Commit:**
```
git add -A
git commit -m "Phase 2: AlgorithmKit + native Quick Sort proof of concept"
```

---

## Phase 3 — `ScriptingKit`: prove the JS path before porting anything else

> **`ScriptingKit` has since been removed.** It bound a private JavaScriptCore symbol
> (`JSContextGroupSetExecutionTimeLimit`) that App Store validation flagged and blocked TestFlight
> submission over; by then everything it loaded had already been ported to native Swift, so the
> whole module was deleted rather than reworked. This phase is kept as historical record.

**Goal:** `JSRecordingEngineBridge`/`JSAlgorithmAdapter`/manifest decoding/execution-time watchdog
(§2.2, §2.3) exist; **Bubble Sort**, authored as `.js` + manifest, produces a tape and is verified
against a hand-written native reference. This is the phase that proves "everything is scripted"
(§2.6) is actually viable — do it early, before you've sunk effort into porting 15 more algorithms
natively out of habit.

**Files:**
`Modules/ScriptingKit/Sources/{JSRecordingEngineBridge,JSAlgorithmAdapter,AlgorithmManifest,ExecutionTimeLimit}.swift`,
`App/Resources/Algorithms/bubblesort.js`, `App/Resources/Algorithms/bubblesort.manifest.json`
(bundled resources — the exact §2.3 example, adapted to Bubble Sort's logic).

**How to write it:** transcribe §2.2's bridge verbatim. `installExecutionTimeLimit(on:seconds:)`
uses `JSContextGroupSetExecutionTimeLimit` via the context's `jsGlobalContextRef` — this is a C API
call, so it needs a small bridging header or an `@_silgen_name`-free wrapper; keep it isolated in
one file (`ExecutionTimeLimit.swift`) since it's the one place in the module touching C interop.
`AlgorithmRegistry.discover()` (Phase 2's registry) now also calls `loadScripts(from:)` against
`Bundle.main.url(forResource: "Algorithms", ...)`.

**Tests:**
- Keep a native `BubbleSortReference` **test-only** fixture (per §7's guidance — never shipped in
  `BuiltInAlgorithms`) and assert the JS-authored `bubblesort.js`, run through `JSAlgorithmAdapter`,
  produces an identical operation sequence for the same input. This is the standing bridge-parity
  check.
- A deliberately infinite-looping malformed script asserts the watchdog fires and surfaces a
  `.failed` state rather than hanging the test run.
- A manifest with a duplicate `id`/missing field asserts `AlgorithmRegistry.discover()` skips it and
  logs, rather than crashing.

**Checkpoint:** `tuist test` green, including the parity/timeout/malformed-manifest tests. At this
point you have both halves of the algorithm plugin system proven independently — everything from
here on is "write more scripts," not "build more infrastructure."

**Commit:**
```
git add -A
git commit -m "Phase 3: ScriptingKit — JS algorithm bridge, Bubble Sort as first scripted algorithm"
```

---

## Phase 4 — `VisualizationKit` + one native visualizer, wiring the first real screen

**Goal:** `Visualizer`/`DrawCommand`/`VisualizationContext`/`VisualizerRegistry` (§2A.2) exist; a
native `BarGraphVisualizer` (the direct port of the app's current, only-ever style) renders via a
real `Canvas`; `SortSession`/`SortView`/`VisualizationCanvas` (§3.5, §4.2) get built and wired to
**one** real screen (Quick Sort's) end-to-end — recording, replay, and drawing all connected for
the first time, side by side with the untouched v1 app.

**Files:** `Modules/VisualizationKit/Sources/{Visualizer,DrawCommand,VisualizationContext,VisualizerRegistry,RGBAColor}.swift`;
`Modules/BuiltInVisualizers/Sources/BarGraphVisualizer.swift` — **not** scaffolding this time:
visualizations are native-only for good (§2A.3), so this file is the first of many permanent
`BuiltInVisualizers` conformances, unlike Phase 2's throwaway native Quick Sort;
`Modules/SortFeature/Sources/{SortSession,SortView,VisualizationCanvas,ScrollingSortView}.swift`;
`Modules/SettingsKit/Sources/AppSettings.swift` (just enough of it — `selectedVisualizerID`,
`playbackSpeed` — to unblock this phase; the rest of §3.3 lands in Phase 8).

**How to write it:** `BarGraphVisualizer.draw(_:)` is the simplest possible `Visualizer` — for each
`(index, value)` in `context.values`, emit one `.rect(...)` sized by `value`/`context.valueRange`,
colored via `context.markers[index]` (empty = default color, contains `Marker.primary`/`.secondary`
= highlighted). `VisualizationCanvas` (§4.2's sketch) is close to copy-paste ready. Build
`SortSession.start(values:)` exactly as in §3.5, but with `audio`/`analytics` as no-op stub
conformances for now (`AudioEngineKit`/`PersistenceKit` real implementations are Phase 8) — the
point of this phase is proving record → replay → draw, not the full service graph.

**Validate in the actual app now**, not a scratch preview: wire exactly one entry point (a debug
menu item or a temporary extra tab) to `ScrollingSortView(algorithm: QuickSort())`, run it on
device/simulator, confirm bars animate, step/scrub work if you choose to enable them this early
(§1.4 makes them nearly free, but they're not required until Phase 12).

**Checkpoint:** the new stack visibly sorts an array end-to-end for Quick Sort, next to the
still-fully-functional (if you want to check) `Legacy/Sort Symphony.xcodeproj` app. This is the
"does the whole idea actually work" milestone — everything after this phase is filling in breadth
(more algorithms, more visualizers, more services), not proving new architecture.

**Commit:**
```
git add -A
git commit -m "Phase 4: VisualizationKit + BarGraphVisualizer, first end-to-end SortSession screen"
```

---

## Phase 5 — A second and third `Visualizer`, proving the axis is genuinely orthogonal

**Goal:** no new infrastructure this phase — `VisualizationKit`/`BuiltInVisualizers` are already
real as of Phase 4 (visualizations were never going to get a JS bridge, §2A.3: a scripted-drawing
layer would mean either reimplementing `GraphicsContext` for scripts to target or building some
dynamic-dispatch scene-graph over SwiftUI, for a plugin surface simple enough that plain Swift is
already about as easy to author as a script). Instead, this phase's job is proving `Visualizer` is
a genuinely swappable axis, independent of `SortSession`/`ReplayEngine`, by adding **two more**
native conformances with meaningfully different layouts: `RainbowVisualizer` (trivial — same bar
layout as Phase 4, color purely from value via `RGBAColor.hueRamp`) and `ScatterPlotVisualizer`
(a real layout change — one dot per column at its value's height, proving the abstraction isn't
secretly bar-shaped). `AppSettings.selectedVisualizerID` becomes user-changeable mid-run in
`SettingsView`.

**Files:** `Modules/BuiltInVisualizers/Sources/{RainbowVisualizer,ScatterPlotVisualizer}.swift`,
`Modules/SettingsFeature/Sources/SettingsView.swift` (add the visualizer picker).

**How to write it:** each is a small, pure `draw(_:)` — no manifest, no registry-discovery step, no
watchdog, because there's no interpreter in this path at all (§2A.3). Adding either file needs zero
`Project.swift` edit, since `Modules/BuiltInVisualizers/Sources/**` is already glob-matched by
Phase 0's `Module.framework` helper — only a recompile, which for a project this size is seconds.

**Tests:** plain unit tests per conformance (§7) — feed each a hand-built `VisualizationContext`,
assert the expected `[DrawCommand]` sequence. No timeout/parity tests are needed here, unlike the
algorithm-scripting phases — there's no bridge to have a boundary condition in.

**Checkpoint:** switching the visualizer picker mid-sort in the running app changes the rendering
live, with zero changes to `SortSession`/`ReplayEngine` — this is the proof that the two plugin axes
(algorithms, visualizations) are genuinely orthogonal, even though only one of them is scripted.

**Commit:**
```
git add -A
git commit -m "Phase 5: Rainbow and ScatterPlot visualizers, mid-run visualizer switching"
```

---

## Phase 6 — Shuffles become tapes

**Goal:** `ShuffleAlgorithm` (§2A.4) exists; the app's current shuffle methods move from a plain
function to scripted tapes, concatenated with the sort's own tape into one continuous `Tape`.

**Files:** `Modules/AlgorithmKit/Sources/{ShuffleAlgorithm,ShuffleRegistry}.swift`,
`Modules/SortEngineKit/Sources/Tape.swift` (add `shuffleID: String?` to `TapeHeader`),
`App/Resources/Shuffles/{random,reverse,...}.js` + manifests for whatever shuffle set
`Legacy/Shared`'s current `ShuffleMethod` already ships, ported first — new ArrayV shuffles come in
Phase 7.

**How to write it:** `SortSession.start(values:)` changes to: record the selected shuffle against
`Array(0..<n)`, record the sort against the shuffle's output, concatenate `[SortOperation]` arrays,
build one `Tape` whose `header.shuffleID` is the shuffle's ID and whose `header.initialValues` is
the *pre-shuffle* identity array — `ReplayEngine` doesn't change at all, it's still just replaying
one array of operations.

**Tests:** a concatenated tape's operation count equals shuffle-tape-length + sort-tape-length
exactly; replaying it end-to-end produces a sorted final `frame` regardless of which shuffle was
used (i.e., shuffling never leaves the array in a state a sort can't handle).

**Checkpoint:** watching a shuffle happen before the sort starts is a real, visible feature for the
first time — previously the app "shuffled" outside of any recorded/visualized path.

**Commit:**
```
git add -A
git commit -m "Phase 6: ShuffleAlgorithm — shuffles as tapes, concatenated shuffle+sort recording"
```

---

## Phase 7 — Porting ArrayV content at scale

**Goal:** work through §2A.6's category-by-category plan, porting as many of ArrayV's ~189
algorithms and ~35 shuffles as practical as scripts (§2.6), and as many of its 15 visualization
styles as practical as native `BuiltInVisualizers` conformances (§2A.3 — no scripting for these).

**How to write it — this phase is a repeatable loop, not a list of one-off tasks:**
1. Pick a batch (e.g. one ArrayV source directory: `exchange/`, then `insert/`, then `select/`, ...).
2. For each algorithm: read the Java `runSort` body, mechanically translate
   `Reads.compareValues`/`compareIndices` → `engine.compare`, `Writes.swap`/`write` →
   `engine.swap`/`setValue`, `Highlights.markArray`/`clearMark` → `engine.mark`/`unmark`,
   `Writes.createExternalArray` → `engine.createAuxArray`. Write the manifest from the Java class's
   `@SortMeta`/`setCategory`/`setUnreasonableLimit` calls.
3. Run the parameterized test suite (§2.5) against the new script immediately — sortedness is a
   30-second feedback loop per algorithm, so don't batch 20 scripts before testing any of them.
4. For visualizations: same loop against `VisualizationContext`, one ArrayV `Visual` subclass at a
   time; flag anything needing `originalIndices` (disparity family) or deferred entirely
   (CustomImage, per §2A.6).
5. For `concurrent/` algorithms specifically: stop and decide per-algorithm whether a sequential
   simulation is faithful enough, or whether it belongs in `BuiltInAlgorithms` as a native escape
   hatch (§2.6) — don't force a bad sequential port just to keep the "everything scripted" streak.

**No silent caps:** if a particular algorithm or style is skipped (too obscure, needs the
not-yet-designed teaching-mode annotations, etc.), keep a running list in this phase's tracking
(a checklist file, an issue, whatever you use) rather than letting "ported everything" quietly mean
"ported most things." This phase can run for a long time and land incrementally — it's the one
phase in this plan with no fixed exit condition beyond "you're satisfied with coverage."

**Checkpoint:** growing `algorithms.count`/`visualizers.count`/`shuffles.count` in the registries,
each new arrival passing its own test with zero project/Tuist changes — the actual payoff of
§2/§2A's entire design.

**Commit:** this phase is the one exception to "one commit per phase" — it has no fixed exit
condition, so commit **per batch** instead (one commit per ArrayV source directory or similar-sized
chunk), each passing its own tests before landing:
```
git add -A
git commit -m "Phase 7: port ArrayV exchange/ algorithms (Bubble, Cocktail, Comb, ...)"
```
A long, incrementally-committed sequence like this is the expected shape for this phase — resist the
urge to squash it into one commit at the end; the per-batch history is useful if a later batch's
translation turns out to have a mistake worth bisecting to.

---

## Phase 8 — Service decomposition, replacing `SortViewModel`

**Goal:** `AudioService`, `AnalyticsService` (with real CloudKit sync), the rest of `AppSettings`
replace their stub/partial versions from Phase 4; `SortSession` (§3.5) is wired to the real
services.

**Deviation from §3.1–§3.5 as drafted:** `SortGate`/`AlgorithmWarning`/
`AlgorithmMetadata.confirmationWarning` (§3.4) were removed rather than finished — see the "resolved
decisions" bullet added to §9 during this phase. `AnalyticsService`'s CloudKit sync also uses plain
SwiftData (`ModelConfiguration(cloudKitDatabase: .automatic)`), not `NSPersistentCloudKitContainer`
— §3.2 as drafted undersold how directly SwiftData handles this itself.

**Files:** `Modules/AudioEngineKit/Sources/AudioService.swift` (move `Legacy/Shared/.../Synthesizer.swift`'s
body over, rename, add the `AudioPlaying` protocol), `Modules/PersistenceKit/Sources/{RunSummary,AnalyticsService,DeviceInfoProvider}.swift`
(pure-SwiftData model + sync against the existing `iCloud.com.nhubbard.Sort2.mobile` container — §9
confirms retention specifically for cross-device comparison), `Modules/SettingsKit/Sources/AppSettings.swift`
(fill in the rest: `soundEnabled`, `synthNoteRange`, `defaultArraySize`, `codeTheme` — no Bogo/Bitonic
warning toggles, per the §9 deviation above).

**How to write it:** §3.1–§3.3/§3.5 are implementation-ready (§3.4 is not — see the deviation note).
The one sequencing detail worth calling out: wire `AnalyticsService.record(...)` to fire from
`SortSession`'s `.complete` transition, and verify with a real device (or two, if you have them)
that `RunSummary` rows actually sync through CloudKit before considering this phase done —
`Legacy/`'s `CloudKitRecordEncoder` is reference material at this point (§0.2), not something you
need to touch or migrate data out of.

**No mid-stream deletion needed:** unlike an earlier draft of this plan, there's nothing to delete
here — `Legacy/Shared/Data/Primary/SortViewModel.swift` and the `*Impl.swift` files were already cut
out of the live build in Phase 0 (§0.2). They simply stop being relevant reference material once
`SortSession` covers everything; removing the bytes themselves happens once, in Phase 11.

**Checkpoint:** the app fully works end-to-end — every algorithm runs through `SortSession`, with
real audio and real CloudKit-synced analytics.

**Commit:**
```
git add -A
git commit -m "Phase 8: AudioService, AnalyticsService (CloudKit), AppSettings"
```

---

## Phase 9 — SwiftUI feature migration and data-driven navigation

**Goal:** `ContentView` (§4.4) becomes fully data-driven off `AlgorithmRegistry`; `Page.swift`'s five
parallel switches are deleted; `SettingsFeature`/`HomeFeature`/`BenchmarkFeature` get their real
views.

**Files:** `App/Sources/ContentView.swift` (replace the placeholder from Phase 0 with §4.4's
version), `Modules/SettingsFeature/Sources/SettingsView.swift`, `Modules/HomeFeature/Sources/HomeView.swift`.

**How to write it:** §4.1–§4.4 are implementation-ready as-is — `@Environment(AppSettings.self)`/
`@Environment(AudioService.self)` injected once at `Sort2App`'s root via `.environment(...)`,
`@State private var session: SortSession` per detail view, `@Bindable` only where two-way bindings
are needed. `Legacy/Shared/Views/Main/Page.swift` and its `Algorithms` enum (§0.2) are your reference
for what the five parallel switches used to look like — build `ContentView` against
`AlgorithmRegistry.shared.algorithms(in:)` directly rather than porting them.

**Checkpoint:** adding a **new** algorithm from this point on is "drop a `.js` + manifest pair in
`Algorithms/`" and nothing else — no Xcode/Tuist change, no `ContentView` edit. Verify this claim
directly: add one throwaway test algorithm, confirm it appears in the sidebar with zero other
changes, then remove it.

**Commit:**
```
git add -A
git commit -m "Phase 9: data-driven ContentView, SettingsFeature/HomeFeature real views"
```

---

## Phase 10 — Persistence finalization and `BenchmarkFeature`

**Goal:** the cross-device comparison view that motivated keeping CloudKit (§9) becomes real; the
Swift Charts complexity view (a standing `TODO.md` item) ships.

**Files:** `Modules/BenchmarkFeature/Sources/{BenchmarkView,ComplexityChart,DeviceComparisonView}.swift`.

**How to write it:** batch-record each algorithm N times per array size, off-screen (`RecordingEngine`
only, never `ReplayEngine` — no UI/audio cost per §1's `recordingDuration` design), plot
`header.recordingDuration`/`compareCount` against size with Swift Charts. `DeviceComparisonView`
queries `AnalyticsService`'s CloudKit-synced `RunSummary` rows grouped by `DeviceInfo`, presenting
exactly the "how does the same algorithm run on different Apple devices" view that was the original
reason for keeping CloudKit at all.

**Checkpoint:** run the same algorithm on two different devices signed into the same iCloud account,
confirm both runs show up in `DeviceComparisonView`.

**Commit:**
```
git add -A
git commit -m "Phase 10: BenchmarkFeature — complexity charts, cross-device comparison view"
```

---

## Phase 11 — Cleanup

**Goal:** remove `Legacy/` entirely; the repository contains only the v2 Tuist project. Because
every prior phase already treated `Legacy/` as inert reference material rather than something to
pick apart file-by-file (§0.2, and the notes in Phase 8/9), this phase is now a single, simple step
instead of an archaeology exercise.

**Delete:**
```
git rm -r Legacy/
```

Before running it, do one last read-through of `Legacy/` for anything you referenced but never
actually finished porting (§2A.6/Phase 7's "no silent caps" tracking list is the place to check) —
once this commit lands, `Legacy/` is gone from the working tree (still recoverable from git history
if needed, but no longer sitting in the checkout as a temptation to keep referencing). Regenerate
with `tuist generate` one more time as the final structural check.

**Checkpoint:** `git status` shows a repository that's entirely the v2 module tree; `tuist build`
and `tuist test` both pass from a clean checkout with no manual steps beyond `tuist install`.

**Commit:**
```
git commit -m "Phase 11: remove Legacy/ — v2 rewrite is now the only source in the repository"
```

At this point, opening a PR from `v2-rewrite` into `dev`/`main` (or fast-forwarding it directly, if
you've been working solo and don't need review) is the natural next step — that merge decision is
yours to make when you're satisfied with where things stand, not something this plan prescribes.

---

## Phase 12 — Stretch goals (pick up anytime after Phase 9)

None of these block each other or anything above; do them in whatever order interests you most.
Same commit discipline applies — one commit per item as you finish it, not a grab-bag commit at the
end, since these can land weeks apart from each other:

- **Step/scrub UI**: `ReplayEngine.stepForward/stepBackward/seek` (§1.4) are already built as of
  Phase 1 — this is purely a `SortView` UI addition (a scrub `Slider` bound to `stepIndex`, forward/
  back buttons), no engine work.
- **Video/GIF export**: iterate `tape.operations` off-screen at a fixed frame rate into
  `ImageRenderer` → `AVAssetWriter`, using whichever `Visualizer` is selected — the same
  `VisualizationContext`/`draw(_:)` call the live UI uses, just driven by a loop instead of a
  `Timer`/`Task.sleep`.
- **CustomImage visualizer** (deferred in §2A.6): needs an image-picker UI and a per-pixel remap
  step keyed by current value permutation — worth doing once the other 14+ styles are stable and
  you want the single most novelty-heavy ArrayV style.
- **Teaching-mode step annotations** (§2A.6's noted-but-undesigned stretch goal): the seam is an
  optional annotation riding on `SortOperation`, surfaced by opt-in `Visualizer`s as
  `DrawCommand.text` captions. Actually designing this — what vocabulary of "step intents" makes
  sense across 189 different algorithms — is real, undone design work; don't start it without
  expecting a design pass at least as involved as §2A itself.
- **Showcase/playlist mode**: ArrayV's Groovy scripting layer (batch-run multiple algorithms in
  sequence) was explicitly not ported (§2A.6) — if you want it later, it's a thin orchestration
  layer over `SortSession`/`AlgorithmRegistry`, not a new engine concept.
