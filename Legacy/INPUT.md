## Architectural Anti-Patterns in Sort Symphony

Here is a detailed breakdown of the architectural antipatterns present, organized from most to least severe:

### 1. **Massively Bloated God Object — `SortViewModel`

`SortViewModel` is the single worst offender. It combines, in one class:

- All **UI state** (alert flags like `showBogoSortWarning`, `showDelayPopup`, `showBitonicWarning`, `showSoundError`, etc.)
- All **sorting primitives** (`swap`, `compare`, `getValue`, `setValue`, `changeColor`, etc.)
- **Audio engine** lifecycle (`toner`, sound error state)
- **CloudKit benchmarking** (writing `RunRecord` to the public database directly inside `doSort()`)
- **Timing/formatting** (`DateComponentsFormatter`, `NumberFormatter`, `getRunTime()`)
- **Platform detection** (IOKit vs. DeviceKit `#if` branches mid-method)
- **Atomic concurrency primitives** (`ManagedAtomic<Int>`)

This violates the Single Responsibility Principle so thoroughly that every concern in the app flows through one object. Adding a new algorithm, changing the persistence layer, or swapping audio backends all require touching the same class.

---

### 2. **`@Published` for Non-Observable State / Abuse of `@Published`**

`ManagedAtomic<Int>` is published:

```swift
@Published public var operations: ManagedAtomic<Int> = ManagedAtomic(0)
```

`ManagedAtomic` is not itself `ObservableObject`-aware — it does not emit change signals when its inner value changes. Publishing the *wrapper object* rather than the integer value means SwiftUI never actually re-renders on counter changes, which is both semantically wrong and forces the awkward `getOperations()` polling pattern rather than clean reactive binding.

Additionally, `startTime: CFAbsoluteTime` is published, even though `CFAbsoluteTime` is just a `Double` alias, and it changes on every sort start — this is a raw C type being used inside a reactive SwiftUI system.

---

### 3. **Business Logic and Persistence Hardcoded into `doSort()`**

The `doSort()` method directly embeds a CloudKit save inside the sort completion path:

```swift
try await CKContainer.default().publicCloudDatabase.save(
    try CloudKitRecordEncoder().encode(RunRecord(...))
)
```

A sort algorithm executor should have no knowledge of analytics, persistence, or network I/O. This makes testing impossible and violates separation of concerns. There is even a `// FIXME: Migrate this to Swift Data` comment acknowledging this debt but left unresolved.

### 4. **Platform Detection Scattered Throughout Business Logic**

`#if !os(macOS)` and `#if targetEnvironment(macCatalyst)` guards appear *inside* `SortViewModel.doSort()` and `Sort2App.body`, not in platform-specific files or abstractions. The IOKit/DeviceKit model-identifier lookup is embedded inline in the sort completion handler. This pattern will compound painfully as the app grows.

The `iOS/` and `macOS/` folders exist (suggesting you understood platform splits), but the logic that most needs it lives in `Shared/`.

---

### 5. **Settings as a Bag of Stringly-Typed `UserDefaults` Keys**

`UserDefaults` keys are duplicated string literals scattered across the entire codebase:
- `SortViewModel` accesses `"sortSoundOn"`, `"sortDelay"`, `"synthLowNote"`, `"synthHighNote"`, etc. via `@AppStorage`
- `SettingsView` independently declares `@AppStorage` for the same keys
- `Sort2App` initializes defaults by calling `UserDefaults.standard.setValue(...)` with the same raw strings again
- `ShuffleMethod.create(...)` reads `UserDefaults.standard.integer(forKey: "sortShuffleMethod")` directly

There is no central `AppSettings` struct, enum namespace, or type-safe wrapper. A typo in any one of those string keys produces a silent bug.

---

### 6. **View Contains Event-Handling Business Logic (`SortView`)**

`SortView` is responsible for:

- Spawning and cancelling `Task` references (`sortTaskRef`, `recreateTaskRef`)
- Routing UI events through a large set of `onXxx()` functions (`onRunning`, `onBogoAccept`, `onBogoDecline`, `onBitonicAccept`, `onArraySizeChange`, etc.)
- Directly mutating `state.*` properties

In SwiftUI best practice, views should describe appearance and delegate *intent* to a view model or store. Instead, `SortView` is acting as its own controller. The state machine for BogoSort alone (`showBogoSortWarning → bogoSortAccepted → running → sortTaskRef.cancel()`) is entirely hand-rolled inside the view.

---

### 7. **Free Functions as Module-Level "Services"**

`ScrollingSortView.swift` contains three `@MainActor` free functions — `loadResource`, `loadHighlightResource`, and `loadComplexityResource` — as module-level globals. These are effectively a static service that knows how to load from the `AlgorithmRegistry` and the filesystem. There is no reason they couldn't be a `ResourceLoader` struct or a method on a dedicated type; as globals they are untestable, undiscoverable, and ambiguously scoped.

---

### 8. **Plugin System Bridging Through `NSObject` and `NSClassFromString`**

The `PluginLoader` manually loads framework bundles, looks up the principal class via `NSClassFromString` with string-concatenated module-prefixed names, casts to `NSObject.Type`, calls `init()`, then tries to cast to `AlgorithmPlugin`. This is Objective-C runtime dynamism in a codebase that is otherwise pure Swift. Swift has proper module/type systems (`@_exported import`, `@_silgen_name`, or static registration patterns) that could avoid this entirely. The approach is also fragile — the `"SortAlgorithmCore"` exclusion is a hardcoded string, and any framework naming mismatch silently no-ops.

---

### 9. **`SortItem` Includes Layout Data (`width: CGFloat`)**

```swift
public var width: CGFloat = 0
```

`SortItem` is the core data model, yet it carries a `CGFloat width` property that belongs to the rendering layer. Model types should be agnostic of how they are displayed. This property appears to be unused in the current rendering path (bars are sized from `GeometryProxy` in `SortView`), making it dead weight that signals the model/view boundary was not well-defined early on.

---

### 10. **`enforceRunning()` / `enforceIndex()` Used Inconsistently**

Most operations guard with `await enforceRunning()`, but some paths bypass it deliberately with comments like *"Don't change to await enforceRunning(); will break reset function."* This means the enforcement contract is not actually enforced — callers must know which functions are guarded and which aren't, and why. The workaround comment is a red flag that the state machine governing `running` and task cancellation is not well-modeled.

---

### 11. **Default Initialization in `Sort2App` Instead of `registerDefaults`**

```swift
if !UserDefaults.standard.bool(forKey: "isConfigured") {
    UserDefaults.standard.setValue(36, forKey: "synthLowNote")
    ...
}
```

`UserDefaults.standard.register(defaults:)` exists precisely to establish default values without conditional logic or a guard key. The current approach uses a sentinel key `"isConfigured"` to emulate what the framework already provides, and it runs *every launch* to check the flag.

---

### Summary Table

| Anti-Pattern                            | Severity    | Primary Location    |
|-----------------------------------------|-------------|---------------------|
| God Object                              | 🔴 Critical | `SortViewModel`     |
| Persistence in Algorithm Executor       | 🔴 Critical | `doSort()`          |
| Stringly-Typed Settings Keys            | 🟠 High     | App-wide            |
| View as Controller                      | 🟠 High     | `SortView`          |
| `@Published ManagedAtomic`              | 🟠 High     | `SortViewModel`     |
| Platform Logic in Shared Business Logic | 🟠 High     | `doSort()`          |
| NSObject Plugin Bridge                  | 🟡 Medium   | `PluginLoader`      |
| Free Function "Services"                | 🟡 Medium   | `ScrollingSortView` |
| Model Carrying Layout Data              | 🟡 Medium   | `SortItem.width`    |
| Inconsistent Guard Contract             | 🟡 Medium   | `enforceRunning()`  |
| Manual Default Registration             | 🟢 Low      | `Sort2App`          |

Given this was built over four years with no prior Swift experience, the codebase is actually quite coherent and shows genuine evolution — the plugin system, the protocol abstraction (`SortViewModelProtocol`), the `AlgorithmRegistry`, and the use of Swift Concurrency throughout are all evidence of a developer who progressively learned and applied better patterns. The anti-patterns above are mostly the residue of early decisions that were never fully refactored away.

> I would love to use the proper `@Observable` pattern, but unfortunately, the whole system stopped working when I did that. What would you do to improve the codebase in a rewrite, like a v2?
Let me do a thorough read of the remaining files I haven't seen yet before giving architectural advice.

Now I have a complete picture of the entire codebase. Here is a thorough, concrete v2 design recommendation.

---

## What I Would Do in a v2 Rewrite

The fundamental reason `@Observable` broke everything is rooted in a single architectural decision from day one: **the sort algorithms run as `async` mutations directly on the view model's own `data` array while SwiftUI is simultaneously reading that same array to render bars.** `ObservableObject` with `@Published` hides this with Combine's CoW-friendly batching. `@Observable` makes every property access a direct read/write through the observation registrar, and concurrent structural mutations of an array that a view is actively iterating is a data race, full stop. So the fix isn't "make `@Observable` work" — it's redesigning the concurrency model so `@Observable` is the natural, obvious choice.

Here's the layer-by-layer design:

---

### 1. Separate the Sort Engine from the ViewModel entirely

The root problem is that `SortViewModel` **is** the engine. It owns the data, runs the algorithm, plays audio, and talks to CloudKit, all at once. In v2, the engine becomes its own isolated actor:

```swift
// The engine is an actor - it owns the array exclusively.
// No view ever touches this directly.
actor SortEngine {
    private var items: [SortItem]
    private var running: Bool = false
    private var operationCount: Int = 0
    private var currentTask: Task<Bool, Never>?

    // All mutations happen here, in isolation.
    // Algorithms call into this actor via the protocol.
    func swap(_ i: Int, _ j: Int) { ... }
    func compare(_ i: Int, _ j: Int, by: ...) -> Bool { ... }

    // The engine publishes a *snapshot* for the view to render.
    // This is the only crossing point.
    func snapshot() -> SortSnapshot { ... }
}
```

The view model becomes a pure **coordinator** that drives the engine and projects snapshots into the UI:

```swift
@Observable
@MainActor
final class SortCoordinator {
    // Read-only from the view's perspective.
    // Updated via a stream of snapshots from the engine.
    private(set) var snapshot: SortSnapshot = .empty
    private(set) var stats: SortStats = .zero
    var isRunning: Bool = false

    private let engine: SortEngine
    private let analytics: AnalyticsService    // injected
    private let audio: AudioService            // injected

    func start() async { ... }
    func stop() { ... }
    func reset() async { ... }
}
```

The view only ever sees `SortSnapshot` — a value type, immutable, safe to hand to SwiftUI's diffing engine at any time. `@Observable` works perfectly here because `snapshot` is only ever *replaced as a whole*, not mutated element-by-element while being read.

---

### 2. The Snapshot Pattern — why `@Observable` failed, and how to fix it

`@Observable` failed because the sort loop does things like this thousands of times per second:

```swift
data[i].color = .red    // mutation #1
data[j].color = .orange // mutation #2
data.swapAt(i, j)       // mutation #3
data[i].color = .white  // mutation #4
```

Each of those lines fires observation notifications. SwiftUI sees the first one, starts computing a new body, and the array is already different by the time the body function reads it. With `@Observable` this is a guaranteed data race.

The fix is a **double-buffer / snapshot pattern**:

```swift
struct SortSnapshot: Equatable {
    let items: [BarDescriptor]   // value type, not SortItem
    let operationCount: Int
    let elapsedTime: TimeInterval

    static let empty = SortSnapshot(items: [], operationCount: 0, elapsedTime: 0)
}

struct BarDescriptor: Identifiable, Equatable {
    let id: UUID
    let heightFraction: Double   // pre-computed, 0.0...1.0
    let color: Color
}
```

The engine accumulates all mutations for one "step" in its private buffer, then publishes a single atomic snapshot at the end of that step. The coordinator receives it on the main actor:

```swift
actor SortEngine {
    private var buffer: [SortItem] = []

    // Called by algorithm after every logical "step"
    private func publishSnapshot() async {
        let snap = makeSnapshot(from: buffer)
        await coordinator.applySnapshot(snap)   // one hop to main actor
    }
}
```

SwiftUI now sees `snapshot` change as an atomic whole. `@Observable` fires once per step, not once per array element mutation. The render is always consistent.

---

### 3. Settings as a Type-Safe, Observable Store

Replace every `@AppStorage("stringly-typed-key")` scattered across a dozen files with a single settings store:

```swift
@Observable
@MainActor
final class AppSettings {
    // Persisted - but the keys are owned here and nowhere else
    var synthLowNote: Int          { didSet { persist() } }
    var synthHighNote: Int         { didSet { persist() } }
    var delay: Float               { didSet { persist() } }
    var arraySize: Int             { didSet { persist() } }
    var soundEnabled: Bool         { didSet { persist() } }
    var shuffleMethod: ShuffleMethod { didSet { persist() } }
    var codeTheme: CodeTheme       { didSet { persist() } }
    var warnBogo: Bool             { didSet { persist() } }
    var warnBitonic: Bool          { didSet { persist() } }

    static let shared = AppSettings()

    private let store = UserDefaults.standard

    private init() {
        // Register defaults ONCE, the correct way
        store.register(defaults: [
            "synthLowNote": 36,
            "synthHighNote": 72,
            "delay": 0.1,
            ...
        ])
        // Load from store
        synthLowNote = store.integer(forKey: "synthLowNote")
        ...
    }

    private func persist() { ... }
}
```

`SettingsView`, `SortView`, and the engine all receive this via the environment or direct injection. No string is duplicated anywhere. The type system enforces correctness.

---

### 4. Decompose the God Object into focused services

`SortViewModel`'s responsibilities become four separate, injectable types:

| Service | Responsibility |
|---|---|
| `SortEngine` (actor) | Owns the array, runs algorithms, enforces index bounds, counts operations |
| `AudioService` (@MainActor class) | Manages AudioKit lifecycle, maps values to frequencies |
| `AnalyticsService` (actor) | Records run results; owns CloudKit/SwiftData interaction |
| `SortCoordinator` (@Observable @MainActor) | Drives the engine, projects snapshots, owns UI state flags |

`SortCoordinator` injects all three and coordinates them, but knows nothing about their internals:

```swift
func sort() async {
    let result = await engine.run(algorithm: algorithm)
    await analytics.record(result, on: deviceInfo)   // not in the sort loop!
}
```

Critically: **CloudKit is called after `sort()` returns**, not inside it. The sort loop is completely clean.

---

### 5. Algorithm protocol stays, but gets cleaner

The existing `SortAlgorithm` + `SortViewModelProtocol` design is actually good. In v2 it becomes cleaner because the protocol is now backed by a proper actor instead of an `@MainActor` class that also owns UI state:

```swift
public protocol SortAlgorithm: Sendable {
    var identifier: AlgorithmID { get }
    var metadata: AlgorithmMetadata { get }

    // Algorithms operate on the engine directly
    func execute(on engine: SortEngineProtocol) async
}

// The protocol the engine exposes to algorithms
public protocol SortEngineProtocol: Actor {
    var count: Int { get }
    func swap(_ i: Int, _ j: Int) async
    func compare(_ i: Int, _ j: Int, by: (Int, Int) -> Bool) async -> Bool
    func getValue(_ i: Int) async -> Int
    func setValue(_ i: Int, _ value: Int) async
    func changeColor(_ i: Int, to color: AlgorithmColor) async
    func resetColor(_ i: Int) async
    func checkCancellation() async throws   // throws CancellationError
}
```

Notice `checkCancellation()` throws instead of returning `Bool`. This means:

```swift
// Instead of every algorithm doing:
guard await enforceRunning() else { return }

// Algorithms can just use structured concurrency naturally:
try await engine.checkCancellation()
// Or even just:
try Task.checkCancellation()
```

The `enforceRunning()` pattern disappears entirely. Cancellation is structured.

---

### 6. Replace the NSObject plugin bridge with static registration

The `PluginLoader` using `NSClassFromString` and `NSObject` casting is the most fragile piece of the system. In v2, drop it entirely. Swift has a clean pattern for this: **each plugin framework statically registers itself** the moment it's linked, using a `@_silgen_name`-exposed registration function or a simple initializer:

```swift
// In QuickSortPlugin, executed at framework load time:
extension AlgorithmRegistry {
    @_silgen_name("QuickSortPlugin_register")
    static func registerQuickSort() {
        shared.register(QuickSortAlgorithm(), in: .quickSortBundle)
    }
}
```

Or more idiomatically, use the fact that Swift `enum`s with `static let` properties are lazily initialized — put registration in a static initializer that fires on first access. No dynamic Objective-C runtime needed.

Alternatively, since you're already using Tuist, define the plugin frameworks as Tuist dependencies that are linked statically. Static linking means the plugin types are available at compile time with zero runtime lookup.

---

### 7. Fix `SortItem` — separate model from presentation

`SortItem` in v2 is a pure model value. No `Color`, no `width`:

```swift
// Model layer — knows nothing about rendering
struct SortValue: Identifiable, Equatable, Sendable {
    let id: UUID
    var value: Int
}

// Presentation layer — derived by the coordinator when building a snapshot
struct BarDescriptor: Identifiable, Equatable {
    let id: UUID
    let heightFraction: Double
    let color: Color
}
```

The mapping from `SortValue` to `BarDescriptor` lives in the coordinator's `makeSnapshot()` method. The engine never imports SwiftUI.

---

### 8. The state machine for per-algorithm warnings

The current `SortView` hand-rolls a multi-step confirmation state machine for BogoSort and Bitonic Sort across a tangle of `@Published` bools and `onXxx()` functions. In v2, model it explicitly:

```swift
enum SortGate {
    case clear            // no confirmation needed, proceed
    case needsConfirmation(AlgorithmWarning)
    case confirmed
    case declined
}

struct AlgorithmWarning: Identifiable {
    let id: AlgorithmID
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}
```

The coordinator exposes `var gate: SortGate` and the view just reacts to it with a single `.confirmationDialog` modifier. No `bogoSortAccepted`, `shouldShowBitonicWarning`, or 5-function event handler chain needed.

---

### 9. `UserDefaults.register(defaults:)` and `@AppStorage` used correctly

The `Sort2App` initializer-sentinel pattern goes away. One call in `AppSettings.init()`:

```swift
store.register(defaults: [
    Keys.synthLowNote: 36,
    Keys.delay: 0.1,
    ...
])
```

`register(defaults:)` only fills in values for keys that don't already exist — it's exactly the "first launch" initializer you want, without a guard key.

---

### 10. The `insertionSort` busy-wait is a correctness bug

This deserves special mention:

```swift
// Current InsertionSortImpl.swift
while data != data.sorted() {  // ← O(n log n) comparison on every outer loop iteration
    for i in 1..<data.count { ... }
}
```

The outer `while data != data.sorted()` loop is not how insertion sort works. It converts insertion sort from `O(n²)` to potentially `O(n³)` in the worst case, and causes it to re-run the entire sort body from scratch if one pass doesn't fully sort the array (which insertion sort's single-pass implementation won't). In v2, implement it correctly: one pass of the inner loop, no outer `while` comparator.

---

### The v2 dependency graph

```
SortEngineProtocol (protocol, in SortAlgorithmCore)
    ↑
SortEngine (actor, in app target)   ←──── algorithms call this
    ↑
SortCoordinator (@Observable, @MainActor)
    ├── AudioService
    ├── AnalyticsService
    └── AppSettings
         ↑
Views (@Observable environment injection)
    ContentView → SortCoordinator (one per algorithm page, not one global)
    SettingsView → AppSettings
```

Each algorithm page creates its **own** `SortCoordinator`. There is no shared global sort state. This also eliminates the `setAlgo(algo:)` anti-pattern and the `algorithm.rawValue` string-switch dispatch, because the coordinator is constructed with the algorithm already bound.

---

### Why this makes `@Observable` work

With this design:
- `SortCoordinator.snapshot` is a value type that changes **atomically** — one assignment per render frame
- `SortCoordinator.isRunning`, `gate`, `stats` are simple scalars that change rarely
- The engine actor owns all mutable array state and no view ever touches it directly
- SwiftUI's observation system sees clean, infrequent, non-racing property accesses

`@Observable` was designed for exactly this pattern. The reason it broke is that the current design mutates UI-observed state from inside a concurrent loop — which is fundamentally incompatible with observation, not just with `@Observable` specifically.
> I would prefer an architecture that pre-sorts the array and replays the operations onto the view, because it would also enable stepping and recording, and accelerate the sorting process considerably. Does that make sense?
Yes, that makes complete sense, and it's actually the right architecture for this domain. Let me think through the full implications before advising you.
[read_file…]

[read_file…]

[read_file…]
Yes, it makes complete sense — and it's actually the architecture that professional sort visualizers (like `timo.io/timsort`) use. Let me map out the full design precisely, including all the sharp edges specific to *your* codebase.

---

## The Record/Replay Architecture

### The Core Idea

Instead of algorithms mutating a live array that SwiftUI is reading, you split execution into two fully independent phases:

```
Phase 1 — Record (off-screen, instantaneous, no delay, no UI):
  Algorithm runs on a plain [Int] array
  Every logical operation is appended to a tape: [SortOperation]

Phase 2 — Replay (on-screen, user-controlled speed, steppable):
  A replay engine walks the tape at any speed
  SwiftUI only ever sees the current frame's rendered state
  Stepping, scrubbing, recording are free capabilities
```

These two phases share nothing except the tape. The algorithm never touches SwiftUI. SwiftUI never touches the algorithm.

---

### The Operation Tape

Every distinct thing an algorithm can do becomes a case in one enum:

```swift
enum SortOperation: Sendable {
    // Structural mutations
    case swap(Int, Int)
    case setValue(Int, Int)          // (index, newValue) — needed for Radix
    case setSlice([Int], from: Int)  // bulk-write a range — also needed for Radix buckets

    // Visual annotations only — no structural effect
    case highlight([Int: HighlightColor])   // mark one or more indices
    case clearHighlights([Int])             // clear specific indices
    case clearAllHighlights

    // Audio hint (replay engine maps index → frequency)
    case playNote(Int)

    // Metadata
    case compare(Int, Int)           // counted but structurally inert
    case markSorted(Int)             // turns a bar permanently green at completion
}

enum HighlightColor: Sendable {
    case pivot, comparison, swap, reading, writing, bucket(Int)
}
```

A full sort of 256 items with QuickSort produces roughly 8,000–15,000 operations. At 8 bytes per operation average that's ~120KB. Even BogoSort on 12 items stays manageable because you enumerate permutations rather than randomly shuffling, so the tape is bounded.

---

### The Recording Engine

The recording engine is a plain `struct` — no actors, no async, no SwiftUI — that implements the same primitive interface your algorithms already use:

```swift
struct RecordingEngine {
    private(set) var tape: [SortOperation] = []
    private(set) var values: [Int]          // the live array being sorted
    private(set) var compareCount: Int = 0

    init(values: [Int]) {
        self.values = values
    }

    mutating func swap(_ i: Int, _ j: Int) {
        tape.append(.highlight([i: .swap, j: .swap]))
        tape.append(.swap(i, j))
        tape.append(.playNote(i))
        tape.append(.playNote(j))
        tape.append(.clearHighlights([i, j]))
        values.swapAt(i, j)
        compareCount &+= 1
    }

    mutating func compare(_ i: Int, _ j: Int, by: (Int, Int) -> Bool = (>=)) -> Bool {
        tape.append(.highlight([i: .comparison, j: .comparison]))
        tape.append(.compare(i, j))
        tape.append(.clearHighlights([i, j]))
        compareCount &+= 1
        return by(values[i], values[j])
    }

    mutating func setValue(_ i: Int, _ value: Int) {
        tape.append(.highlight([i: .writing]))
        tape.append(.setValue(i, value))
        tape.append(.clearHighlights([i]))
        values[i] = value
    }

    // etc.
}
```

Notice it's `mutating` on a `struct`. It runs on a background thread, produces a value, and hands it off. There is no actor boundary, no `await`, no `Task.sleep`. It just runs.

---

### The Algorithm Protocol Changes

Your algorithms currently receive a `SortViewModelProtocol`. In v2 they receive a `RecordingEngine`. Because the engine is a `struct` with `mutating` methods, the protocol needs a tiny shim:

```swift
// In SortAlgorithmCore
public protocol SortAlgorithm: Sendable {
    var identifier: AlgorithmID { get }
    var metadata: AlgorithmMetadata { get }

    // Synchronous. Runs on a background thread. No async.
    // Returns the completed tape.
    func record(engine: inout RecordingEngine)
}
```

This is a breaking change to the plugin protocol, but it's a simplification — `async` disappears entirely from algorithm implementations:

```swift
// QuickSort before:
func _quickSort(_ vm: SortViewModelProtocol, _ left: Int, _ right: Int) async {
    guard await vm.enforceRunning() else { return }
    ...
    while await vm.compare(pivot, i) && i < j { ... }
}

// QuickSort after:
func _quickSort(_ engine: inout RecordingEngine, _ left: Int, _ right: Int) {
    // No guard. No await. No enforceRunning. Just algorithm logic.
    if left < right {
        ...
        while engine.compare(pivot, i) && i < j { ... }
    }
}
```

The algorithms become dramatically simpler. The `enforceRunning()` pattern vanishes because cancellation is no longer relevant during recording — you can't cancel a synchronous function. Cancellation only applies to the *replay*, which you can pause/stop at any point.

---

### The Replay Engine

The replay engine is an `@Observable` `@MainActor` class. This is the **only** thing SwiftUI observes. It maintains the current visual state of the bars:

```swift
@Observable
@MainActor
final class ReplayEngine {
    // This is what SwiftUI reads. Updated one frame at a time.
    private(set) var frame: [BarState]
    private(set) var stepIndex: Int = 0
    private(set) var isPlaying: Bool = false
    private(set) var compareCount: Int = 0

    private let tape: [SortOperation]
    private let initialValues: [Int]
    private var playbackTask: Task<Void, Never>?

    struct BarState: Identifiable {
        let id: UUID        // stable — same UUIDs from recording
        var value: Int
        var highlight: HighlightColor?
        var isSorted: Bool = false
    }

    init(tape: [SortOperation], initialValues: [Int]) {
        self.tape = tape
        self.initialValues = initialValues
        // Build initial frame from initialValues
        self.frame = initialValues.enumerated().map { i, v in
            BarState(id: stableIDs[i], value: v)
        }
    }

    // Step forward by one operation
    func stepForward() {
        guard stepIndex < tape.count else { return }
        apply(tape[stepIndex])
        stepIndex += 1
    }

    // Step backward — re-applies from 0 to stepIndex - 1
    func stepBackward() {
        guard stepIndex > 0 else { return }
        resetFrame()
        let target = stepIndex - 1
        for i in 0..<target { apply(tape[i]) }
        stepIndex = target
    }

    // Play at a given speed (operations per second)
    func play(speed: Double) {
        isPlaying = true
        playbackTask = Task {
            while stepIndex < tape.count && !Task.isCancelled {
                stepForward()
                let delay = UInt64(1_000_000_000.0 / speed)
                try? await Task.sleep(nanoseconds: delay)
            }
            isPlaying = false
        }
    }

    func pause() {
        playbackTask?.cancel()
        isPlaying = false
    }

    // Scrub to any position
    func seek(to index: Int) {
        pause()
        resetFrame()
        let target = min(index, tape.count)
        for i in 0..<target { apply(tape[i]) }
        stepIndex = target
    }

    private func apply(_ op: SortOperation) {
        switch op {
        case .swap(let i, let j):
            frame.swapAt(i, j)
        case .setValue(let i, let v):
            frame[i].value = v
        case .highlight(let map):
            for (i, color) in map { frame[i].highlight = color }
        case .clearHighlights(let indices):
            for i in indices { frame[i].highlight = nil }
        case .clearAllHighlights:
            for i in frame.indices { frame[i].highlight = nil }
        case .compare(_, _):
            compareCount &+= 1
        case .playNote(let i):
            audio.play(value: frame[i].value, totalValues: frame.count)
        case .markSorted(let i):
            frame[i].isSorted = true
        case .setSlice(let values, let from):
            for (offset, v) in values.enumerated() {
                frame[from + offset].value = v
            }
        }
    }
}
```

Notice:
- `stepBackward()` re-applies from the beginning. For 15,000 ops this is fast — it's just integer array mutations with no I/O. If you want O(1) backward steps you can checkpoint every 500 operations and re-apply from the nearest checkpoint.
- `frame` is only written by `@MainActor` functions. `@Observable` fires exactly once per `stepForward()` call. No data races, no batching, no CoW tricks needed.
- Seeking to any position is free. This is the "scrubbing" capability that was literally impossible with the current architecture.

---

### The Coordinator / Session

One level above the replay engine sits the session, which owns the full lifecycle:

```swift
@Observable
@MainActor
final class SortSession {
    enum Phase {
        case idle
        case recording                   // background task running
        case ready(tape: [SortOperation], initialValues: [Int])
        case replaying(ReplayEngine)
        case complete(ReplayEngine)
    }

    private(set) var phase: Phase = .idle
    private(set) var recordingProgress: Double = 0  // for a progress indicator during long records

    let algorithm: any SortAlgorithm
    let settings: AppSettings

    func prepare(values: [Int]) async {
        phase = .recording
        // Run recording on a background thread - it's synchronous, not async
        let tape = await Task.detached(priority: .userInitiated) {
            var engine = RecordingEngine(values: values)
            self.algorithm.record(engine: &engine)   // pure, synchronous
            return (engine.tape, values)
        }.value
        phase = .ready(tape: tape.0, initialValues: tape.1)
    }

    func startReplay() {
        guard case .ready(let tape, let initial) = phase else { return }
        let replay = ReplayEngine(tape: tape, initialValues: initial)
        phase = .replaying(replay)
        replay.play(speed: settings.playbackSpeed)
    }
}
```

`SortView` binds to `SortSession`. When the user presses "Start", `prepare()` fires, the recording happens instantly in the background (no perceived delay for reasonable array sizes), and replay begins. The UI sees the phase transition and renders accordingly.

---

### What you get for free

Once this is in place, several features that are currently impossible or deeply broken become trivial:

**Stepping** — already shown. `stepForward()` and `stepBackward()` on `ReplayEngine`. One button in the UI, two lines of logic.

**Scrubbing** — a `Slider` bound to `stepIndex / tape.count`. Drag it anywhere. `seek(to:)` handles it.

**Speed control** — `play(speed:)` accepts any `Double`. 0.5× to 100× is just a number. There's no longer a `delay` slider with millisecond granularity awkwardly stuffed into the sort loop.

**Recording to video/GIF** — iterate the tape off-screen at 60fps, render each frame to an `ImageRenderer`, pipe to AVAssetWriter. The tape is the perfect source for this.

**Benchmarking without visual overhead** — run `RecordingEngine` synchronously, measure wall time, count operations from the tape. No UI, no audio, no delay. Your benchmarking page becomes trivial.

**Comparing two algorithms** — run two `RecordingEngine`s, two `ReplayEngine`s, side by side.

**Resumable sorts** — serialise the tape to disk (`Codable`). Resume from any `stepIndex`.

---

### The one genuine hard problem: Radix Sort

Your current Radix Sort uses `Color` as a bucket discriminator — it picks 11 shuffled colors and uses the color sequence to determine which bucket an item belongs to visually. This means the color assignments are *part of the algorithm's logic*, not just decoration.

In the tape model, `HighlightColor.bucket(Int)` handles this cleanly: the recording engine assigns bucket indices (0–10) rather than `Color` values. The replay engine maps bucket index → color. This also means you can theme bucket colors independently of the algorithm, which was previously impossible.

The bucket color shuffle needs to be seeded and stored in the tape header so replay is deterministic:

```swift
struct TapeHeader: Sendable {
    let algorithmID: AlgorithmID
    let initialValues: [Int]
    let seed: UInt64           // for algorithms with randomized visual elements
    let recordedAt: Date
    let totalOperations: Int
    let totalCompares: Int
}

struct Tape: Sendable {
    let header: TapeHeader
    let operations: [SortOperation]
}
```

---

### The one behavioral difference to decide up front

Currently, the sort algorithms control *when* to play notes and *which* notes to play, because `playNote` is woven into the algorithm logic. In the tape model, note timing is determined by the replay engine's speed. This is actually better — it means notes play in sync with the visual frame rate rather than with the algorithm's internal delay logic — but it means the audio "texture" of different algorithms will change slightly. Whether that's acceptable is a design call, but I'd argue it's an improvement: the current architecture means a fast algorithm at low delay can play notes faster than AudioKit can process them, which causes audio glitches.

---

### Migration path from the current codebase

You don't have to rewrite everything at once. The protocol boundary between the algorithm and the engine is the only thing that changes for plugin authors. The migration is:

1. Write `RecordingEngine` and `SortOperation` in `SortAlgorithmCore`.
2. Add `func record(engine: inout RecordingEngine)` to `SortAlgorithm` protocol alongside the existing `execute()`.
3. Port one algorithm (QuickSort) to the new protocol as proof of concept.
4. Write `ReplayEngine` and `SortSession`.
5. Wire up one view to the new session.
6. Once it works end-to-end, port the remaining algorithms and deprecate `execute()`.

The `TestSortViewModel` you already have becomes `TestRecordingEngine` — a concrete `RecordingEngine` with assertion helpers. The existing plugin tests still work, just calling `record(engine:)` instead of `execute(viewModel:)`.

---

### In one sentence

The record/replay architecture makes the sort algorithms **pure functions** from `[Int]` to `[SortOperation]`, which is the right abstraction, and makes the UI a **pure consumer** of that tape, which is what `@Observable` was designed for.
> Could you make a Markdown document that describes this new architecture in thorough detail so that I can remember this conversation? I prefer having a plugin system somewhat like the original system, because that way, unlike the original v0 architecture I created, I don't have to run around the codebase changing individual details when I add a new algorithm. The plugin system allows me to drop in a new framework file that gets automatically recognized by the app.
