# History

The current app is the result of a full rewrite. This page covers that rewrite's phases and the
work still remaining.

## Why the rewrite happened

The original app centered on `SortViewModel`, one `ObservableObject` that combined the sort engine,
the UI state store, the audio trigger, the analytics writer, and the algorithm host. Algorithms
mutated a `@Published` array element by element, live, on the main actor. SwiftUI read that same
array to render bars.

This structure caused most of the old app's problems:

- `@Observable` could not be adopted without a rewrite.
- Adding an algorithm required touching six unrelated places.
- Step, scrub, and benchmarking were all hard, because the algorithm and the renderer shared one
  call stack.

The rewrite fixed this by making algorithms pure, synchronous, replayable data producers. Every
other component became a thin consumer of that data. [Architecture overview](overview.md) covers
the resulting design. This page covers how the app got there.

## Build history

| Phase | Goal | Result |
|---|---|---|
| 0 | Archive the pre-rewrite source; bootstrap an empty module graph. | Done. The team removed the archived source once the migration finished. |
| 1 | Build `SortEngineKit`: tape, `RecordingEngine`, `ReplayEngine`, unit-tested. | Done. |
| 2 | Build `AlgorithmKit` and one native algorithm (Quick Sort), proving record-then-replay end to end. | Done. |
| 3 | Build a JavaScript scripting bridge for algorithms, proven with Bubble Sort. | Done, later removed entirely. Every algorithm and shuffle is native Swift, with no scripting layer. |
| 4 | Build `VisualizationKit` and a first native visualizer (Bar Graph); build the first real sort screen. | Done. Rendering has since moved from `Canvas` to Metal; see [Architecture overview](overview.md#rendering-metal-not-canvas). |
| 5 | Add a second and third visualizer, proving the visualization axis is independent of the algorithm. | Done. 16 visualizer styles ship today, including Custom Image. |
| 6 | Make shuffles into tapes: `ShuffleAlgorithm`, concatenated shuffle-and-sort recording. | Done. 43 shuffles ship today. |
| 7 | Port ArrayV content at scale. | Ongoing. See [Port status](../reference/port-status.md) for current progress. |
| 8 | Decompose services: `AudioService`, `AnalyticsService` (CloudKit), `AppSettings`. | Done. `AudioService` uses a local synth built on `AVAudioEngine`, not a third-party audio package. |
| 9 | Build a data-driven `ContentView` and real `SettingsFeature`/`HomeFeature` views. | Done. |
| 10 | Finalize persistence and complexity views. | Done, with one scope change: the Big-O correlation chart shipped inside `SortFeature`/`PersistenceKit`, not as its own module. The team dropped a separate device-to-device comparison view as a goal (see [Architecture overview](overview.md#platform-and-scope-decisions)). |
| 11 | Clean up: remove the archived pre-rewrite source. | Done. The repository contains only the rewritten module tree. |

## Later additions

Three items from the original design have since taken shape:

- **Custom Image** now uses a dedicated Metal texture renderer and image tiles linked to array
  values. Users can choose a photo or file, or try a built-in sample. The chosen image is saved
  locally and downsampled before texture creation. See [Content](content.md).
- **Live video recording** captures actual playback through ScreenCaptureKit on supported Mac
  Catalyst versions, with ReplayKit on iPadOS and as a fallback. Deterministic off-screen export
  remains a separate possibility. See the [recording guide](../guides/live-recording-2026-10-08.md).
- **Teaching graph and annotations** link algorithm-authored decisions to replay positions. The
  graph and explanations can be inspected while stepping and seeking. See the
  [teaching graph guide](../guides/teaching-graph-annotations.md).

Two other items from the original list have shipped:

- **Fixed-duration playback pacing** shipped as a pacing mode alongside the default
  ops-per-second mode. `ReplayEngine` includes an adaptive controller that recomputes the required
  rate every tick from real remaining time and remaining work.
- **Binary tape export and import** shipped with a larger scope than originally planned. The
  original design scoped export to failed sorts only. Since nothing in `SortSession` actually
  restricts export that way, it shipped as a general, user-triggered action available whenever a
  tape exists. This feature is also why `ZstdKit` gained a real encoder, not just a decoder; see
  [Compression formats](../reference/compression.md) for the reason.
