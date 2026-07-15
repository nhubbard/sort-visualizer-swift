# Sort Symphony v2 — Architecture

Status: **the v2 rewrite this document originally designed has shipped.** What follows is a
condensed record of the target architecture and the decisions behind it, kept brief wherever the
corresponding feature is built and real in `Modules/` — full detail is kept only for the design
questions still genuinely open (§2A's "Still open" list). For the ordered build history (now
complete) see `IMPLEMENTATION_PLAN.md`; its Phase 12 stretch goals are the same open items listed
in §2A, not a second, divergent list.

Section numbers below are kept stable from the original draft, since other docs and code comments
cross-reference them (e.g. "§2A.6").

---

## 0. Why a v2, precisely

The pre-v2 app centered on `SortViewModel`, a single `ObservableObject` that was simultaneously the
sort engine, the UI state store, the audio trigger, the analytics writer, and the algorithm host —
16 algorithms mutated its `@Published var data: [SortItem]` element-by-element, live, on the
`@MainActor`, while SwiftUI read that same array to render bars. That one structural fact was the
root cause of nearly every pain point: `@Observable` couldn't be adopted without a rewrite, adding
an algorithm touched six unrelated places, step/scrub/benchmarking were all "hard" because the
algorithm and the render were the same call stack, and CloudKit/device-detection/UI-alert state had
nowhere natural to live.

v2 fixed this at the root by making algorithms pure, synchronous, replayable data producers, with
everything else as a thin, focused, `@Observable`-friendly consumer of that data. That single change
is what the rest of this document (and everything actually built in `Modules/`) falls out of.

---

## 1. The core engine: record now, replay later — shipped

Sorting splits into two phases sharing nothing but a value type: **recording** (off the main actor,
no delay, no UI, no audio — an algorithm runs against `RecordingEngine` and appends every logical
operation to a `Tape`) and **replay** (`@MainActor`, user-controlled speed, fully steppable and
scrubbable — `ReplayEngine` walks the tape and exposes one `@Observable` current frame that SwiftUI
reads and nothing else ever touches).

This is built exactly as designed: `SortOperation`/`Marker`/`AuxHandle`/`TapeHeader`/`Tape`/
`RecordingEngine`/`ReplayEngine` all live in `Modules/SortEngineKit/Sources/`, with the checkpoint-
ladder scrubbing scheme (`ReplayEngine`'s `checkpoints`, snapshotted every ~500 operations) built as
originally planned. `TapeHeader.recordingDuration` still measures pure algorithmic wall-clock time,
decoupled from playback speed and free of UI/audio overhead — the design goal behind step/scrub,
speed control, and per-run analytics all being effectively free once this split exists.

---

## 2A. Modular visualizations and shuffles — shipped

`~/ArrayV` (a mature, prior-art Java sort visualizer) proved that "how to draw the array" doesn't
need to be baked into the sort engine — it ships 15 interchangeable visualization styles, chosen
independently of which algorithm is running. v2 adopted that split directly and it's built exactly
as designed. Subsection numbers below (§2A.3/§2A.4/§2A.6) are kept stable specifically because
source-code comments throughout `Modules/` (`Visualizer.swift`, `VisualizerRegistry.swift`,
`BarGraphVisualizer.swift`, `ShuffleAlgorithm.swift`, `SortSession.swift`, `Tape.swift`, the
`Disparity*Visualizer.swift` family, and others) reference them directly.

**The `Visualizer` protocol** (`Modules/VisualizationKit/Sources/`) never sees *how* an algorithm
works — only `ReplayEngine`'s already-computed current frame (`VisualizationContext`: values,
markers, aux arrays, canvas size, color seed), turned into `[DrawCommand]`, a plain `Codable`
description of shapes to draw (`.rect`/`.ellipse`/`.line`/`.polygon`/`.text`). **Rendering has moved
on from the original design**: this document originally specified a native
`Canvas { context, size in ... }` loop switching over `DrawCommand` cases. That shipped, then was
later replaced end-to-end by a Metal renderer (`Modules/SortFeature/Sources/MetalRendererView.swift`,
`MetalShapeRenderer`, `MetalBarRenderer`, and the per-visualizer `Metal*Layout` types) for
performance — there is no `Canvas`/`GraphicsContext` rendering path left anywhere in the app. The
`Visualizer`/`DrawCommand` split still describes the real plugin boundary; only the final "turn draw
commands into pixels" step changed backends.

### 2A.3 Visualizations are native-only, deliberately

A considered decision, not an omission: a `Visualizer.draw(_:)` is already a pure, synchronous,
~10-20 line function from data to data, cheap enough to author that a scripting bridge would only
add failure modes (timeouts, malformed scripts, bridge conversion bugs) to the one part of the
system that runs every frame, for a plugin axis that doesn't need the "author it without
recompiling" benefit as much as algorithms do. Every conformance lives in
`Modules/BuiltInVisualizers/Sources/`, 14 styles today. **CustomImage** (ArrayV's user-supplied-
image, remapped-per-permutation style) remains the one deferred visualization — still not built,
still the one style disproportionate in UI/remap cost relative to its value versus the other 14.

### 2A.4 Shuffles are tapes too

`ShuffleAlgorithm` (`Modules/AlgorithmKit/Sources/`) records against an identity array through the
same `RecordingEngine` primitives a sort uses; `SortSession` concatenates the shuffle's tape and the
sort's tape into one continuous `Tape` (`TapeHeader.sortStartIndex` marks the boundary), so a
shuffle-then-sort is just one longer replay with no `ReplayEngine` changes needed. ~38 shuffles ship
in `BuiltInAlgorithms`.

### 2A.6 Porting ArrayV content, and what's still open

Porting realized ~82 algorithms, ~38 shuffles, and 14 of ArrayV's 15 visualization styles as native
Swift (CustomImage excepted, §2A.3). The Disparity family (`DisparityBarGraph`/`DisparityCircle`/
`DisparityChords`/`DisparityDots`) shipped as ordinary conformances with no new engine feature — an
earlier draft of this document incorrectly believed they needed a new `originalIndices` field to
track each value's "home index"; they don't, since ArrayV's own source confirms the
`sin(π(value-index)/n)` formula only ever needs the array's ordinary current index, the same data
every other `Visualizer` already receives.

**Kept in full detail below, unlike the shipped content above, because these are genuinely still
open:**

- **Teaching-mode step annotations.** Visually indicating *what a step means* (e.g. "this compare
  decided the pivot side," "this write is the merge's output pointer advancing"), not just that a
  step happened. **Deferred, not designed.** The natural seam: an optional `annotation: String?` (or
  a small "step intent" enum) riding alongside `SortOperation`, surfaced by `Visualizer`s that opt
  in (e.g. as `DrawCommand.text` captions). Actually designing the vocabulary of step intents across
  ~82 different algorithms is real, undone design work — expect a design pass at least as involved
  as this section, not a quick addition.
- **Binary tape export/import for debugging a failed sort.** Dump a run's `Tape` to a compact file
  when a sort fails verification; load it back later without re-running the algorithm. **Deferred,
  not designed** — but the more tractable of this pair, since `Tape`/`TapeHeader`/`SortOperation`
  are already `Codable` (unused today, but present) and `ReplayEngine`'s only public initializer
  already just takes a plain `Tape` value with no opinion about where it came from, so import is
  nearly free once export exists. The real work is a small versioned, tag-byte-per-case binary
  encoder/decoder for `SortOperation` (skip `JSONEncoder`/`PropertyListEncoder` — both carry real
  per-field overhead for what's a 12-case enum of small `Int` payloads), plus a hook off
  `SortSession.phase == .failed` to write the file.
- **Video/GIF export.** Iterate `tape.operations` off-screen at a fixed frame rate through whichever
  `Visualizer` is selected, into `ImageRenderer` → `AVAssetWriter` — the same
  `VisualizationContext`/`draw(_:)` call the live UI uses, just driven by a loop instead of a
  display link. Not started.

---

## 3. Services — shipped

`SortViewModel`'s ~33 properties and 432 lines split into focused, single-purpose types, all real
today:

| Concern | Lives in |
|---|---|
| Recording/replay | `RecordingEngine`/`ReplayEngine`, `Modules/SortEngineKit/` |
| Audio | `AudioService`/`AudioPlaying`, `Modules/AudioEngineKit/` — backed by `Modules/ToneKit/` (a local AVAudioEngine-based synth), **not AudioKit**; AudioKit/AudioKitEX/SoundpipeAudioKit were fully removed and replaced |
| Analytics/persistence | `AnalyticsService`, `Modules/PersistenceKit/` — SwiftData with CloudKit sync (`iCloud.com.nhubbard.Sort2.mobile`), so a recorded run from any of your own devices feeds the same `BigOCorrelationChart` |
| Settings | `AppSettings`, `Modules/SettingsKit/` |
| Orchestration | `SortSession`, `Modules/SortFeature/Sources/SortSession.swift` — the only type that composes the above; each algorithm screen owns its own instance, matching the pre-v2 "each screen gets its own view model" behavior |

One deviation from the original design worth keeping as a decision record: **the confirmation-
dialog/warning-toggle system** (a generalized `SortGate`/`AlgorithmWarning` pair meant to replace
Bogo/Bitonic-specific warning booleans) was built partway, then removed in favor of ArrayV's own,
simpler precedent — an `unreasonableLimit`-style approach, realized here as unconditional
`AlgorithmMetadata.sizeRange` clamping in `SortSession.start(size:)`. No per-algorithm settings
toggle exists or is needed.

---

## 4. The reactive SwiftUI layer — shipped

Every `@Observable` type (`ReplayEngine`, `SortSession`, `AppSettings`) mutates its observed state
from exactly one place — a `@MainActor` method, one property (or one atomically-replaced value) at
a time, never concurrently with a reader. That precondition is what made `@Observable` actually work
here, where it broke down against the old `SortViewModel`'s live element-by-element mutation. The
real view layer follows the designed shape throughout: `@Environment(AppSettings.self)` injection
instead of `@EnvironmentObject`, `@State private var session: SortSession` per algorithm screen
instead of `@StateObject`, `@Bindable` only where a two-way binding is genuinely needed, and
data-driven sidebar navigation off `AlgorithmRegistry.shared.algorithms(in:)` instead of hand-
maintained parallel switches. As in §2A, the one substantive drift from the original sketch is the
renderer: the SwiftUI layer hosts a Metal view (`MetalRendererView`), not a `Canvas`.

---

## 5/6. Module graph — shipped, see `Project.swift` for the live source of truth

The coarse-grained module boundaries this document originally specified are built, with `Project.swift`
and `Modules/` now the authoritative record rather than a table here that would just drift out of
sync again. Two real deviations from the original graph, worth calling out explicitly since they
change the shape rather than just filling it in: **no `ScriptingKit` module** — algorithms and
shuffles are native Swift only now — and **no separate `BenchmarkFeature` module** — the Swift
Charts complexity-correlation goal it was meant to carry shipped inside `SortFeature`/
`PersistenceKit` instead (§2A), never as its own module.
Tuist structure is a single `Project.swift` with many targets, as originally decided (§9) — no
multi-project workspace.

---

## 7. Testing strategy — shipped

One parameterized suite runs every registered algorithm and shuffle through `RecordingEngine` and
asserts sortedness; `ReplayEngine` is tested against hand-built tape fixtures (stepping, seeking,
and stepping-then-seeking all asserted to agree); every `Visualizer` conformance gets a plain unit
test feeding a hand-built `VisualizationContext` and asserting the expected `[DrawCommand]`s. See
`Modules/*/Tests/` throughout — this is no longer a plan, it's the actual test suite shape.

---

## 8. Migration plan

See `IMPLEMENTATION_PLAN.md` — now a build history rather than a forward plan; its remaining stretch
goals are the same ones listed in §2A above.

---

## 9. Resolved decisions

- **macOS target shape — Mac Catalyst, not native AppKit.** Deliberate: `NSSlider` draws a visible
  tick mark per step for a stepped slider (a real defect this app's speed/size sliders would hit),
  and Catalyst doesn't have that problem. No native macOS destination is planned.
- **Algorithms/shuffles — native Swift permanently, no scripting stage.**
- **Visualizations — native-only from day one**, never scripted. See §2A.
- **CloudKit — retained**, so a run recorded on any of your own devices feeds the same Big-O
  correlation chart (§2A/§3). A dedicated device-to-device comparison view (the original motivation
  for keeping CloudKit at all) was dropped as a goal outright, not just deferred — with the
  recording architecture's `recordingDuration` measuring raw per-device CPU speed rather than
  anything intrinsic to the algorithm, a cross-device comparison wouldn't actually mean anything.
- **Downloadable algorithm packs — no.** Bundled-only; revisit only if a concrete need to distribute
  content outside the app bundle shows up.
- **Tuist structure — single project, many targets.** See §5/6.
- **Confirmation-dialog/warning-toggle system — removed, not built.** See §3's deviation note.
