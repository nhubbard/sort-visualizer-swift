# Architecture overview

## The core split: record now, replay later

The app used to center on `SortViewModel`, one `ObservableObject` that combined the sort engine,
the UI state store, the audio trigger, the analytics writer, and the algorithm host. Algorithms
mutated a `@Published var data: [SortItem]` array element by element, live, on the main actor.
SwiftUI read that same array to render bars.

This design caused most of the old app's problems:

- `@Observable` could not be adopted without a rewrite.
- Adding an algorithm required touching six unrelated places.
- Step, scrub, and benchmarking were all hard, because the algorithm and the renderer shared one
  call stack.

The current architecture fixes this by splitting sorting into two phases that share only a plain
value type:

- **Recording** runs off the main actor, with no delay, no UI, and no audio. An algorithm runs
  once, at full CPU speed, against a `RecordingEngine`. Every operation (a compare, a swap, a
  write) appends to a `Tape`.
- **Replay** runs on the main actor, at a user-controlled speed, fully steppable and scrubbable. A
  `ReplayEngine` walks the tape and exposes one `@Observable` current frame. SwiftUI reads that
  frame; nothing else touches it.

This split has one direct consequence: `TapeHeader.recordingDuration` measures pure algorithmic
wall-clock time, independent of playback speed. Step, scrub, speed control, and per-run analytics
all follow from this split without separate mechanisms.

See [Engine layer](engine.md) for the types this split is built from: `Tape`, `RecordingEngine`,
`ReplayEngine`, `SortOperation`.

## Three independent plugin axes

[ArrayV](https://github.com/gouravkhunger/ArrayV), a prior-art Java sort visualizer, established
the source pattern this app follows: drawing logic and shuffle logic don't need to live inside the
sorting algorithm.

- A `SortAlgorithm` sees only a `RecordingEngine`. It has no access to the active visualizer, the
  on-screen array state, or the audio settings.
- A `Visualizer` sees only a `VisualizationContext`: the replay engine's current values, markers,
  and aux-array contents. It has no access to the algorithm that produced that state. Switching
  visualizer styles mid-sort swaps one pure function for another.
- A `ShuffleAlgorithm` records against the same `RecordingEngine` primitives as a sort, starting
  from a sorted array. A shuffle-then-sort run produces one continuous `Tape` with a marked
  boundary (`TapeHeader.sortStartIndex`). `ReplayEngine` treats a shuffle segment and a sort
  segment identically.

This separation is why adding an algorithm, a shuffle, or a visualizer never requires a
project-file edit or a change to a central switch statement. Each addition is one new file that
conforms to a small protocol, plus registration at a few fixed call sites. See the
[guides](../guides/building.md) for the exact steps per content type.

## Native content only

Every algorithm, shuffle, and visualizer ships as compiled Swift. The app has no scripting bridge
and no interpreted-plugin format.

An earlier version of the app included a JavaScript scripting backend for algorithms. It shipped,
then was removed after review found it referenced a private API and blocked App Store submission.
Native Swift is the permanent content path for both algorithms and visualizers.

For visualizers, native-only was the original design, not a fallback. `Visualizer.draw(_:)` is a
pure, synchronous function, ten to twenty lines long. A scripting bridge would add failure modes
(timeouts, malformed scripts, conversion bugs) to the part of the system that runs every frame.

## Rendering: Metal, not `Canvas`

The `Visualizer` protocol still defines the plugin boundary: a `Visualizer` turns a
`VisualizationContext` into `[DrawCommand]`, a `Codable` description of shapes
(`.rect`, `.ellipse`, `.line`, `.polygon`, `.text`).

The rendering backend has changed. The original implementation used a native SwiftUI `Canvas`. For
performance, a Metal renderer replaced it end to end
(`Modules/SortFeature/Sources/MetalRendererView.swift` and related files). Every visualizer's
geometry logic now has a corresponding `Metal*Layout` type. The app has no `Canvas`/
`GraphicsContext` rendering path. Per-frame color and easing calculations run in vertex shaders on
the GPU, not on the CPU.

See [Features & app target](features.md) for the Metal renderer family.

## The reactive layer

Every `@Observable` type in the app (`ReplayEngine`, `SortSession`, `AppSettings`) mutates its
state from one place: a single `@MainActor` method, one property or one atomically-replaced value
at a time. No concurrent readers exist during a mutation.

This precondition makes `@Observable` work. The old design's live, element-by-element mutation
from inside the algorithm violated it.

The SwiftUI layer applies the same pattern throughout:

- `@Environment` injection for shared state.
- One `@State private var session: SortSession` per algorithm screen.
- `@Bindable` only where a two-way binding is required.
- A data-driven sidebar built from `AlgorithmRegistry.algorithms(in:)`, not a hand-maintained
  switch over categories.

## Platform and scope decisions

These decisions are settled, not open questions. They explain several non-obvious details
elsewhere in the codebase.

- **Mac Catalyst is the desktop target, not native AppKit.** `NSSlider` draws a visible tick mark
  per step on a stepped slider. This app's speed and size sliders would show that defect. Mac
  Catalyst does not have it. No native macOS destination is planned.
- **Algorithms and shuffles are native Swift, permanently.** No scripting stage exists or is
  planned.
- **Visualizations are native-only from the first version**, for the reasons above.
- **CloudKit sync is retained.** A run recorded on one device feeds the same Big-O correlation
  chart on another device signed into the same iCloud account. A device-to-device comparison view
  was considered and dropped: `recordingDuration` measures per-device CPU speed, not anything
  intrinsic to the algorithm, so a cross-device comparison would not be meaningful.
- **The app ships no downloadable algorithm packs.** All content is bundled. This would change
  only given a concrete need to distribute content outside the app bundle.
- **The Tuist structure is a single project with many targets**, not a multi-project workspace.
  See [Building the project](../guides/building.md).
- **The app has no per-algorithm confirmation dialog.** An earlier design built a generalized
  `SortGate`/`AlgorithmWarning` pair, meant to replace Bogo- and Bitonic-specific warning booleans.
  It was removed in favor of ArrayV's approach: unconditional `AlgorithmMetadata.sizeRange`
  clamping in `SortSession.start(size:)`. If an algorithm should not run at a given size, its
  `sizeRange` excludes that size. Settings has no opt-in or opt-out toggle for this behavior.

For open work items (a CustomImage visualizer, video export, teaching-mode step annotations), see
[History](history.md).
