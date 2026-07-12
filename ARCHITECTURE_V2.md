# Sort Symphony v2 — Target Architecture

Status: design document, not yet implemented. Supersedes the discussion in `INPUT.md` (a prior
planning conversation) by grounding it in the actual current codebase and extending it to cover
modular/scriptable algorithm and shuffle plugins plus a native, protocol-based *visualization*
plugin layer (informed by `~/ArrayV`, a prior-art Java visualizer — see §2A), full `SortViewModel`
decomposition, an
idiomatic `@Observable` SwiftUI architecture, and a real Tuist module graph.

For the concrete, ordered build sequence with real Tuist manifests and per-phase code, see
**`IMPLEMENTATION_PLAN.md`** — this document is the target design; that one is the "how to
actually write it, in what order" companion.

The WIP artifacts `Plugins/SortAlgorithmCore/`, `RawResources/quicksort/QuickSortPlugin/`,
`xcconfigs/*Plugin*.xcconfig`, `Project.swift`, `Tuist.swift`, `Tuist/`, and
`Sort Symphony-Tuist.xcodeproj`/`.xcworkspace` are all superseded by this document and should be
deleted once the new structure is in place (§8, step 9). They represented a one-Tuist-framework-
per-algorithm approach that never got past empty scaffolding — v2 replaces that idea entirely with
the scripted-plugin system in §2.

---

## 0. Why a v2, precisely

The current app (`Sort Symphony.xcodeproj`, single target `Sort Symphony (iOS)`, iOS/iPadOS +
Mac Catalyst) works, but has one structural root cause behind almost every pain point:

**`SortViewModel` (`Shared/Data/Primary/SortViewModel.swift`, 432 lines, `ObservableObject`) *is*
the sort engine, the UI state store, the audio trigger, the analytics writer, and the algorithm
host, all at once — and the 16 algorithms are `extension SortViewModel` methods that mutate its
`@Published var data: [SortItem]` element-by-element, live, on the `@MainActor`, while SwiftUI is
reading that same array to render bars.**

That single fact explains:

- Why `@Observable` broke everything when you tried it (`INPUT.md`): `@Published`/Combine batches
  and coalesces notifications; `@Observable`'s direct-access tracking does not tolerate thousands
  of interleaved element-level mutations against a value SwiftUI is mid-render on.
- Why adding an algorithm today touches six places: `Algorithms` enum case, `Page` enum case (+
  `displayName`/`iconName`/`algorithm` switch arms), the `switch` in `ContentView`, the `switch` in
  `SortViewModel.doSort()`, a new `*Impl.swift` extension, a new `Resources/*.bundle/` folder.
- Why step/scrub/record-video/benchmark-without-visuals are all “hard” today — the algorithm and
  the render are the same call stack, so you can't separate "what happened" from "how fast to show
  it."
- Why `CloudKit`, `IOKit`/`DeviceKit` platform detection, and UI alert flags all live inside
  `doSort()` — there was never a natural place to put them.

v2 fixes this at the root: **algorithms become pure, synchronous, replayable data producers**, and
everything else becomes a thin, focused, `@Observable`-friendly consumer of that data. Every
other requested improvement (plugin loading, service decomposition, reactive SwiftUI, Tuist
modularity) falls out of that one change.

---

## 1. The core engine: record now, replay later

This is the load-bearing idea (first sketched conceptually in `INPUT.md`; concretized here). Split
sorting into two phases that share nothing but a value type:

```
Phase 1 — Record (off the main actor, no delay, no UI, no audio):
    Algorithm runs against a plain in-memory buffer.
    Every logical operation it performs is appended to a Tape: [SortOperation].

Phase 2 — Replay (@MainActor, user-controlled speed, fully steppable/scrubbable):
    ReplayEngine walks the Tape and exposes ONE @Observable snapshot: the current frame.
    SwiftUI only ever reads that frame. It never sees the algorithm run.
```

### 1.1 The tape

```swift
// Module: SortEngineKit — no SwiftUI, no UIKit, no AudioKit, no Foundation-heavy deps.

public enum SortOperation: Sendable, Codable, Equatable {
    case swap(Int, Int)
    case setValue(Int, Int)
    case mark(marker: Int, index: Int)          // ArrayV-style: persists until unmark/unmarkAll
    case unmark(marker: Int)
    case unmarkAll
    case compare(Int, Int)                      // counted, structurally inert
    case markSorted(Int)                        // permanent "done" marker at completion
    case auxCreate(handle: Int, length: Int)    // scratch buffers for merge/radix/bucket sorts
    case auxWrite(handle: Int, index: Int, value: Int)
    case auxDelete(handle: Int)
}

/// Marker IDs, borrowed directly from ArrayV's `Highlights`: a marker stays "on" an index until
/// the algorithm explicitly clears it, rather than being scoped to a single operation the way the
/// original `Accent`-per-op design was. What a marker *looks like* is entirely the Visualizer's
/// decision (§2A) — the engine only ever tracks bare integer IDs, never colors or shapes.
public enum Marker {
    public static let primary = 1     // auto-applied by RecordingEngine.compare/swap
    public static let secondary = 2
    public static let pivot = 3       // algorithm-managed, e.g. held across a whole partition pass
    public static let write = 4
    public static func bucket(_ n: Int) -> Int { 100 + n }
}

public struct AuxHandle: Hashable, Sendable, Codable { public let rawValue: Int }

public struct TapeHeader: Sendable, Codable, Equatable {
    public let algorithmID: String
    public let initialValues: [Int]
    public let visualSeed: UInt64        // seeds e.g. Radix's shuffled bucket→color map, deterministically
    public let compareCount: Int
    public let swapCount: Int
    public let recordingDuration: TimeInterval   // wall-clock time to RECORD — this is the real perf number
    public let recordedAt: Date
}

public struct Tape: Sendable, Codable, Equatable {
    public let header: TapeHeader
    public let operations: [SortOperation]
}
```

Note `recordingDuration` — this is the actual algorithmic performance number (CPU time to produce
the tape), decoupled from playback speed. `BENCHMARKS.md`-style measurement becomes "record N
times, read `header.recordingDuration`," with **zero UI/audio overhead skewing the number** —
which the current architecture cannot do, since today "elapsed time" is polluted by the delay
slider and AudioKit scheduling.

### 1.2 The recording engine

A plain `struct` with `mutating` methods — no actor, no `async`, no `@MainActor`. This is the
*only* interface an algorithm ever touches. `compare`/`swap` auto-apply `Marker.primary`/
`.secondary` (matching ArrayV's `Reads.compareIndices`/`Writes.swap` convention of always marking
what they touch); everything past that — `pivot`, `bucket(n)`, custom markers — is the algorithm's
own choice, held across as many operations as it likes:

```swift
public struct RecordingEngine: Sendable {
    public private(set) var values: [Int]
    private var tape: [SortOperation] = []
    private var compareCount = 0
    private var swapCount = 0
    private var auxWriteCount = 0
    private var nextAuxHandle = 0

    public init(values: [Int]) { self.values = values }

    public var count: Int { values.count }

    public mutating func compare(_ i: Int, _ j: Int, by cmp: (Int, Int) -> Bool = (>=)) -> Bool {
        tape.append(.mark(marker: Marker.primary, index: i))
        tape.append(.mark(marker: Marker.secondary, index: j))
        tape.append(.compare(i, j))
        compareCount += 1
        return cmp(values[i], values[j])
    }

    public mutating func swap(_ i: Int, _ j: Int) {
        tape.append(.mark(marker: Marker.primary, index: i))
        tape.append(.mark(marker: Marker.secondary, index: j))
        tape.append(.swap(i, j))
        values.swapAt(i, j)
        swapCount += 1
    }

    public mutating func setValue(_ i: Int, _ value: Int) {
        tape.append(.mark(marker: Marker.write, index: i))
        tape.append(.setValue(i, value))
        values[i] = value
    }

    public mutating func mark(_ marker: Int, at index: Int) { tape.append(.mark(marker: marker, index: index)) }
    public mutating func unmark(_ marker: Int) { tape.append(.unmark(marker: marker)) }
    public mutating func unmarkAll() { tape.append(.unmarkAll) }

    /// Scratch buffers for algorithms that need one — LSD Radix's per-digit registers, merge
    /// sort's temp array, bucket sort's buckets. Mirrors ArrayV's `Writes.createExternalArray`;
    /// rendered as extra visual strips by the Visualizer (§2A), counted separately from `values`.
    public mutating func createAuxArray(length: Int) -> AuxHandle {
        defer { nextAuxHandle += 1 }
        tape.append(.auxCreate(handle: nextAuxHandle, length: length))
        return AuxHandle(rawValue: nextAuxHandle)
    }

    public mutating func writeAux(_ handle: AuxHandle, at index: Int, value: Int) {
        tape.append(.auxWrite(handle: handle.rawValue, index: index, value: value))
        auxWriteCount += 1
    }

    public mutating func deleteAuxArray(_ handle: AuxHandle) { tape.append(.auxDelete(handle: handle.rawValue)) }

    public mutating func markSorted(_ i: Int) { tape.append(.markSorted(i)) }

    public func finish() -> (tape: [SortOperation], compareCount: Int, swapCount: Int, auxWriteCount: Int) {
        (tape, compareCount, swapCount, auxWriteCount)
    }
}
```

No `guard await enforceRunning() else { return }` anywhere. A synchronous function **cannot** be
cancelled mid-loop-body anyway (today's checks are largely theater around `Task.sleep` points that
no longer exist once delay isn't interleaved into the algorithm). Cancellation now applies only to
*replay*, where it's a first-class, structured concept (`Task` cancellation on the replay loop).

### 1.3 The algorithm protocol

```swift
// Module: AlgorithmKit

public protocol SortAlgorithm: Sendable {
    var id: AlgorithmID { get }
    var metadata: AlgorithmMetadata { get }
    func record(into engine: inout RecordingEngine)
}

public struct AlgorithmID: Hashable, Sendable, Codable, RawRepresentable {
    public let rawValue: String
}

public struct AlgorithmMetadata: Sendable, Codable, Equatable {
    public var displayName: String
    public var category: AlgorithmCategory       // .logarithmic / .quadratic / .weird — same 3 groups you already use
    public var sizeRange: ClosedRange<Int>
    public var stable: Bool
    public var timeComplexity: ComplexityBounds   // best/average/worst — feeds the existing complexity.json + future Charts view
    public var spaceComplexity: String
    public var confirmationWarning: AlgorithmWarning?   // replaces the bespoke Bogo/Bitonic bool pairs (§3.4)
    public var iconName: String
}
```

Bubble Sort, ported, for comparison with the current `extension SortViewModel` version:

```swift
struct BubbleSort: SortAlgorithm {
    let id = AlgorithmID(rawValue: "bubblesort")
    let metadata = AlgorithmMetadata(displayName: "Bubble Sort", category: .quadratic, /* ... */)

    func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        for i in 1..<engine.count {
            for j in 0..<(engine.count - i) where engine.compare(j, j + 1) {
                engine.swap(j, j + 1)
            }
        }
    }
}
```

No `await`, no `@MainActor`, no `enforceRunning`. This is a straight, ordinary, synchronous,
100%-unit-testable function. Radix Sort's shuffled-bucket-color behavior (currently
`RadixSortImpl.swift`, `[Color].shuffled()` used as the bucket discriminator) maps directly onto
`Marker.bucket(Int)` + `header.visualSeed`, so the color choice moves from "part of the algorithm's
logic" to "a deterministic function of the seed, applied by the Visualizer at replay time" (§2A) —
themeable, and reproducible from a saved tape. LSD Radix's actual bucket *registers* — currently
approximated in v1 with `[[SortItem]]` living outside the visible array — become real aux arrays
via `engine.createAuxArray(length:)`/`writeAux(_:at:value:)`, matching ArrayV's
`Writes.createExternalArray`/`arrayListAdd` exactly, and giving Radix its own rendered strip
instead of silently mutating `data` out of order.

### 1.4 The replay engine

The **only** `@Observable` type that touches per-element sort state:

```swift
// Module: SortEngineKit

@Observable @MainActor
public final class ReplayEngine {
    public struct BarState: Identifiable, Sendable {
        public let id: UUID
        public internal(set) var value: Int
        public internal(set) var markers: Set<Int> = []   // which Marker IDs currently sit on this index
        public internal(set) var isSorted = false
    }

    public private(set) var frame: [BarState]
    public private(set) var auxArrays: [Int: [Int]] = [:]   // AuxHandle.rawValue -> current contents, for VisualizationContext
    public private(set) var stepIndex = 0
    public private(set) var isPlaying = false
    public private(set) var compareCount = 0

    private let tape: Tape
    private let stableIDs: [UUID]
    private let checkpoints: [(step: Int, frame: [BarState])]   // every ~500 ops, for O(1)-ish scrubbing
    private var playbackTask: Task<Void, Never>?

    public init(tape: Tape) { /* build initial frame + checkpoint ladder from tape.header.initialValues */ }

    public func stepForward() { /* apply tape.operations[stepIndex]; stepIndex += 1 */ }
    public func stepBackward() { /* replay from nearest checkpoint ≤ stepIndex - 1 */ }
    public func seek(to index: Int) { /* pause(); replay from nearest checkpoint */ }

    public func play(operationsPerSecond: Double) {
        isPlaying = true
        playbackTask = Task { [weak self] in
            while let self, self.stepIndex < self.tape.operations.count, !Task.isCancelled {
                self.stepForward()
                try? await Task.sleep(for: .seconds(1.0 / operationsPerSecond))
            }
            self?.isPlaying = false
        }
    }

    public func pause() { playbackTask?.cancel(); isPlaying = false }
}
```

Every mutation happens inside a single `@MainActor` method, one `stepIndex` at a time. There is no
concurrent writer, so `@Observable`'s direct-access tracking is exactly the right tool — this is
the reason the migration to `@Observable` will actually work in v2 where it failed in v1.

**What this buys you for free**, all of which are current `TODO.md` items or previously-abandoned
features:

| Feature | v1 status | v2 mechanism |
|---|---|---|
| Step forward/back | Disabled (commented out in v1.1) | `stepForward()`/`stepBackward()`, already shown above |
| Scrubbing | Never existed | `Slider` bound to `stepIndex`, calls `seek(to:)` |
| Speed control | `delay: Float` slider woven into every algorithm `await` point | `play(operationsPerSecond:)`, just a number, no algorithm changes |
| Complexity graphs (Swift Charts) | "Data collection is configured correctly" but ungenerated | Run `RecordingEngine` N times per size, off-screen, read `header.compareCount`/`recordingDuration` — no visual/audio cost |
| Video/GIF export | Not present | Iterate `tape.operations` off-screen at 60fps into `ImageRenderer` → `AVAssetWriter` |
| Benchmarking (`BENCHMARKS.md`) | Manual, hand-copied from debug `print()` | Automatic harness over `header.recordingDuration`/`compareCount`/`swapCount` |
| Insertion Sort's `while data != data.sorted()` bug (O(n³) blowup) | Present | Gone — a straight single-pass `record(into:)` implementation, unit-tested against a known-sorted assertion |

---

## 2. Modular, scriptable algorithms (JavaScriptCore plugin system)

> **Removed.** `ScriptingKit` (and the `App/Resources/Algorithms`/`Shuffles` script drop-in
> mechanism it enabled) was deleted after App Store validation rejected a TestFlight build for
> referencing a private API, `_JSContextGroupSetExecutionTimeLimit` (bound in
> `ExecutionTimeLimit.swift` via `@_silgen_name`, §2.2). By that point every algorithm and shuffle
> had already been ported to native Swift (§2.6, revised) and the JS path was unused in the
> shipping app, so it was deleted outright rather than patched. The rest of this section is kept as
> historical design record, not a description of current code.

This directly replaces the abandoned NSObject/`NSClassFromString`/`INFOPLIST_KEY_NSPrincipalClass`
bundle-plugin approach hinted at in `xcconfigs/QuickSortPlugin.xcconfig` (never implemented) and
the one-Tuist-framework-per-algorithm idea in `Project.swift` (also never populated). Both were
going to require an Xcode/Tuist project edit and a recompile for every new algorithm — the opposite
of what you asked for.

### 2.1 Why JavaScriptCore, and why it's App Store safe

`JSRecordingEngineExport`/`JSContext` is a public Apple system framework, not a bespoke scripting
runtime — this is the same category of thing as embedding Lua in a game or React Native's JS
bridge. Guideline 2.5.2 explicitly permits interpreters that execute *downloaded or bundled
scripts* as long as they don't change the primary purpose of the app or provide features
inconsistent with the app's stated intent. A sort-visualizer that runs sort-algorithm scripts to
visualize sort algorithms is squarely inside that carve-out, whether the scripts are:

- **bundled** in the app — this is the *only* mode v2 ships (§9): no downloadable content packs,
  no signing/trust story to design, no `applicationSupportAlgorithmsDirectory`. Every script is a
  known-at-build-time resource inside the app bundle, reviewed by App Review exactly once, same as
  any other asset. This sidesteps the 2.5.2 downloaded-script question entirely rather than relying
  on it — it's also fine per 2.5.2 if you ever want to revisit it, but there's no reason to take on
  that complexity now.

The key property that makes this safe *and* simple: JS algorithms and native Swift algorithms
produce the exact same thing — a `Tape` — through the exact same `RecordingEngine` primitive
surface. From the rest of the app's point of view there is no difference between a native and a
scripted algorithm. Shuffles (§2A.4) reuse this exact same bridge, since a shuffle is structurally
just another `RecordingEngine`-driven algorithm. Visualizations deliberately do **not** get this
treatment — see §2A.3 for why they stay native-only.

### 2.2 The bridge

```swift
// Module: ScriptingKit

@objc protocol JSRecordingEngineExport: JSExport {
    func compare(_ i: Int, _ j: Int) -> Bool
    func swap(_ i: Int, _ j: Int)
    func getValue(_ i: Int) -> Int
    func setValue(_ i: Int, _ value: Int)
    func count() -> Int
    func markSorted(_ i: Int)
}

@objc final class JSRecordingEngineBridge: NSObject, JSRecordingEngineExport {
    private(set) var engine: RecordingEngine
    init(engine: RecordingEngine) { self.engine = engine }

    func compare(_ i: Int, _ j: Int) -> Bool { engine.compare(i, j) }
    func swap(_ i: Int, _ j: Int) { engine.swap(i, j) }
    func getValue(_ i: Int) -> Int { engine.values[i] }
    func setValue(_ i: Int, _ value: Int) { engine.setValue(i, value) }
    func count() -> Int { engine.count }
    func markSorted(_ i: Int) { engine.markSorted(i) }
}

struct JSAlgorithmAdapter: SortAlgorithm {
    let id: AlgorithmID
    let metadata: AlgorithmMetadata
    let source: String   // contents of the .js file

    func record(into engine: inout RecordingEngine) {
        let bridge = JSRecordingEngineBridge(engine: engine)
        let context = JSContext()!
        context.setObject(bridge, forKeyedSubscript: "engine" as NSString)

        var caughtError: String?
        context.exceptionHandler = { _, exception in caughtError = exception?.toString() }

        // Enforce a hard wall-clock ceiling on untrusted script execution using the
        // JavaScriptCore C API (JSContextGroupSetExecutionTimeLimit), reachable via
        // context.jsGlobalContextRef — a badly written or malicious plugin cannot hang the app.
        installExecutionTimeLimit(on: context, seconds: 5.0)

        context.evaluateScript(source)
        context.evaluateScript("sort(engine)")

        engine = bridge.engine   // struct copy-back — RecordingEngine's tape is now populated
        if let caughtError { /* surface as SortSession.phase = .failed(.pluginError(caughtError)) */ }
    }
}
```

A misbehaving script becomes a caught, user-visible "this plugin failed" state — never a crash,
never a hang, because the execution-time watchdog forcibly interrupts a runaway script.

### 2.3 Script + manifest contract

Each plugin is **two files**, dropped into a folder, nothing else:

```
Algorithms/
  quicksort.js
  quicksort.manifest.json
```

```javascript
// quicksort.js
function sort(engine) {
    quicksort(0, engine.count() - 1);
    function quicksort(left, right) {
        if (left >= right) return;
        const p = partition(left, right);
        quicksort(left, p - 1);
        quicksort(p + 1, right);
    }
    function partition(left, right) {
        let i = left - 1;
        for (let j = left; j < right; j++) {
            if (engine.compare(j, right)) { i++; engine.swap(i, j); }
        }
        engine.swap(i + 1, right);
        return i + 1;
    }
}
```

```json
{
    "id": "quicksort",
    "displayName": "Quick Sort",
    "category": "logarithmic",
    "stable": false,
    "sizeRange": [16, 512],
    "timeComplexity": { "best": "O(n log n)", "average": "O(n log n)", "worst": "O(n²)" },
    "spaceComplexity": "O(log n)",
    "iconName": "quick",
    "confirmationWarning": null
}
```

Manifest, not JSDoc-comment parsing — it's trivially `Codable`, versionable, and validated at load
time instead of regex-scraped from comments.

### 2.4 Discovery — the actual "drop-in" mechanism

```swift
// Module: AlgorithmKit

@MainActor
final class AlgorithmRegistry {
    static let shared = AlgorithmRegistry()

    private(set) var algorithms: [any SortAlgorithm] = []

    func discover() {
        algorithms = builtIns   // the primary content path now (§2.6) — every proven algorithm lives here
        algorithms += loadScripts(from: Bundle.main.url(forResource: "Algorithms", withExtension: nil)!)
    }

    private func loadScripts(from directory: URL) -> [any SortAlgorithm] {
        // pair each *.js with its *.manifest.json, decode, wrap in JSAlgorithmAdapter,
        // skip + log any pair that fails manifest decoding or has a duplicate id
    }
}
```

Adding algorithm #17 becomes: **write one `.js` file and one `.json` manifest, drop them in
`Algorithms/`.** No Xcode project edit, no Tuist regeneration, no recompile, no touching
`Page.swift`'s 5 parallel switches. `ContentView`'s navigation becomes data-driven off
`AlgorithmRegistry.shared.algorithms` directly (§4.4) — a new algorithm shows up in the sidebar
automatically. Native `SortAlgorithm` conformances remain available for algorithms you specifically
want compiled (e.g. if you ever have a perf-sensitive showcase), added the old-fashioned way by
appending one array literal entry to `builtIns` — still a single touch point, not six.

### 2.5 Testing

Because native and scripted algorithms share one protocol and one tape output shape, one
parameterized test suite covers both:

```swift
for algorithm in AlgorithmRegistry.shared.algorithms {
    var engine = RecordingEngine(values: randomValues)
    algorithm.record(into: &engine)
    let (_, compares, swaps) = engine.finish()
    #expect(engine.values == randomValues.sorted())
}
```

This is the direct fix for the abandoned unit-testing attempt in `TODO.md` ("I tried doing unit
testing with a protocol and a separate implementation... it just failed over and over").

### 2.6 Native Swift is the target — JavaScript is a proving ground, not a destination

**Revised policy, as of the native-porting batch that shipped all 20 algorithms in
`BuiltInAlgorithms`.** The original policy here (quoted below for history) was "everything is
scripted, not a fallback," chosen to maximize authoring velocity for the "port everything from
ArrayV" goal — a script is trivial to generate en masse compared to hand-writing 189 Swift
`SortAlgorithm` conformances. That velocity argument still holds, but it traded away something the
original policy didn't account for: **on iOS, `JSContext` only ever gets JavaScriptCore's bytecode
interpreter — the JIT tiers are reserved for WebKit's own content process** — so every
`compare`/`swap` pays interpreter overhead *and* a per-call Objective-C bridge crossing
(`JSRecordingEngineExport` dynamic dispatch), on top of a fresh `JSContext` being constructed and
the script re-parsed on every single `record(into:)` call (§2.2's `JSAlgorithmAdapter` never caches
a compiled context across runs). Running the app for real exposed this as a genuinely slow
recording step, especially for the O(n log n) algorithms people run at the largest sizes.

The new policy: **native Swift, in `BuiltInAlgorithms`, is the target end state for every
algorithm and shuffle.** JavaScript keeps exactly one job — a fast, zero-recompile *proving ground*
for a brand-new algorithm's logic, before it's translated to native Swift and its script retired.
Concretely:
- `App/Resources/Algorithms/` is empty by default now, not because algorithms are scripted by
  default, but because nothing is *currently being prototyped* — it's the drop point for the next
  new algorithm's `.js` + manifest, exactly as described in §2.3/§2.4, until that algorithm is
  proven out and ported.
- `AlgorithmRegistry.builtIns` (§2.4) is where every proven algorithm actually lives now — the
  "escape hatch, not the primary content path" framing is inverted: `builtIns` is the primary path,
  `scriptLoader`'s discovery of `Algorithms/` is the temporary staging path.
- Everything else about the bridge (§2.1's App Store rationale, §2.2's mechanism, §2.3's
  script+manifest contract, §2.4's discovery, §2.5's shared test-suite shape) is unchanged and
  still real — a new algorithm still starts life exactly as described there. It just doesn't stay
  there once proven.

**Visualizations remain the deliberate, permanent exception** (§2A.3): `BuiltInVisualizers` is the
*only* location for `Visualizer` conformances, native-only from day one — there was never a
scripted stage for these, and there still isn't. There is no `Visualizations/*.js` bundle and no
`VisualizerRegistry` script-discovery step at all.

<details>
<summary>Original policy (superseded above, kept for history)</summary>

Per your decision: `.js` + manifest is the *default and primary* authoring path for **algorithms
and shuffles** — not a fallback for "the ones you didn't get around to compiling."
`BuiltInAlgorithms`/`BuiltInShuffles` exist only as escape hatches for the rare case JS genuinely
can't express (e.g. a concurrent sort that wants real OS threads — `JSContext` is single-threaded).
Concretely: they ship **empty** at launch. Every one of the ~16 current algorithms, and every
ArrayV algorithm/shuffle you port (§2A.6), is authored as a script from day one, including the ones
you happen to port first while bootstrapping the system. This maximizes the "port everything from
ArrayV" goal, since a script is trivial to generate en masse (by hand or by a one-off translation
pass) compared to hand-writing 189 Swift `SortAlgorithm` conformances.

</details>

---

## 2A. Modular visualizations (ArrayV-inspired) and scripted shuffles

The current app only ever draws one thing: vertical bars, height ∝ value. `~/ArrayV` (a mature,
prior-art Java sort visualizer) proves this doesn't need to be baked into the engine — it ships
**15 interchangeable visualization styles** (bars, circular fans, chord diagrams, spirals, scatter
plots, pixel meshes, stacked hoops...) that all render from the *same* underlying array + highlight
state, chosen independently of which algorithm is running. v2 adopts that separation directly: a
`Visualizer` is a second, orthogonal plugin axis alongside `SortAlgorithm` — protocol-based and
zero-project-edit to extend the same way algorithms are, but **native-only, not scripted** (§2A.3
explains why the "everything is scripted" policy in §2.6 deliberately stops at visualizations).

### 2A.1 The shape of the split

```
SortAlgorithm  →  Tape (values, marks, aux arrays)         "what happened, structurally"
Visualizer     →  Tape's current frame → [DrawCommand]     "how to draw what's happening right now"
```

A `Visualizer` never sees *how* the algorithm works — only `ReplayEngine`'s current, already-computed
frame (values + markers + aux arrays). This is a direct port of ArrayV's own separation:
`Visual.drawVisual(int[] array, ArrayVisualizer, Renderer, Highlights)` never touches `Sort`/`Reads`/
`Writes` — it only reads the array and the `Highlights` marker table, exactly like `VisualizationContext`
below only reads `ReplayEngine`'s `frame`/`auxArrays`.

### 2A.2 The `Visualizer` protocol

```swift
// Module: VisualizationKit — depends only on SortEngineKit (for Marker/AuxHandle's raw Int shape), no SwiftUI.

public struct RGBAColor: Sendable, Codable, Equatable {
    public var red, green, blue, alpha: Double
    /// ArrayV's `Visual.getIntColor`: derive a color purely from a value's position in the range —
    /// no per-element state to store, matches how most of the 15 ArrayV styles pick color.
    public static func hueRamp(_ position: Double) -> RGBAColor   // position ∈ 0...1
}

public enum DrawCommand: Sendable, Codable, Equatable {
    case rect(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
    case ellipse(x: Double, y: Double, width: Double, height: Double, color: RGBAColor)
    case line(x1: Double, y1: Double, x2: Double, y2: Double, color: RGBAColor, lineWidth: Double)
    case polygon(points: [SIMD2<Double>], color: RGBAColor)
    case text(x: Double, y: Double, string: String, color: RGBAColor)
}

public struct VisualizationContext: Sendable {
    public let values: [Int]                    // ReplayEngine.frame, unwrapped to raw ints
    public let valueRange: ClosedRange<Int>      // for normalizing height/hue/radius
    public let markers: [Int: Set<Int>]          // index -> marker IDs active on it (inverse of BarState.markers)
    public let auxArrays: [Int: [Int]]           // AuxHandle.rawValue -> contents, drawn as extra strips
    public let canvasSize: CGSize
    public let colorSeed: UInt64                 // == TapeHeader.visualSeed, for deterministic per-run color choices
}

public protocol Visualizer: Sendable {
    var id: VisualizerID { get }
    var metadata: VisualizerMetadata { get }     // displayName, supportsAuxArrays, iconName
    func draw(_ context: VisualizationContext) -> [DrawCommand]
}
```

Rendering `[DrawCommand]` natively is a straight `Canvas { context, size in ... }` loop
(`GraphicsContext.fill(Path(...), with: .color(...))` per case) — no retained scene graph, matching
ArrayV's own immediate-mode `Graphics2D` model exactly. `VisualizerRegistry.discover()` is simply
`visualizers = builtIns` — every `Visualizer` is a compiled-in `BuiltInVisualizers` conformance
(§2A.3), no runtime script discovery. The running `SortSession`/`ReplayEngine` is completely
unaware of which visualizer is active — `SortView` resolves the user's current pick (an
`AppSettings.selectedVisualizerID`, changeable mid-run, exactly like ArrayV's live style switcher)
and feeds it a fresh `VisualizationContext` every frame.

### 2A.3 Visualizations are native-only — deliberately, not by omission

Unlike algorithms and shuffles, **visualizations do not get a JS bridge.** This was considered and
rejected: a `Visualizer` only needs to be *pluggable*, not *scriptable* — those are different
things, and JS only buys you the second one at a cost not worth paying here.

The `DrawCommand`/`VisualizationContext` split (§2A.2) already gives you everything a plugin system
needs without an interpreter: `DrawCommand` is inert `Codable` data (a case, some doubles, a color),
not a view — `VisualizationCanvas`'s `Canvas { context, size in ... }` closure just `switch`es over
a `[DrawCommand]` and calls the matching `GraphicsContext.fill`/`.stroke`/`.draw(Text)` method. A
native `Visualizer.draw(_:)` conformance is a **pure, synchronous function from data to data** —
`(VisualizationContext) -> [DrawCommand]` — exactly as swappable/hot-loadable-in-spirit as a JS
function would have been, minus the interpreter, the per-frame watchdog, and the bridge plumbing.

The reason to actually avoid a JS visualization bridge, concretely: rendering ultimately has to
happen through `GraphicsContext`'s real drawing calls, which only exist as native Swift API — there
is no way to hand a JS script "a SwiftUI view" to mutate, and building some intermediate
scene-graph/dynamic-dispatch layer just so a script *could* describe drawing would mean
reimplementing a chunk of `GraphicsContext` badly, for a plugin axis where the "author it without
recompiling" benefit matters far less than it does for algorithms. Compare the two cases directly:
an algorithm is 100+ lines of nontrivial control flow that's genuinely nicer to drop in as a file;
a `Visualizer` is typically a 10–20 line loop over `context.values` emitting `.rect`/`.ellipse`
cases — there's little friction left for JS to remove, and removing the bridge removes an entire
category of runtime failure (timeouts, malformed scripts, bridge/context-conversion bugs) from the
one part of the system that runs every single frame.

**What you still get, without JS:** new visualizers are still zero-project-edit to add — they're
plain `.swift` files matched by `Modules/BuiltInVisualizers/Sources/**`'s glob (§0's `Module.framework`
helper), so dropping in `RainbowVisualizer.swift` needs a recompile but never a `Project.swift`
edit or `tuist generate`. `VisualizerRegistry.discover()` (§2A.5) is simply `visualizers = builtIns`
— there is no `Visualizations/*.js` bundle, no manifest format, no runtime discovery step to fail.

### 2A.4 Shuffles become tapes too

ArrayV treats shuffling as *just another algorithm* — it runs through the same `Reads`/`Writes`/
`Highlights` instrumentation a sort does, which is why "watch a fractal Sierpinski shuffle
un-scramble" is a real, working feature there. v2 adopts this directly instead of the current
`ShuffleMethod` being a plain, unrecorded `[Int] -> [Int]` function:

```swift
// Module: AlgorithmKit

public protocol ShuffleAlgorithm: Sendable {
    var id: ShuffleID { get }
    var metadata: ShuffleMetadata { get }
    func record(into engine: inout RecordingEngine)   // starts from a sorted/identity array, same primitive surface as SortAlgorithm
}
```

`TapeHeader` gains `public let shuffleID: String?`, and `SortSession.start(values:)` records the
shuffle's tape first (against `0..<n` identity values), then records the sort's tape against the
shuffle's *output*, and concatenates the two `[SortOperation]` arrays into one continuous `Tape`
before handing it to `ReplayEngine` — from the replay/UI's point of view a shuffle-then-sort is just
one longer tape with a marker in `TapeHeader` recording where the sort itself began (an
`operations.count` offset), no `ReplayEngine` changes needed. Shuffles are authored and discovered
exactly like algorithms (`.js` + manifest, `ShuffleRegistry`), so ArrayV's ~35 shuffles (structural
ones like `SIERPINSKI`/`GRAY_CODE`/`BST_TRAVERSAL`, adversarial worst-case generators like
`QSORT_BAD`) port over as scripts with zero new engine machinery.

### 2A.5 Module additions

`VisualizationKit` (protocol + `DrawCommand`/`VisualizationContext`, native `Canvas` renderer) and
`BuiltInVisualizers` (every actual `Visualizer` conformance — not an escape hatch, §2.6) slot into
the module graph as their own branch, with no `ScriptingKit` dependency; the shuffle half of
`AlgorithmKit`/`ScriptingKit` slots in alongside the existing algorithm plugin system — see the
updated table and diagram in §5.2/§6.

### 2A.6 Porting ArrayV content — realistic scope

**Algorithms** (~189 concrete classes across `exchange/`, `hybrid/`, `distribute/`, `select/`,
`concurrent/`, `insert/`, `merge/`, `misc/`, `quick/`): the overwhelming majority translate to a
`.js` script mechanically — `Reads.compareValues`/`compareIndices` → `engine.compare`,
`Writes.swap`/`write` → `engine.swap`/`setValue`, `Highlights.markArray`/`clearMark` →
`engine.mark`/`unmark`, `Writes.createExternalArray` → `engine.createAuxArray`. Two categories need
extra thought before porting:
- **`concurrent/` (23 files)**: these assume real OS threads (`Thread`/`ExecutorService` in Java).
  `JSContext` is single-threaded, so port these as *sequential simulations* of the same algorithmic
  idea (interleave the "threads'" work deterministically, tape-record the interleaving) rather than
  literal parallelism — or, since native Swift is the target for everything now anyway (§2.6), just
  write them directly as a `BuiltInAlgorithms` entry without a JS prototyping stage at all.
- **Bogo/Stooge/slowsort-style "Impractical Sorts"**: no special handling needed structurally (they
  use the same `Reads`/`Writes` calls as anything else) — just keep `AlgorithmMetadata.sizeRange`
  tight and `confirmationWarning` set (§3.4), same as v1's existing Bogo/Bitonic gate.
- ArrayV's **Groovy scripting/"Showcase" layer** (`groovyapi/`, batch playlist DSL) is an
  orchestration/demo-reel concern layered *on top of* algorithms, not part of the algorithm or
  visualization plugin surface itself — not part of this port; revisit only if you want a "watch N
  algorithms run in sequence" showcase mode later.

**Visualizations** (15 styles): 14 of the 15 port cleanly onto `VisualizationContext` as pure
functions of `values`/`markers`/`auxArrays` — BarGraph, Rainbow, SineWave, ColorCircle, Spiral,
ScatterPlot, WaveDots, SpiralDots, HoopStack, PixelMesh, a straightforward circular variant, and
**the whole Disparity family** (DisparityBarGraph/DisparityCircle/DisparityChords/DisparityDots).
An earlier version of this doc claimed the Disparity family needed a new
`VisualizationContext.originalIndices` field to track each value's "original/home index" — that was
wrong, caught only once someone actually read ArrayV's real source
(`visuals/{bars,circles,dots}/Disparity*.java`) instead of pattern-matching the
`sin(π(value - index)/n)`-shaped formula in ArrayV's own comments. `index` there is just the
ordinary current loop index into the current array — the exact same `values`/position data every
other `Visualizer` already receives — not a tracked start-of-run index. No engine feature was ever
needed; all four ship as ordinary `BuiltInVisualizers` conformances alongside the rest.
- **CustomImage** (user-supplied image, remapped per current permutation): deferred, the one
  genuine exception. It's the one ArrayV style that needs an asset-picker UI and per-pixel remap
  logic disproportionate to its value here — a good "phase 6+" nice-to-have
  (§ `IMPLEMENTATION_PLAN.md`), not a blocker for shipping the other 14.

**Stretch goal — teaching-mode step annotations**: your longer-term idea of visually indicating
*what a step means*, not just that it happened (e.g. "this compare decided the pivot side," "this
write is the merge's output pointer advancing") is a natural extension of this same architecture,
but is explicitly **deferred, not designed yet**. The natural seam for it later: an optional
`annotation: String?` (or a small enum of "step intents") riding alongside `SortOperation`, surfaced
by `Visualizer`s that opt in (e.g. as `DrawCommand.text` captions) — noted here so the `DrawCommand`/
`SortOperation` shapes above aren't accidentally designed in a way that forecloses adding it.

---

## 3. Decomposing `SortViewModel`

`SortViewModel`'s 432 lines and ~33 properties split into five single-purpose types. None of them
know about the others' internals; `SortSession` is the only thing that composes them.

| v1 (all in `SortViewModel`) | v2 | Module |
|---|---|---|
| `data`, `swap`/`compare`/`getValue`/`setValue`, 16 algorithm extensions | `RecordingEngine` + `SortAlgorithm` conformances | `SortEngineKit`, `AlgorithmKit` |
| `running`, `sortTaskRef`, `enforceRunning()` | `ReplayEngine.play/pause/stepForward/stepBackward/seek` (structured `Task` cancellation, no manual guards) | `SortEngineKit` |
| `let toner = Synthesizer()`, `playNote()` | `AudioService` (§3.1) | `AudioEngineKit` |
| CloudKit save inline in `doSort()`, `RunRecord`, `CloudKitRecordEncoder` | `AnalyticsService` (§3.2) | `PersistenceKit` |
| 9 `@AppStorage` properties, scattered string keys | `AppSettings` (§3.3) | `SettingsKit` |
| `showBogoSortWarning`/`bogoSortAccepted`/`showBitonicWarning`/etc. | `SortGate` enum (§3.4) | `SortEngineKit` |
| IOKit/DeviceKit `#if` block inline in `doSort()` | `DeviceInfoProvider` (tiny, one method, one call site: `AnalyticsService`) | `PersistenceKit` |
| Everything glued together | `SortSession` (§3.5) — the *only* type that owns instances of the above | `SortFeature` |

### 3.1 `AudioService`

```swift
// Module: AudioEngineKit

protocol AudioPlaying: Sendable {
    func start() throws
    func stop()
    func play(value: Int, in range: ClosedRange<Int>)
}

@MainActor
final class AudioService: AudioPlaying {
    private let engine = AudioEngine()      // AudioKit, unchanged from Synthesizer.swift
    private var osc: Oscillator
    private var env: AmplitudeEnvelope
    // ... existing Synthesizer.swift body, moved verbatim, just renamed and given a protocol
}
```

Crucially, `ReplayEngine.stepForward()` decides *whether* to call `audio.play(...)` based on
`AppSettings.soundEnabled`, and derives pitch from the **current frame's value**, not from
anything baked into the tape. This also fixes a real bug class: today, a fast algorithm at low
delay can outrun AudioKit's note-scheduling and glitch, because note-firing is woven into the
algorithm's own timing. In v2, notes fire at the replay engine's frame rate, which is the same
rate the bars visually update at, so audio and animation can never drift apart.

### 3.2 `AnalyticsService`

```swift
// Module: PersistenceKit

actor AnalyticsService {
    func record(_ tape: TapeHeader, algorithm: AlgorithmID, device: DeviceInfo) async throws {
        let summary = RunSummary(algorithmID: algorithm.rawValue, arraySize: tape.initialValues.count,
                                  compareCount: tape.compareCount, swapCount: tape.swapCount,
                                  recordingDuration: tape.recordingDuration, device: device, recordedAt: tape.recordedAt)
        try modelContext.insert(summary)   // SwiftData — replaces CloudKitRecordEncoder/Decoder entirely
        try modelContext.save()
    }
}
```

Resolves the standing `// FIXME: Migrate this to Swift Data instead of using a manual serializer.`
comment. `SortSession` calls this **after** `phase` transitions to `.complete` — never from inside
recording or replay, so the engine has zero knowledge that analytics exist at all. **CloudKit is
retained** (your decision, §9) — `AnalyticsService` pushes through SwiftData's
`NSPersistentCloudKitContainer` sync using the existing `iCloud.com.nhubbard.Sort2.mobile`
container, so `RunSummary` rows sync across your own devices. This is what actually realizes the
partially-built goal behind the current CloudKit code: comparing how the same algorithm performs
across different Apple devices/chips, driven by `DeviceInfoProvider` + `TapeHeader.recordingDuration`
already being device-tagged, per-run, structured data instead of a bespoke encoder.

### 3.3 `AppSettings`

```swift
// Module: SettingsKit

@Observable @MainActor
final class AppSettings {
    static let shared = AppSettings()

    var soundEnabled: Bool { didSet { store.set(soundEnabled, forKey: Keys.soundEnabled) } }
    var synthNoteRange: ClosedRange<Int> { didSet { persistRange() } }
    var playbackSpeed: Double { didSet { store.set(playbackSpeed, forKey: Keys.playbackSpeed) } }
    var defaultArraySize: Int { didSet { store.set(defaultArraySize, forKey: Keys.defaultArraySize) } }
    var shuffleMethod: ShuffleMethod { didSet { store.set(shuffleMethod.rawValue, forKey: Keys.shuffleMethod) } }
    var codeTheme: CodeThemeID { didSet { store.set(codeTheme.rawValue, forKey: Keys.codeTheme) } }
    var warnBeforeBogoSort: Bool { didSet { store.set(warnBeforeBogoSort, forKey: Keys.warnBogo) } }
    var warnBeforeBitonicSort: Bool { didSet { store.set(warnBeforeBitonicSort, forKey: Keys.warnBitonic) } }

    private enum Keys { static let soundEnabled = "soundEnabled"; /* ...the ONE place these strings exist... */ }
    private let store = UserDefaults.standard

    private init() {
        store.register(defaults: [Keys.soundEnabled: true, Keys.playbackSpeed: 30.0, /* ... */])
        soundEnabled = store.bool(forKey: Keys.soundEnabled)
        // ...
    }
}
```

`store.register(defaults:)` replaces the `"isConfigured"` sentinel-flag dance in `Sort2App.swift` —
it is idempotent by construction and needs no guard. `SettingsView`, `SortSession`, and
`ShuffleMethod.create(maximum:)` all take `AppSettings` as a dependency instead of independently
declaring `@AppStorage("sameStringLiteral")`.

### 3.4 The confirmation-dialog state machine — superseded, see §9

**Removed during Phase 8** in favor of unconditional `AlgorithmMetadata.sizeRange` clamping,
matching ArrayV's own `unreasonableLimit` precedent rather than v1's per-algorithm toggle design —
see the "Confirmation-dialog/warning-toggle system... removed, not built" bullet in §9. The section
below is left as-drafted for historical context; none of it exists in the codebase anymore.

Replaces `showBogoSortWarning`/`bogoSortAccepted`/`showBitonicWarning`/`shouldShowBitonicWarning`
and `SortView`'s `onBogoAccept`/`onBogoDecline`/`onBitonicAccept` handler family:

```swift
enum SortGate: Equatable {
    case clear
    case needsConfirmation(AlgorithmWarning)
    case declined
}

struct AlgorithmWarning: Equatable, Sendable {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
}
```

`AlgorithmMetadata.confirmationWarning` (§1.3/§2.3's manifest) drives this directly — Bogo Sort's
and Bitonic Sort's warnings become **data** (`confirmationWarning` in their manifest/metadata), not
bespoke per-algorithm boolean pairs. A new algorithm that also deserves a warning just sets that one
metadata field; no new `@Published` flags, no new view handler functions. The view collapses to one
`.confirmationDialog(item:)` modifier bound to `session.gate`.

### 3.5 `SortSession` — the orchestrator

```swift
// Module: SortFeature

@Observable @MainActor
final class SortSession {
    enum Phase {
        case idle
        case recording
        case ready(Tape)
        case replaying(ReplayEngine)
        case complete(ReplayEngine)
        case failed(SortSessionError)
    }

    private(set) var phase: Phase = .idle
    private(set) var gate: SortGate = .clear

    let algorithm: any SortAlgorithm
    private let audio: any AudioPlaying
    private let analytics: AnalyticsService
    private let settings: AppSettings

    init(algorithm: any SortAlgorithm, audio: any AudioPlaying, analytics: AnalyticsService, settings: AppSettings) {
        self.algorithm = algorithm; self.audio = audio; self.analytics = analytics; self.settings = settings
    }

    func start(values: [Int]) async {
        if let warning = algorithm.metadata.confirmationWarning, gate != .declined {
            gate = .needsConfirmation(warning); return
        }
        phase = .recording
        let tape = await Task.detached(priority: .userInitiated) {
            var engine = RecordingEngine(values: values)
            algorithm.record(into: &engine)
            let (ops, compares, swaps) = engine.finish()
            return Tape(header: .init(algorithmID: algorithm.id.rawValue, initialValues: values,
                                       visualSeed: .random(in: .min ... .max), compareCount: compares,
                                       swapCount: swaps, recordingDuration: /* measured */ 0, recordedAt: .now),
                        operations: ops)
        }.value
        phase = .ready(tape)
        startReplay(tape)
    }

    private func startReplay(_ tape: Tape) {
        let replay = ReplayEngine(tape: tape)
        phase = .replaying(replay)
        replay.play(operationsPerSecond: settings.playbackSpeed)
        Task {
            // observe replay completion, then:
            phase = .complete(replay)
            try? await analytics.record(tape.header, algorithm: algorithm.id, device: DeviceInfoProvider.current())
        }
    }
}
```

Note the ordering: **analytics is written after replay completes, driven by `phase`, entirely
outside the recording/replay call stack.** This is the structural fix for "CloudKit save hardcoded
inside `doSort()`."

Each algorithm page constructs its **own** `SortSession` (matching today's "each `SortView` gets
its own `SortViewModel`" behavior, just done cleanly via `@State` — see §4). There is no shared
global sort state, so navigating away and back naturally resets, exactly like today.

---

## 4. The reactive SwiftUI layer

### 4.1 What changes and why it will actually work this time

Every `@Observable` type introduced above (`ReplayEngine`, `SortSession`, `AppSettings`) mutates
its observed state from exactly one place: a `@MainActor` method, one property (or one atomically-
replaced array) at a time, never concurrently with a reader. That is the precondition `@Observable`
requires and the v1 `SortViewModel` violated. There is no remaining reason `@Observable` would
break in v2 — the architecture was the actual blocker, not the macro.

### 4.2 View ownership pattern

```swift
struct ScrollingSortView: View {
    let entry: AlgorithmRegistry.Entry
    @Environment(AppSettings.self) private var settings
    @Environment(AudioService.self) private var audio
    @State private var session: SortSession

    init(entry: AlgorithmRegistry.Entry) {
        self.entry = entry
        _session = State(wrappedValue: SortSession(algorithm: entry.algorithm, audio: audio, /* ... */))
    }

    var body: some View {
        SortView(session: session)
        AlgorithmDetailSection(entry: entry)   // description/complexity/code samples — unchanged resource-bundle loading
    }
}

struct SortView: View {
    @Bindable var session: SortSession
    @Environment(AppSettings.self) private var settings   // holds selectedVisualizerID (§2A.2)

    var body: some View {
        switch session.phase {
        case .replaying(let replay), .complete(let replay):
            VisualizationCanvas(replay: replay, visualizer: VisualizerRegistry.shared.current)
        default:
            ProgressView()
        }
    }
    .confirmationDialog(item: /* binding derived from session.gate */) { warning in /* Accept/Decline */ }
}

/// Replaces the hardcoded `BarLayout`/`Bar` pair: one `Canvas` that asks whichever `Visualizer`
/// is currently selected (§2A) to turn the replay's current frame into draw commands. Switching
/// styles mid-run (matching ArrayV's live style switcher) is just changing which `Visualizer`
/// this reads — `ReplayEngine`/`SortSession` are completely unaware a style even exists.
struct VisualizationCanvas: View {
    let replay: ReplayEngine
    let visualizer: any Visualizer

    var body: some View {
        Canvas { context, size in
            let ctx = VisualizationContext(
                values: replay.frame.map(\.value), valueRange: 0...replay.frame.count,
                markers: /* invert BarState.markers into index->markers */ [:],
                auxArrays: replay.auxArrays, canvasSize: size,
                colorSeed: /* tape.header.visualSeed, threaded down from SortSession */ 0)
            for command in visualizer.draw(ctx) { context.draw(command) }   // one switch over DrawCommand cases
        }
    }
}
```

- `@Environment(Type.self)` (the `@Observable`-flavored environment injection) replaces
  `@EnvironmentObject` everywhere — `AppSettings.shared` and `AudioService` are injected once at
  the app root (`.environment(AppSettings.shared)` in `Sort2App`), not re-declared per view.
- `@State private var session: SortSession` replaces `@StateObject var state: SortViewModel = SortViewModel()`
  — `@Observable` reference types work directly with `@State` since iOS 17; no `ObservableObject`
  conformance needed anywhere in the app.
- `@Bindable var session: SortSession` is used exactly where two-way bindings are needed (e.g. a
  `Slider` for array size before a run starts), replacing the current pattern of `SortView` directly
  mutating `state.*` from a dozen `onXxx()` functions.
- `SortView` stops being its own controller: it renders `session.phase` and forwards user intents
  (`session.start(values:)`, `session.pause()`) — it no longer owns `Task` handles
  (`sortTaskRef`/`recreateTaskRef` disappear; `ReplayEngine` owns exactly one `playbackTask`).

### 4.3 Data model split

```swift
// SortEngineKit — pure model, no Color, no CGFloat
public struct SortValue: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var value: Int
}
```

`SortItem.width: CGFloat` (currently present, apparently dead — bars are sized from
`GeometryProxy`/`BarLayout`, not from this field) is dropped entirely. Presentation state
(`ReplayEngine.BarState.accent`/`isSorted`) lives only in the replay layer; the model never imports
SwiftUI.

### 4.4 Data-driven navigation

```swift
struct ContentView: View {
    @State private var selection: AlgorithmID?
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Home") { NavigationLink("Home", value: AlgorithmID.home) }
                ForEach(AlgorithmCategory.allCases) { category in
                    Section(category.displayName) {
                        ForEach(AlgorithmRegistry.shared.algorithms(in: category)) { algo in
                            NavigationLink(algo.metadata.displayName, value: algo.id)
                        }
                    }
                }
            }
        } detail: {
            if let selection { ScrollingSortView(entry: AlgorithmRegistry.shared.entry(for: selection)) }
        }
    }
}
```

`Page.swift`'s 5 parallel hand-maintained switches (`algorithm`, `displayName`, `iconName`, plus
`ContentView`'s detail switch and `SortViewModel.doSort()`'s dispatch switch) collapse to zero —
navigation is generated directly from whatever `AlgorithmRegistry` discovered. This is what makes
the JS plugin system's "drop a file in a folder" promise actually true end-to-end: the sidebar,
not just the sort logic, updates automatically.

---

## 5. Tuist module graph

### 5.1 Why the current WIP Tuist config doesn't work

The existing `Project.swift`/`xcconfigs/` scaffolding creates **one Tuist framework target per
algorithm** (`QuickSortPlugin`, `MergeSortPlugin`, `HeapSortPlugin`, each with its own
`.xcconfig`, its own test target, its own scheme). Scaled to 16+ algorithms this is 16+ framework
targets, 32+ xcconfig files, 16+ test targets — enormous ceremony for what is, per algorithm, often
under 60 lines of logic. It also never solved the "no recompile" goal, since a new framework target
still requires a `Project.swift` edit and `tuist generate`.

v2 replaces per-algorithm Tuist targets with the JS plugin system (§2) for extensibility, and uses
Tuist purely for **coarse-grained architectural modules** — the boundaries that are stable and
rarely change, unlike "one more sorting algorithm."

### 5.2 Module list

| Module | Contents | Depends on |
|---|---|---|
| `SortEngineKit` | `SortOperation`, `Marker`, `AuxHandle`, `Tape`, `RecordingEngine`, `ReplayEngine`, `SortValue`, `SortGate` | (none — Foundation only) |
| `AlgorithmKit` | `SortAlgorithm`, `ShuffleAlgorithm` (§2A.4), metadata types, `AlgorithmID`/`ShuffleID`, `AlgorithmRegistry`/`ShuffleRegistry` | `SortEngineKit` |
| `VisualizationKit` *(new, §2A)* | `Visualizer` protocol, `DrawCommand`, `VisualizationContext`, `VisualizerID`/`VisualizerMetadata`, `VisualizerRegistry`, native `Canvas`-based `VisualizationCanvas` renderer | `SortEngineKit` |
| `ScriptingKit` | `JSRecordingEngineBridge`/`JSAlgorithmAdapter` (§2.2), manifest decoding, execution-time watchdog — **algorithms and shuffles only**, no visualization bridge (§2A.3) | `AlgorithmKit`, `JavaScriptCore` |
| `BuiltInAlgorithms` | Native `SortAlgorithm`/`ShuffleAlgorithm` conformances — **the target for every algorithm** (§2.6, revised); `Algorithms/`'s scripts are a temporary proving ground, not a permanent home | `AlgorithmKit` |
| `BuiltInVisualizers` *(new)* | Native `Visualizer` conformances — **every** visualization lives here (§2.6); not an escape hatch, the primary and only location | `VisualizationKit` |
| `AudioEngineKit` | `AudioService`, `AudioPlaying` | AudioKit family (SPM) |
| `PersistenceKit` | `RunSummary` (SwiftData + CloudKit sync, retained per §9), `AnalyticsService`, `DeviceInfoProvider` | SwiftData, CloudKit |
| `SettingsKit` | `AppSettings` (incl. `selectedVisualizerID`), typed key namespace | (none) |
| `DesignSystemKit` | `CodeTheme` + themes, `CustomIconLabel`, `RandomizingHeader`, `StateToggle`, `TouchBarSlider`, the Liquid Glass button/slider styles from the current refactor | (none) |
| `MathRenderingKit` | `SwiftMathView` (`IosMathView+UIKit`/`+AppKit` wrappers) | SwiftMath (SPM) |
| `SortFeature` | `SortSession`, `SortView`, `VisualizationCanvas`, `ScrollingSortView` | `SortEngineKit`, `AlgorithmKit`, `VisualizationKit`, `AudioEngineKit`, `SettingsKit`, `DesignSystemKit` |
| `SettingsFeature` | `SettingsView` (incl. visualizer picker) | `SettingsKit`, `VisualizationKit`, `AudioEngineKit`, `DesignSystemKit` |
| `HomeFeature` | `HomeView`, About/Credits | `DesignSystemKit` |
| `BenchmarkFeature` *(new — realizes the Swift Charts item in `TODO.md`)* | Off-screen batch recording + Charts, cross-device comparison view over `AnalyticsService` (§9) | `SortEngineKit`, `AlgorithmKit`, `PersistenceKit` |
| `Sort Symphony` (app target) | `Sort2App`, `ContentView`, environment wiring, entitlements/Info.plist | all feature modules |

Dependency direction is strictly acyclic and matches the numbered sections above: engine → algorithm
→ (scripting | built-ins), engine → visualization → built-ins (no scripting branch — §2A.3),
independently alongside audio/persistence/settings/design-system, with feature modules assembling
those, and the app target assembling features. `SortEngineKit`, `AlgorithmKit`, and
`VisualizationKit` have **zero** dependency on SwiftUI/AudioKit/SwiftData — they're the most-tested,
least-churned layer, exactly where you want the stability.

### 5.3 Structure and DRY-ness

Recommendation: **one `Project.swift`, many targets**, not a multi-project Tuist workspace. At this
project's scale (one app, ~14 internal modules, one developer) a full multi-project workspace mostly
adds `tuist generate` overhead without the incremental-build wins it's designed for at larger team
sizes; you can graduate to it later if module count or build times justify it.

Replace the current `xcconfigs/*.xcconfig`-per-target pattern with a single helper:

```swift
// Tuist/ProjectDescriptionHelpers/Module.swift
public enum Module {
    public static func framework(
        name: String,
        destinations: Destinations = [.iPhone, .iPad, .macCatalyst],
        dependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil
    ) -> [Target] {
        [
            .target(name: name, destinations: destinations, product: .framework,
                    bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased())",
                    sources: ["Modules/\(name)/Sources/**"], resources: resources,
                    dependencies: dependencies, settings: .settings(base: Self.baseSettings)),
            .target(name: "\(name)Tests", destinations: destinations, product: .unitTests,
                    bundleId: "com.nhubbard.Sort2.mobile.modules.\(name.lowercased()).tests",
                    sources: ["Modules/\(name)/Tests/**"], dependencies: [.target(name: name)]),
        ]
    }
    private static let baseSettings: SettingsDictionary = [ /* the handful of shared build settings that used to be duplicated across every xcconfig */ ]
}
```

Each module's contribution to `Project.swift` becomes one line:
`targets += Module.framework(name: "SortEngineKit")`,
`targets += Module.framework(name: "AlgorithmKit", dependencies: [.target(name: "SortEngineKit")])`,
etc. — 32 hand-written xcconfig files collapse to one helper function and, if you still want
per-module overrides, a two-file `Base.xcconfig`/`Release.xcconfig` pair referenced once from the
helper rather than duplicated per target.

`Tuist/Package.swift` keeps its role of pinning external SPM dependencies (AudioKit family,
`SwiftMath`, `DeviceKit`, `MarkdownUI`, `swift-algorithms`); `swift-atomics`/`ManagedAtomic` is very
likely removable in v2 since operation counting moves to a plain `Int` inside the (single-threaded,
synchronous) `RecordingEngine` — there's no concurrent writer left to protect against.

---

## 6. Full v2 dependency graph

```
                                    SortEngineKit
                     (Tape, Marker, AuxHandle, RecordingEngine, ReplayEngine, SortGate)
                               │                          │
                         AlgorithmKit               VisualizationKit
              (SortAlgorithm, ShuffleAlgorithm)   (Visualizer, DrawCommand)
                  │              │                          │
           ScriptingKit    BuiltInAlgorithms          BuiltInVisualizers
       (proving ground —   (target for every       (every visualizer lives here — §2.6)
        empty until a new   algorithm — §2.6,
        algorithm is being     revised)
        prototyped)
                       └──────┬───────┘                     │
                              │                              │
                              └──────────────┬───────────────┘
                                              │
   AudioEngineKit    SettingsKit    PersistenceKit    DesignSystemKit    MathRenderingKit
   (AudioService)   (AppSettings)  (AnalyticsService)  (themes, controls)  (SwiftMathView)
        └────────────────┴──────────────┴────────────────┴──────────────────┘
                              │
                 ┌────────────┼─────────────┬───────────────┐
             SortFeature  SettingsFeature  HomeFeature  BenchmarkFeature
                              │
                     Sort Symphony (app target)
                (Sort2App, ContentView, environment wiring)

Algorithms/*.js + *.manifest.json        ──discovered at runtime──▶  AlgorithmRegistry
Shuffles/*.js + *.manifest.json          ──discovered at runtime──▶  ShuffleRegistry
(visualizations are plain .swift files in BuiltInVisualizers — compiled in, no runtime discovery,
 no manifest, no project edit needed to add one — §2A.3)
```

---

## 7. Testing strategy

- **Algorithms** (native or scripted): one parameterized suite runs every `AlgorithmRegistry` entry
  through `RecordingEngine`, asserts sortedness and reasonable compare/swap counts. This is the
  direct, working replacement for the abandoned "protocol + separate test-target implementation"
  attempt in `TODO.md` — it works now because `RecordingEngine` is a plain synchronous struct with
  no `@MainActor`/`ObservableObject` entanglement to fight with a test target.
- **`ReplayEngine`**: assert `frame` after N `stepForward()` calls matches the array state a
  reference (e.g. `Array.sorted()`-based) implementation would produce at the same operation index;
  assert `seek(to:)` and seeking-then-stepping agree.
- **`JSAlgorithmAdapter`** (algorithms and shuffles; no visualization equivalent, §2A.3): the bridge
  itself (§2.2) stays exercised even though every shipped algorithm is native now (§2.6, revised) —
  keep exactly one algorithm as a permanent **test-only** native fixture (never shipped in
  `BuiltInAlgorithms`) purely so the bridge has a known-correct reference to diff against — run the
  native fixture and its JS-authored twin through identical input and assert identical tapes. This
  is a bridge-correctness check, proving the proving-ground path (§2.6) still works for whatever
  algorithm gets prototyped there next, not a claim that native and JS versions both ship.
- **`Visualizer`**: plain unit tests per conformance — feed a hand-built `VisualizationContext` in,
  assert the expected `[DrawCommand]` out. No bridge, no timeout case, no manifest to validate —
  it's ordinary pure-function testing (§2A.3).
- **Manifest loading**: malformed/missing manifest, duplicate `id`, and execution-timeout scripts
  (the algorithm/shuffle per-run watchdog, §2.2) each get a dedicated test asserting a clean
  `.failed` state rather than a crash.
- **UI**: with `SortSession`/`ReplayEngine` fully decoupled from SwiftUI, snapshot/interaction tests
  against `SortView` no longer need a live algorithm run — seed a `ReplayEngine` directly from a
  hand-built `Tape` fixture.

---

## 8. Migration plan

Superseded by **`IMPLEMENTATION_PLAN.md`**, which sequences the build Tuist-first (the module
graph in §5/§6 exists from day one, not as a late-stage refactor) and phases in the engine,
scripted algorithms, native visualizations, ArrayV content porting, feature-module SwiftUI
migration, and persistence in that order, each with a concrete file list and completion checkpoint.
This section intentionally no longer duplicates that ordering.

---

## 9. Resolved decisions

The following were open questions in an earlier draft of this document; all five are now decided.

- **macOS target shape — Mac Catalyst, not native AppKit.** Deliberately kept, not a default-by-
  omission: `NSSlider` draws a visible tick-mark line for *every step* when a stepped slider is
  used (a real, previously-encountered visual defect with the app's speed/size sliders), and Mac
  Catalyst doesn't have this problem. Catalyst's other rough edges are a known, accepted tradeoff
  against that specific AppKit regression. `Module.framework`'s `destinations` default stays
  `[.iPhone, .iPad, .macCatalyst]`; no true native macOS destination is planned.
- **How many algorithms/shuffles stay native vs. move to JS — revised: every shipped algorithm
  goes native eventually; JS is a temporary proving-ground stage, not a permanent home.** See
  §2.6 (revised) — the original "scripted by default, as many as possible" answer optimized for
  authoring velocity while porting all of ArrayV, but running the app for real exposed JS-on-iOS's
  lack of a JIT as a genuine recording-speed cost. Every visualization is, and always was, a native
  `Visualizer` conformance regardless (a JS bridge for drawing was considered and rejected — see
  §2A.3 — since it would require either reimplementing `GraphicsContext` for scripts to target, or
  some dynamic-dispatch scene-graph layer over SwiftUI, for a plugin axis simple enough that native
  Swift is already about as easy to author as a script would be). §2A.6 flags the handful of
  algorithms — mainly `concurrent/` — that may need a native escape hatch instead.
- **CloudKit — retained.** Not just "keep the current feature": it's the partial implementation of
  a specific plan to compare how the same algorithm performs across different Apple devices, so
  `AnalyticsService` (§3.2) is built around that goal directly (device-tagged `RunSummary` rows,
  synced via the existing `iCloud.com.nhubbard.Sort2.mobile` container) rather than treated as
  optional.
- **Downloadable algorithm packs — no, not for now.** Bundled-only (§2.1, §2.4): no
  `applicationSupportAlgorithmsDirectory`, no manifest-signing/trust design needed. Revisit only if
  a concrete reason to distribute content outside the app bundle shows up later.
- **Tuist structure — single project, many targets.** Confirmed per §5.3: a multi-project Tuist
  workspace is unnecessary ceremony at this scale and for a single developer; the `Module.framework`
  helper is the whole story.
- **Confirmation-dialog/warning-toggle system (§3.4, as originally drafted) — removed, not built.**
  `SortGate.needsConfirmation`/`AlgorithmWarning`/`AlgorithmMetadata.confirmationWarning` and
  `SortView`'s `.confirmationDialog` existed briefly (built ahead of the phase that was meant to
  finalize them) as a direct copy of v1's bespoke `showBogoSortWarning`/`showBitonicWarning` boolean
  pairs, generalized into one metadata field plus a settings toggle per warning-worthy algorithm.
  Checking ArrayV's own solution (`~/ArrayV`'s `Sort.java`/`RunSort.java`) turned up something
  simpler: no per-algorithm settings toggle at all, just an `unreasonableLimit` int per sort (`0` =
  none; e.g. BogoSort's is `10`) that the runner compares against the *currently selected* array
  size. `AlgorithmMetadata.sizeRange.upperBound` already does this job — Bogo Sort is already
  clamped to `[4, 16]` — just enforced unconditionally by `SortSession.start(size:)` rather than
  warned-past. Removing the dialog/toggle system entirely avoids both v1's leftover complexity and a
  hypothetical future need for scripts/settings to interact just to support two algorithms out of
  hundreds.

**Noted stretch goal, explicitly deferred (not designed):** visually indicating what each
algorithmic step *means* as a teaching tool (e.g. captioning "this compare decided the pivot side"),
beyond just animating that a step happened. §2A.6 leaves a seam for this (an optional annotation
riding on `SortOperation`, surfaced by opt-in `Visualizer`s) without committing to a design now.
