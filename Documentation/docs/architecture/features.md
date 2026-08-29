# Features & app target

This layer consists of `SortFeature`, `SettingsFeature`, `HomeFeature`, `IntentsKit`, and the
`SortSymphony` app target. The app target assembles every other layer into a running app.

## `SortFeature`: the sort screen and the Metal rendering host

This is the largest module. It composes nearly every service in the app.

### `SortSession`: the orchestrator

```swift
@Observable @MainActor
public final class SortSession { ... }
```

`SortSession` is the only type that owns instances of `RecordingEngine`, `ReplayEngine`,
`AudioPlaying`, `AnalyticsService`, and `AppSettings` at once. Each algorithm screen constructs its
own `SortSession`. No shared global sort state exists. `SortSession` performs four steps, in
order:

1. Call `TapeFactory.makeTape(algorithm:shuffle:size:operationCap:)` (see
   [Engine layer](engine.md)) to record a shuffle-then-sort tape.
2. Construct a `ReplayEngine` from that tape. Drive its `play()`, `pause()`, `stepForward()`, and
   `seek(to:)` methods in response to `RunControlBar`'s transport controls.
3. Fire audio per touched index, through a closure passed to `ReplayEngine.play(onStep:)`. This
   closure is the only connection between `SortEngineKit` and `AudioEngineKit`; `SortEngineKit`
   itself has no dependency on audio code.
4. Once a run reaches `.complete`, pass the tape's header to `AnalyticsService.record(...)`. This
   call never happens during recording or replay.

`SortSession` also drives automation: Showcase mode (every algorithm run in sequence), the
size-sweep loop, the max-size-only loop, and the Full Sweep coverage driver (described below) all
call `SortSession.runAutomation(_:)`/`runShowcasePass()`. One code path runs a sort without manual
transport-control input, shared by four triggers: in-app buttons, keyboard shortcuts, and App
Intents.

### `NonScrollingSortView` versus `ScrollingSortView`

Both views mount the same underlying `SortView`. The app chooses between them based on whether the
mount is about to run through automation.

- **`ScrollingSortView`** is the manually-selected-algorithm screen: a full `ScrollView` with
  `AlgorithmDetailSection` (description, complexity, code samples) below the visualization.
- **`NonScrollingSortView`** is the lean counterpart, used for Showcase, Full Sweep, an
  App-Intent-triggered run, or a classic automation. All four cycle through a fresh combination
  roughly once a second; no user can scroll down and read content before it changes.
  `ScrollingSortView` already skips rendering that content in this case, but its
  `GeometryReader`/`ScrollView`/`VStack` wrapper still had to mount and lay out fresh on every
  combination. A Full Sweep profiling pass measured this cost directly. `NonScrollingSortView`
  removes the wrapper entirely.

### The Metal renderer family

Every visualizer's `[DrawCommand]`-shaped geometry has a Metal render pipeline for performance. The
app has no `Canvas`/`GraphicsContext` path; see
[Architecture overview](overview.md#rendering-metal-not-canvas). The renderer components:

- **`MetalRendererFactory`** maps a `VisualizerID` to its concrete renderer type. For example, it
  routes `"bargraph"` to the special-cased `MetalBarRenderer`, most rectangle- or ellipse-shaped
  visualizers to one generic `MetalShapeRenderer<Layout>`, and triangle-fan-shaped visualizers
  (`colorcircle`, `disparitycircle`, `spiral`) to `MetalTriangleRenderer<Layout>`.
- **`MetalShapeRenderer<Layout>`** and **`MetalTriangleRenderer<Layout>`** are generic over a
  `MetalShapeLayout`/`MetalTriangleLayout` conformance, one per visualizer, defined in
  `MetalVisualizerLayouts.swift`/`MetalPolygonVisualizerLayouts.swift`. Each layout computes only a
  slot's raw underlying value and color ingredients. The vertex shader resolves the on-screen
  geometry and final color. This design keeps per-frame easing and color transitions cheap enough
  to run at 120fps on large arrays.
- **`MetalBarRenderer`** is the one visualizer with its own hand-written renderer, not a generic
  `Layout` conformance. It predates the generic pattern; it was the original proof of concept for
  moving geometry computation onto the GPU.
- **`MetalHanoiTowersRenderer`** is a special case, with its own supporting types
  (`HanoiMoveScheduler`, `MetalHanoiGeometry`). The tower lift, carry, and restore animation
  described in [Content layer](content.md) uses different math from every other visualizer; it does
  not fit a `Layout` conformance.
- **`MetalIncrementalRenderer`** is the shared protocol every renderer above conforms to:
  `apply(_:values:valueRange:markers:)`, called once per `SortOperation` as `ReplayEngine` applies
  it. A renderer repaints only the positions a given operation touched, not the whole frame.

### Algorithm content: `AlgorithmDetailStore`

`AlgorithmDetailContent`, `AlgorithmDetailStore`, `AlgorithmDetailsEnvelope`, and
`AlgorithmDetailsManifest` implement the runtime side of the packed `AlgorithmDetails.algz`
archive. See [Compression formats](../reference/compression.md) for the byte format and
[Managing algorithm content](../guides/algorithm-content.md) for the build process.
`AlgorithmDetailStore` is an actor singleton. It decodes the archive once per app launch and caches
the result. A fire-and-forget prewarm call at launch starts this decode (roughly 1.5 seconds)
before the user opens a detail view.

### Analytics and coverage tooling

- **`BigOCorrelationChart`**/**`BigOCorrelationDetailView`** render `PersistenceKit`'s
  `BigOCorrelation` output as a Swift Charts view: observed runs as points, a per-size average as a
  trendline, and the algorithm's declared best, average, and worst curves as dashed reference
  lines.
- **`AutomationRegistry`** declares each automation (Size Sweep, Max Size Only) as one
  `Automation` value, pairing its size list, keyboard shortcut, and display metadata. This is the
  one source of truth read by both the in-app Automator menu and the invisible keyboard-shortcut
  buttons.
- **`CoverageSweepDriver`**, with its pure, registry-agnostic `CoverageSweepEnumerator` factored out
  for testability, drives Full Sweep: every algorithm, shuffle, and visualizer combination. An
  append-only TSV log makes a sweep resumable across app launches or interruptions. At current
  content counts, Full Sweep covers 167 algorithms × 44 shuffles × 15 visualizers, or 110,220
  combinations.
- **`TapeArchiveDocument`** implements the Export Tape and Import Tape feature: a `FileDocument`
  conformance wrapping `Tape.archived()`/`Tape(archivedData:)` (see
  [Compression formats](../reference/compression.md)) for `ShareLink` and `.fileImporter`.

### `SortCoordinator`: the App Intents bridge

Neither a per-screen `SortSession` nor `ContentView`'s private sidebar selection state is reachable
from outside SwiftUI's view tree. An `AppIntent.perform()` call runs detached from any specific
view. `SortCoordinator` (`@Observable @MainActor`, `.shared`) bridges this gap:

- It holds the sidebar's real `selection` binding, so an intent can select an algorithm the same
  way a manual tap would.
- It holds a `PendingAction` queue (`run`, `automation`, `loadTape`). Whichever `ScrollingSortView`
  mounts next for the target algorithm consumes the pending action exactly once.

`SortCoordinator` also fixed a real bug: the SortCommands menu previously unregistered commands on
task-return rather than view-disappear, so the menu went dead after any sort finished.

## `SettingsFeature`

`SettingsFeature` contains one view, `SettingsView`, built from
`@Bindable var settings = AppSettings.shared`. Every control (visualizer picker, playback-speed
slider, pacing-mode toggle, code theme picker, reset button) binds directly to `AppSettings`. No
separate settings view model exists. `SettingsFeature` depends on `SettingsKit`,
`VisualizationKit`, `AlgorithmKit`, `AudioEngineKit`, and `DesignSystemKit`, one dependency per
settings section it controls.

## `HomeFeature`

`HomeFeature` contains one view, `HomeView`: the welcome screen shown before an algorithm is
selected, rendered from a Markdown string (`MarkdownUI`). Its category-overview paragraph
describes the app's ten `AlgorithmCategory` families directly. A maintainer updates this text by
hand when categories change.

## `IntentsKit`: Shortcuts and Siri

`IntentsKit` wraps `AlgorithmRegistry`, `VisualizerRegistry`, `ShuffleRegistry`, and
`AutomationRegistry` as App Intents entities and queries: `AlgorithmEntity`, `VisualizerEntity`,
`ShuffleEntity`, `AutomationEntity`, and their `Find*Intent` query counterparts. It defines action
intents (`RunSortIntent`, `RunAutomationIntent`, `RunShowcaseIntent`, `RunFullSizeSweepIntent`,
`RunVisualizerShowcaseIntent`, `StopIntent`, and setting-adjustment intents for array size,
shuffle, playback, and visualizer). `SortSymphonyShortcuts`, an `AppShortcutsProvider`, ships
pre-built Shortcuts with the app: an action such as "Run a Sort Symphony size sweep" works in
Shortcuts, Spotlight, and Siri immediately after install, with no import step. Every action intent
calls `SortCoordinator` (above) to select and run something, since that is the only entry point
into SwiftUI's live selection state from outside the view tree.

`IntentsKit` depends on `AlgorithmKit`, `VisualizationKit`, `SortFeature` (for `SortCoordinator`),
and `SettingsKit`.

## The `SortSymphony` app target

`App/Sources/Sort2App.swift` is the composition root. It is the only file with visibility into
both `BuiltInAlgorithms`/`BuiltInVisualizers` and the registries they populate:

```swift
AlgorithmRegistry.shared.builtIns = [ /* every SortAlgorithm(), alphabetized */ ]
ShuffleRegistry.shared.builtIns  = [ /* every ShuffleAlgorithm(), alphabetized */ ]
VisualizerRegistry.shared.builtIns = [
  BarGraphVisualizer(), RainbowVisualizer(), ScatterPlotVisualizer(), /* ...all 15 */
]
AlgorithmRegistry.shared.discover()
ShuffleRegistry.shared.discover()
VisualizerRegistry.shared.discover()
```

The [algorithm](../guides/adding-an-algorithm.md), [shuffle](../guides/adding-a-shuffle.md), and
[visualizer](../guides/adding-a-visualizer.md) guides list this file as a required registration
site because `AlgorithmKit`/`VisualizationKit` cannot see the concrete types in
`BuiltInAlgorithms`/`BuiltInVisualizers` — that dependency edge runs the other way. Nothing
populates a registry's `builtIns` automatically.

Beyond composition, the app target owns:

- `ContentView`'s data-driven sidebar, built from `AlgorithmRegistry.algorithms(in:)`, not a
  hand-maintained switch over categories.
- The `AUv3Extension` app-extension dependency (Mac Catalyst only), embedded through Tuist's
  automatic inference from the extension's `.appExtension` product type. See
  [Audio subsystem](audio.md).
- App Intents metadata wiring. `AppIntents.framework` is linked directly by the app target, even
  though every `AppIntent`/`AppEntity` conformance lives in `IntentsKit`. Xcode's metadata
  extractor exports Shortcuts into the app bundle only when the app target directly links the
  framework, not when it links transitively through another framework.

`Project.swift` is the source of truth for the current dependency graph. This page summarizes it;
consult `Project.swift` directly when a dependency edge's exact reasoning matters.
