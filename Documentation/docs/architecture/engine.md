# Engine layer

This layer consists of `SortEngineKit`, `AlgorithmKit`, `VisualizationKit`, and `ZstdKit`. None of
these modules import SwiftUI or UIKit. Except for `ReplayEngine`'s use of `@Observable`/
`@MainActor`, they have minimal framework dependencies. This is the most-tested, least-churned part
of the app. Understand it before changing anything else.

## `SortEngineKit`: the tape

Everything in this section lives in `Modules/SortEngineKit/Sources/`.

### `SortOperation`

A `Tape` is an ordered array of `SortOperation` values. Each value represents one logical step an
algorithm performs. Replaying operations in order drives stepping, scrubbing, and speed control.

```swift
public enum SortOperation: Sendable, Codable, Equatable {
  case swap(Int, Int)
  case setValue(Int, Int)
  case mark(marker: Int, index: Int)
  case unmark(marker: Int)
  case unmarkAll
  case unmarkIndex(marker: Int, index: Int)
  case compare(Int, Int)
  case markSorted(Int)
  case auxCreate(handle: Int, length: Int)
  case auxWrite(handle: Int, index: Int, value: Int)
  case auxDelete(handle: Int)
  case reversal
}
```

Two cases are counted but structurally inert: `.compare` and `.reversal` never change `values`
directly.

- A `.reversal` is immediately followed by the individual `.swap`s that perform the flip. Scrubbing
  shows the reversal swap by swap. The `.reversal` case itself counts once against
  `TapeHeader.reversalCount`.
- `SortOperation.isAudible` classifies which cases `AudioService` can play a note for (`.compare`,
  `.swap`, `.setValue`, `.auxWrite`). See [Audio subsystem](audio.md).

### `RecordingEngine`

`RecordingEngine` is the only interface an algorithm touches. It is a synchronous,
`mutating`-method struct: no actor, no `async`, no `@MainActor`.

```swift
public struct RecordingEngine: Sendable {
  public private(set) var values: [Int]
  public mutating func compare(_ i: Int, _ j: Int, by cmp: (Int, Int) -> Bool = (>=)) -> Bool
  public mutating func swap(_ i: Int, _ j: Int)
  public mutating func setValue(_ i: Int, _ value: Int)
  public mutating func mark(_ marker: Int, at index: Int)
  public mutating func createAuxArray(length: Int) -> AuxHandle
  public mutating func writeAux(_ handle: AuxHandle, at index: Int, value: Int)
  public mutating func reversal(_ start: Int, _ end: Int)
  public func finish() -> RecordingSummary
}
```

`compare` and `swap` apply `Marker.primary`/`.secondary` automatically. Each call retracts the
previous call's marks first, so at most one index carries `.primary` and one carries `.secondary`
at any time. This produces a "what's happening right now" highlight, not a permanent mark. Any
marker beyond primary and secondary (a pivot marker, a bucket marker, a custom marker) is the
algorithm's own choice. The algorithm controls when to retract it.

`createAuxArray`, `writeAux`, and `deleteAuxArray` back scratch buffers: merge sort's temp array,
LSD Radix's per-digit registers, bucket sort's buckets. Routing these writes through the engine,
instead of using a plain Swift array, makes `auxWriteCount` and the visualizer's rendering of aux
arrays possible.

`RecordingEngine` enforces a hard operation cap (`RecordingEngine.defaultOperationCap`, 300,000).
`SortSession` always passes the live, user-tunable `AppSettings.recordingOperationCap` instead of
the default. Once the tape reaches the cap:

- `compare`, `swap`, and the other methods keep mutating `values`. The algorithm still runs to
  correct completion.
- The tape stops growing. This bounds the run's memory footprint.
- `finish()`'s `RecordingSummary` reports `didExceedCap`, along with the algorithm's true operation
  counts, which keep incrementing past the cap. A caller that skips an oversized run still has real
  numbers to display or log.

### `Tape`

```swift
public struct TapeHeader: Sendable, Codable, Equatable {
  public let algorithmID: String
  public let initialValues: [Int]
  public let visualSeed: UInt64
  public let compareCount, swapCount, mainWriteCount, auxWriteCount, reversalCount: Int
  public let recordingDuration: TimeInterval
  public let recordedAt: Date
  public let shuffleID: String?
  public let sortStartIndex: Int
  public let uniqueValueCount: Int?
}

public struct Tape: Sendable, Codable, Equatable {
  public let header: TapeHeader
  public let operations: [SortOperation]
}
```

- `recordingDuration` measures pure algorithmic wall-clock time, decoupled from playback speed.
- `sortStartIndex` marks where a shuffle's operations end and the sort's operations begin, within
  the same `operations` array. It is `0` when no shuffle precedes the sort. See
  [Content layer](content.md) for why a shuffle records against this same engine.
- `uniqueValueCount` exists because two shuffles (`ShuffledCubicShuffle`, `ShuffledQuinticShuffle`)
  resample through a skewed curve and can collapse several positions onto the same value. Distinct
  value count is not a fixed function of array size; the engine measures it per run.

`Tape` and its contents are `Codable`. This makes binary tape export and import possible with no
additional plumbing; see [Compression formats](../reference/compression.md).
`Tape.compactedForFastPlayback()` produces a replay-only copy with cosmetic marker bookkeeping
removed, used by fixed-duration pacing mode. `header`'s recorded stats are always copied verbatim,
never recomputed, so this method cannot change the reported operation counts. It changes only how
much cosmetic highlight flicker plays back.

### `ReplayEngine`

`ReplayEngine` is the only `@Observable` type that touches per-element sort state. It mutates that
state from one place: a single `@MainActor` method, one batch of operations at a time. This
precondition is what makes `@Observable` work here.

```swift
@Observable @MainActor
public final class ReplayEngine {
  public struct BarState: Identifiable, Sendable, Equatable {
    public let id: UUID          // stable per array position, never per value
    public internal(set) var value: Int
    public internal(set) var markers: Set<Int>
    public internal(set) var isSorted: Bool
  }

  public var frame: [BarState] { get }
  public var speed: Double                       // ops/sec, live
  public var useFixedDurationPacing: Bool        // alternate pacing mode
  public var targetDuration: Double

  public func stepForward()
  public func stepBackward()
  public func seek(to index: Int)
  @discardableResult public func play(onStep: ((SortOperation) -> Void)? = nil) -> Task<Void, Never>
  public func pause()
}
```

Key implementation details:

- **Scrubbing uses a checkpoint ladder.** `ReplayEngine.init` replays the whole tape once at
  startup, snapshotting a full `PlaybackState` every `checkpointInterval(forArrayCount:)`
  operations (at least every 500, scaled up for large arrays so total checkpoint memory stays
  bounded). `seek(to:)` binary-searches for the nearest checkpoint at or before the target, then
  replays forward. A seek never replays more than one interval's worth of operations, regardless of
  tape length.
- **Observed state lives in one struct, not several properties.** `frame`, `auxArrays`,
  `compareCount`, `swapCount`, and the rest all read from a single stored `PlaybackState`, written
  once per mutation. An earlier version used five or more separate `@Observable` stored properties.
  Each fired its own dirty-propagation on every tick, which pegged the main thread in SwiftUI's
  dependency-tracking machinery. Add new ArrayV-parity statistics to `PlaybackState`, not as new
  stored properties.
- **Two pacing modes use different math.** The default mode paces at a flat rate (`speed`, ops per
  second). `useFixedDurationPacing` targets a fixed wall-clock `targetDuration` for the whole
  replay instead. It recomputes the required rate every tick from the remaining real time and
  remaining significant work, so it self-corrects toward the deadline. "Significant" excludes
  cosmetic mark/unmark bookkeeping (`SortOperation.isSignificantForPacing`), so pacing tracks real
  algorithmic progress.
- **`play()` is display-link-driven, not a sleep loop.** An injectable `DisplayLinkDriving` seam
  supplies ticks: `CADisplayLinkDriver` in production, a deterministic fake in tests. Ticks come
  from real vsync, which decouples simulated progress (`speed × elapsed`) from actual frame
  delivery.
- **Large operation bursts apply in bounded chunks.** `maxOperationsPerChunk` caps each chunk at
  2000 operations, with a yield between chunks. This fixes a real freeze on throttled hosts: the
  iPadOS Simulator lacks true vsync and can stall `CADisplayLink` under load. Without chunking, a
  stalled-then-recovered tick could compute a rate that applies the entire remaining tape in one
  synchronous step.
- **Two `OSSignposter` intervals separate tape mutation from dispatch.** `"TickApply"` covers tape
  mutation; `"TickDispatch"` covers fan-out to renderers and audio. These exist because a past
  performance bug was invisible in a generic Instruments trace until traced back to `play()`'s
  internals by hand. For a replay performance issue, start with a Points of Interest capture using
  these two spans.

### `TapeFactory` (in `AlgorithmKit`, but tightly coupled to the above)

```swift
public enum TapeFactory {
  public static func makeTape(
    algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, size: Int, operationCap: Int
  ) throws -> Tape
}
```

`TapeFactory.makeTape` records the shuffle against an identity array `1...size`, then records the
sort against the shuffle's output. It concatenates both into one continuous `Tape`, setting
`sortStartIndex` to the point where the shuffle's tape ends. `recordingDuration` measures only the
sort. A shuffle's cost is not the algorithm's responsibility.

Both the standalone app's `SortSession` and `SortAudioCore`'s headless Audio Unit driver call this
function. It has no UI dependency, which is why it lives in `AlgorithmKit` rather than
`SortFeature`.

## `AlgorithmKit`: the protocols and registries

Everything in this section lives in `Modules/AlgorithmKit/Sources/`.

### The content protocols

```swift
public protocol SortAlgorithm: Sendable {
  var id: AlgorithmID { get }
  var metadata: AlgorithmMetadata { get }
  func record(into engine: inout RecordingEngine)
}

public protocol ShuffleAlgorithm: Sendable {
  var id: ShuffleID { get }
  var metadata: ShuffleMetadata { get }
  func record(into engine: inout RecordingEngine)
}
```

`Visualizer` lives in `VisualizationKit` and is described below. `SortAlgorithm` and
`ShuffleAlgorithm` share the same shape. A shuffle is an algorithm that starts from a sorted array
and ends at a scrambled one, recorded through the identical primitive surface. This mirrors
ArrayV, which treats shuffling the same way: a fractal shuffle can un-scramble as a genuine,
working visualization.

`AlgorithmMetadata` carries everything the UI, the settings screen, and the growth-model system
need to know about an algorithm without running it:

```swift
public struct AlgorithmMetadata: Sendable, Codable, Equatable {
  public var displayName: String
  public var category: AlgorithmCategory
  public var sizeRange: ClosedRange<Int>       // hard clamp, doubles as ArrayV's "unreasonable limit"
  public var growthModel: OperationGrowthModel // fitted operation-count curve, see below
  public var stable: Bool
  public var timeComplexity: ComplexityBounds
  public var spaceComplexity: String
  public var iconName: String
}
```

`sizeRange` is a hard limit, not a suggestion. `SortSession.start(size:)` clamps into it
unconditionally. This is the mechanism that prevents something like Bogo Sort from receiving an
array size that would run indefinitely. No separate confirmation dialog exists; see
[Architecture overview](overview.md#platform-and-scope-decisions).

`AlgorithmCategory` mirrors ArrayV's taxonomy exactly: `concurrent`, `distribution`, `exchange`,
`hybrid`, `impractical`, `insertion`, `merge`, `miscellaneous`, `quick`, `selection`. A ported
algorithm's category matches ArrayV's `setCategory(...)` call, even where that call disagrees with
ArrayV's own source-directory layout.

### `OperationGrowthModel` and `effectiveSizeRange`

Every algorithm's `growthModel` is a measured curve fit to its actual operation-count growth. See
[Recalibrating growth models](../guides/growth-model-calibration.md) for the fitting process.

`AlgorithmMetadata.effectiveSizeRange(operationCap:)` uses this curve, not the hand-picked
`sizeRange.upperBound`, to compute a live safe maximum size. Raising or lowering the
recording-operation-cap setting immediately recalculates every algorithm's real safe ceiling,
rounded down to a size the manual stepper can reach.

A separate hard constant, `maxReasonableArraySize` (8192), caps this value independently of the
operation cap. Some algorithms' true cost is not fully captured by their recorded operation count.
For example, `CycleSort`'s O(n²) comparisons happen through direct `engine.values` reads, not
`engine.compare`. Without the hard cap, such an algorithm's curve could solve to an unreasonable
size once a user raises the operation cap.

### Registries

```swift
@MainActor
public final class AlgorithmRegistry {
  public static let shared = AlgorithmRegistry()
  public var builtIns: [any SortAlgorithm] = []   // populated by the app's composition root
  public func discover()                          // builtIns -> algorithms
  public func algorithm(id: AlgorithmID) -> (any SortAlgorithm)?
  public func algorithms(in category: AlgorithmCategory) -> [any SortAlgorithm]
}
```

`ShuffleRegistry` and `VisualizerRegistry` (the latter in `VisualizationKit`) use the same shape.
`AlgorithmKit`, `VisualizationKit`, and their sibling protocol modules cannot see
`BuiltInAlgorithms`/`BuiltInVisualizers`; that dependency edge points the other way. The app's
composition root (`Sort2App.swift`) populates `builtIns` for all three registries before calling
`discover()`. This is why every new algorithm, shuffle, or visualizer requires registration there;
see the [guides](../guides/building.md).

## `VisualizationKit`: the drawing protocol

Everything in this section lives in `Modules/VisualizationKit/Sources/`.

```swift
public struct VisualizationContext: Sendable {
  public let values: [Int]
  public let valueRange: ClosedRange<Int>
  public let markers: [Int: Set<Int>]      // index -> active marker IDs
  public let auxArrays: [Int: [Int]]       // AuxHandle.rawValue -> contents
  public let canvasSize: CGSize
  public let colorSeed: UInt64             // TapeHeader.visualSeed, for deterministic color choices
}

public enum DrawCommand: Sendable, Codable, Equatable {
  case rect(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
  case ellipse(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
  case line(x1: Double, y1: Double, x2: Double, y2: Double, color: RGBAColor, lineWidth: Double)
  case polygon(points: [SIMD2<Double>], color: RGBAColor)
  case text(x: Double, y: Double, string: String, color: RGBAColor)
}

public protocol Visualizer: Sendable {
  var id: VisualizerID { get }
  var metadata: VisualizerMetadata { get }
  func draw(_ context: VisualizationContext) -> [DrawCommand]
}
```

A `Visualizer` receives only `ReplayEngine`'s current frame, converted to a plain, `Codable`,
inert description of shapes. It has no access to the algorithm's internal logic. This mirrors
ArrayV's own separation: `Visual.drawVisual` never touches `Sort`, `Reads`, or `Writes`.

No code renders a raw `[DrawCommand]` to the screen anymore. See
[Features & app target](features.md) for the Metal renderer that replaced that path. Every Metal
`*Layout` type is a port of this geometry math. Every built-in visualizer's unit tests still call
`draw(_:)` directly against a hand-built `VisualizationContext`.

## `ZstdKit`: decode and encode, for two unrelated reasons

`ZstdKit` (`Modules/ZstdKit/Sources/`) is a Zstandard codec written in Swift, with no C/C++
interop and no linked system library. It appears in the engine layer because both `SortEngineKit`
(tape export) and `SortFeature` (the packed algorithm-content archive) depend on it. `ZstdKit`
itself has no dependencies beyond Foundation.

A module containing both a decoder and an encoder can look like unused scope. It is not. The two
directions serve different consumers, built at different times, for different reasons:

1. **Decode came first**, to read `AlgorithmDetails.algz`: the app's roughly 294 KB packed archive
   of every algorithm's description and syntax-highlighted code samples (down from roughly 17.36 MB
   uncompressed). A Python pipeline (`App/Resources/AlgorithmDetails/manage.py`, using the
   `zstandard` PyPI package) builds this archive once, offline. The shipping app only reads it.
   Decode-only satisfied this requirement completely.
2. **Encode came later**, added on request for a different feature: exporting a recorded `Tape` to
   a file the user can share, and importing one back
   (`Tape.archived()`/`Tape(archivedData:)`). This has to run on-device, synchronously, with no
   Python or external toolchain available at runtime. That requirement forced a Swift-native
   Zstandard encoder.

`AlgorithmDetails.algz` (`ALGZ`/`ADTL`) and exported `.tape` files (`STAP`/`TAPE`) are unrelated at
the application level. One is build-time content; the other is a user-facing export feature. Both
share the same zstd frame format and a similar envelope shape. See
[Compression formats](../reference/compression.md) for both formats, and for the reason the
encoder's correctness was verified against an independent zstd implementation rather than trusted
from self-round-trip testing alone.
