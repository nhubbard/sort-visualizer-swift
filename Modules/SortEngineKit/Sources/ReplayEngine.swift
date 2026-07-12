import Foundation
import Observation
import os
import QuartzCore

/// Labels `play()`'s per-tick batch-apply interval for a manual Instruments capture — the exact
/// mechanism behind a past perf bug (see `state`'s doc comment) was invisible in a generic Time
/// Profiler trace until it was traced back to this call by hand; a signpost interval here means a
/// future trace shows "TickApply" spans directly, with the batch size as its message, instead of
/// requiring that same manual detective work again.
private let replaySignposter = OSSignposter(subsystem: "com.nhubbard.Sort2.SortEngineKit", category: "ReplayEngine")

/// Abstracts the redraw clock so `ReplayEngine` doesn't require a live display link to be
/// testable. `onTick` fires once per frame with the elapsed time since the previous tick (0 for
/// the very first tick after `start`).
protocol DisplayLinkDriving: AnyObject {
    func start(onTick: @escaping (TimeInterval) -> Void)
    func stop()
}

/// Real production driver — paces ticks on true hardware vsync via `CADisplayLink`.
final class CADisplayLinkDriver: DisplayLinkDriving {
    /// `CADisplayLink` has no closure-based initializer, only target/selector, so this plain
    /// `NSObject` exists solely to be that target and forward each callback into a closure.
    private final class Proxy: NSObject {
        let callback: (CADisplayLink) -> Void
        init(callback: @escaping (CADisplayLink) -> Void) { self.callback = callback }
        @objc func tick(_ link: CADisplayLink) { callback(link) }
    }

    private var displayLink: CADisplayLink?
    private var proxy: Proxy?
    private var lastTimestamp: CFTimeInterval?

    func start(onTick: @escaping (TimeInterval) -> Void) {
        let proxy = Proxy { [weak self] link in
            guard let self else { return }
            let elapsed = self.lastTimestamp.map { link.timestamp - $0 } ?? 0
            self.lastTimestamp = link.timestamp
            onTick(elapsed)
        }
        self.proxy = proxy
        let link = CADisplayLink(target: proxy, selector: #selector(Proxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
        lastTimestamp = nil
    }
}

/// The **only** `@Observable` type that touches per-element sort state. Every mutation happens
/// inside a single `@MainActor` method, one `stepIndex` at a time — there is no concurrent writer,
/// so `@Observable`'s direct-access tracking is exactly the right tool (§1.4/§4.1).
@Observable
@MainActor
public final class ReplayEngine {
    /// One visual slot. `id` is stable per array *position*, not per value — swapping two indices
    /// exchanges their `value`, never their `id` or `markers`. Marks are index-based (an algorithm
    /// marks/unmarks specific indices, independent of whatever value currently sits there), so
    /// keeping `id` pinned to the slot is what makes that model consistent, and it means a
    /// `Visualizer` never needs identity-tracking machinery to draw a frame correctly.
    public struct BarState: Identifiable, Sendable, Equatable {
        public let id: UUID
        public internal(set) var value: Int
        public internal(set) var markers: Set<Int> = []
        public internal(set) var isSorted = false

        init(id: UUID, value: Int) {
            self.id = id
            self.value = value
        }
    }

    /// Everything that changes once per applied tape operation, bundled into one value so
    /// `ReplayEngine` only ever performs a single `@Observable` write per mutation — see `state`'s
    /// doc comment for why that matters. Distinct from `isPlaying`/`speed` below, which are
    /// playback *controls*, not state derived from replaying the tape.
    public struct PlaybackState: Sendable, Equatable {
        public internal(set) var frame: [BarState]
        /// `AuxHandle.rawValue` -> current contents, for `VisualizationContext`.
        public internal(set) var auxArrays: [Int: [Int]]
        public internal(set) var compareCount: Int
        public internal(set) var swapCount: Int
        /// Writes to the main array — a swap counts as 2 (ArrayV's `Writes.updateSwap`
        /// convention), plus 1 per `.setValue`.
        public internal(set) var mainWriteCount: Int
        /// Writes to auxiliary/scratch buffers (ArrayV's `Writes.auxWrites`).
        public internal(set) var auxWriteCount: Int
        /// Whole-range-reverse operations (ArrayV's `Writes.reversals`) — counts the operation,
        /// not the element moves it's built from (those already land in `swapCount`).
        public internal(set) var reversalCount: Int
        public internal(set) var stepIndex: Int

        /// Hand-written, not synthesized: `@Observable`'s macro-generated `state` setter calls
        /// this on every plain assignment (`stepForward`/`seek`) to decide whether to notify
        /// observers at all, and the synthesized field-by-field `==` would walk the whole `frame`
        /// array to answer that. `stepIndex` alone determines every other field for a given tape
        /// (both sides are always produced by replaying the same deterministic operation list),
        /// so comparing it is equivalent and O(1).
        public static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
            lhs.stepIndex == rhs.stepIndex
        }
    }

    /// The one `@Observable`-tracked stored property behind `frame`/`auxArrays`/`compareCount`/
    /// `swapCount`/`mainWriteCount`/`auxWriteCount`/`reversalCount`/`stepIndex` below. Profiling a
    /// live replay showed the main thread pegged inside SwiftUI's AttributeGraph dirty-propagation
    /// machinery, not inside any view body — caused by this type previously exposing five of these
    /// as *separate* stored properties, each mutated independently every tick, each firing its own
    /// Observable dirty-propagation. Bundling them into one value and writing it exactly once per
    /// mutation (`stepForward`/`seek`/each `play()` tick) cut that fan-out 5x at the time. Every
    /// ArrayV-parity statistic added since (`mainWriteCount`/`auxWriteCount`/`reversalCount`, and
    /// whatever comes next) is a new `PlaybackState` field for exactly that reason — adding it as
    /// its own stored property on `ReplayEngine` would reopen the fan-out this consolidation closed.
    public private(set) var state: PlaybackState

    public var frame: [BarState] { state.frame }
    public var auxArrays: [Int: [Int]] { state.auxArrays }
    public var stepIndex: Int { state.stepIndex }
    public var compareCount: Int { state.compareCount }
    public var swapCount: Int { state.swapCount }
    public var mainWriteCount: Int { state.mainWriteCount }
    public var auxWriteCount: Int { state.auxWriteCount }
    public var reversalCount: Int { state.reversalCount }

    /// Live element count across all currently-allocated auxiliary/scratch buffers (ArrayV's
    /// "Items in External Arrays" — `Writes.allocAmount`). Derived on demand from `auxArrays`
    /// rather than tracked as its own counter — the live buffer contents are already `state`,
    /// so a separate stored count would just be a second source of truth for the same number.
    public var externalArrayItemCount: Int {
        state.auxArrays.values.reduce(0) { $0 + $1.count }
    }

    /// A second, independent per-operation observer, orthogonal to `play(onStep:)`'s own
    /// parameter — set directly on whichever `ReplayEngine` instance a view currently holds
    /// (views already get one, e.g. `MetalRendererView`), rather than threaded through
    /// `SortSession`'s audio-specific wiring. Exists so an incremental renderer can repaint just
    /// the touched positions without `SortEngineKit`/`SortSession` needing to know renderers
    /// exist at all — the same "engine stays unaware of who's listening" shape `onStep` itself
    /// already has for audio. Fires immediately after `onStep`, with the same post-batch `frame`
    /// state (see `play()`'s doc comment on `onStep` for why a batch's intermediate per-operation
    /// values are never individually observable — both hooks share that same limitation).
    public var onOperationApplied: ((SortOperation) -> Void)?

    public private(set) var isPlaying = false

    /// Operations per second — a live knob, not a one-shot parameter: `play()`'s loop re-reads
    /// this on every iteration, so a caller (e.g. a run-control slider) can change it while
    /// replay is in progress and see the cadence change on the very next step.
    public var speed: Double = 30.0

    /// So consumers (e.g. Metal layouts, for `colorSeed`) can read tape metadata without
    /// `ReplayEngine` handing out the operations array itself.
    public var header: TapeHeader { tape.header }
    public var totalOperationCount: Int { tape.operations.count }

    /// Active playback time — accumulated across pause/resume cycles, excluding time spent
    /// paused. Consistent with `compareCount`/`swapCount`, which also only reflect genuine
    /// progress through the tape, not wall-clock time the session happened to be open.
    public var elapsedPlaybackDuration: TimeInterval {
        activePlaybackDuration + (currentSegmentStart.map { Date().timeIntervalSince($0) } ?? 0)
    }

    private var activePlaybackDuration: TimeInterval = 0
    private var currentSegmentStart: Date?

    /// Folds the currently-open segment (if any) into `activePlaybackDuration` and clears
    /// `currentSegmentStart` — shared by `pause()` and `play()`'s own natural-completion path.
    /// Idempotent: `currentSegmentStart` is `nil` after the first call, so whichever of "the tape
    /// ran out" or "the user paused" happens first wins outright; the other is a no-op. Without
    /// this shared close on the natural-completion path too, `elapsedPlaybackDuration`'s getter
    /// (which adds live `Date()` time for any still-open segment) would keep growing, unbounded,
    /// on every read after a sort finishes on its own — until the next `pause()`/`seek(to:)`
    /// happened to close it. `RunControlBar` reads `elapsedPlaybackDuration` on every body
    /// evaluation, so this was a real, user-visible drift, not just a theoretical one.
    private func closeActiveSegmentIfNeeded() {
        if let currentSegmentStart {
            activePlaybackDuration += Date().timeIntervalSince(currentSegmentStart)
            self.currentSegmentStart = nil
        }
    }

    private let tape: Tape
    /// Every ~500 operations, so `seek(to:)` never replays more than ~500 ops from the nearest one.
    private let checkpoints: [PlaybackState]
    private var playbackTask: Task<Void, Never>?
    /// The driver behind whatever `play()` call is currently in flight, kept here (not just
    /// captured locally inside `play()`'s `Task`) so `pause()` can silence it immediately instead
    /// of waiting for the `Task`'s own cancellation check to run on the next tick.
    private var activeDriver: DisplayLinkDriving?
    private let displayLinkFactory: () -> DisplayLinkDriving

    private static let checkpointInterval = 500

    public convenience init(tape: Tape) {
        self.init(tape: tape, displayLinkFactory: { CADisplayLinkDriver() })
    }

    /// Not `public` — the display-link seam exists so tests can inject a deterministic fake
    /// instead of depending on a real `CADisplayLink` firing inside this module's host-less
    /// `.unitTests` bundle. Production code and `@testable import`ing tests are the only callers.
    init(tape: Tape, displayLinkFactory: @escaping () -> DisplayLinkDriving) {
        self.tape = tape
        self.displayLinkFactory = displayLinkFactory

        let initialFrame = tape.header.initialValues.map { BarState(id: UUID(), value: $0) }
        let initialState = PlaybackState(
            frame: initialFrame, auxArrays: [:], compareCount: 0, swapCount: 0,
            mainWriteCount: 0, auxWriteCount: 0, reversalCount: 0, stepIndex: 0
        )
        self.state = initialState

        var checkpoints = [initialState]
        var working = initialState
        for operation in tape.operations {
            Self.apply(operation, to: &working)
            if working.stepIndex.isMultiple(of: Self.checkpointInterval) {
                checkpoints.append(working)
            }
        }
        self.checkpoints = checkpoints
    }

    public func stepForward() {
        guard state.stepIndex < tape.operations.count else { return }
        mutatingState { working in
            Self.apply(tape.operations[working.stepIndex], to: &working)
        }
    }

    public func stepBackward() {
        guard state.stepIndex > 0 else { return }
        seek(to: state.stepIndex - 1)
    }

    public func seek(to index: Int) {
        pause()
        let target = max(0, min(index, tape.operations.count))
        let checkpoint = nearestCheckpoint(atOrBefore: target)
        mutatingState { working in
            working = checkpoint
            while working.stepIndex < target {
                Self.apply(tape.operations[working.stepIndex], to: &working)
            }
        }
    }

    /// Routes a mutation through `@Observable`'s synthesized `_modify` accessor for `state`
    /// (via `&state`) instead of `var working = state; ...; state = working`. The latter leaves
    /// `state` and `working` referencing the same `frame` buffer until the write-back — `Array`
    /// is copy-on-write, so the very first element mutation inside `body` forces a full O(n) copy
    /// of `frame` before it can write to it. Yielding `state` directly keeps only one reference to
    /// that buffer alive for the whole batch, so no copy happens regardless of how many operations
    /// `body` applies. `_modify` also unconditionally calls `willSet`/`didSet` exactly once for the
    /// whole access rather than routing through the `Equatable`-based `shouldNotifyObservers` the
    /// plain setter uses — batched callers (`play()`) always mutate `state`, so that's moot; this
    /// helper exists for the copy-avoidance, not to dodge the (already-cheap, see `PlaybackState.
    /// ==`) equality check.
    private func mutatingState(_ body: (inout PlaybackState) -> Void) {
        body(&state)
    }

    /// Elapsed time between ticks is clamped to this before feeding the accumulator, so a real
    /// gap (backgrounding, a debugger pause, a genuine hitch) can't turn into one enormous burst
    /// of operations applied in a single tick.
    private static let maxCatchUpInterval: TimeInterval = 0.25

    /// The pure pacing math, factored out of `play()` so it's directly unit-testable without a
    /// driver: how many operations are due given `elapsed` real seconds at `speed` operations per
    /// second, carrying any fractional remainder forward in `accumulator` so slow speeds don't
    /// lose operations to rounding, and never returning more than `remaining` (the tape doesn't
    /// have more to give).
    static func opsToApply(elapsed: TimeInterval, speed: Double, accumulator: inout Double, remaining: Int) -> Int {
        accumulator += min(elapsed, maxCatchUpInterval) * speed
        let ops = min(Int(accumulator), remaining)
        accumulator -= Double(ops)
        return ops
    }

    /// Returns the playback `Task` so callers (e.g. `SortSession`) can `await` its completion
    /// instead of polling `isPlaying`.
    ///
    /// `onStep`, when provided, is called with each operation immediately after it's applied —
    /// this is the seam `SortSession` uses to fire audio per touched index (§3.1 of
    /// ARCHITECTURE_V2.md) without `SortEngineKit` itself knowing `AudioPlaying`/`AppSettings`
    /// exist. Deliberately scoped to this loop only, not `stepForward()` itself, so scrubbing via
    /// `stepForward()`/`stepBackward()`/`seek(to:)` directly never triggers audio.
    ///
    /// Reads `speed` fresh on every tick (rather than capturing it once) so a caller can change it
    /// live, mid-replay, and see the new cadence take effect immediately.
    ///
    /// Ticks come from `displayLinkFactory()` — real hardware vsync (`CADisplayLinkDriver`) in
    /// production, a deterministic fake in tests — rather than a fixed sleep interval derived from
    /// `speed`. This decouples *simulation* (how many tape operations are due, governed purely by
    /// `opsToApply`'s `elapsed × speed` accumulator, uncapped) from *render* (when the display
    /// actually gets a new frame): a fast machine at a high `speed` just accumulates and applies
    /// more operations per real vsync interval, instead of being capped by an assumed render rate.
    /// A tick that has no operation due yet (`opsToApply == 0`, common at low `speed`) is skipped
    /// entirely — no `mutatingState` write, no redraw. Whatever batch *is* due within one tick
    /// still applies through one `mutatingState` call, preserving the single-`@Observable`-write-
    /// per-tick property the type's other doc comments (see `state`) depend on.
    @discardableResult
    public func play(onStep: ((SortOperation) -> Void)? = nil) -> Task<Void, Never> {
        isPlaying = true
        currentSegmentStart = Date()

        let driver = displayLinkFactory()
        activeDriver = driver
        let (stream, continuation) = AsyncStream<TimeInterval>.makeStream()
        driver.start { elapsed in continuation.yield(elapsed) }

        let task = Task { [weak self] in
            var accumulator = 0.0
            for await elapsed in stream {
                guard let self, !Task.isCancelled else { break }
                let remaining = self.tape.operations.count - self.state.stepIndex
                guard remaining > 0 else { break }

                let opsToApply = Self.opsToApply(
                    elapsed: elapsed, speed: self.speed, accumulator: &accumulator, remaining: remaining
                )
                guard opsToApply > 0 else { continue }

                var appliedOperations: [SortOperation] = []
                appliedOperations.reserveCapacity(opsToApply)
                let tickInterval = replaySignposter.beginInterval(
                    "TickApply", id: replaySignposter.makeSignpostID(), "\(opsToApply) ops")
                self.mutatingState { working in
                    for _ in 0..<opsToApply {
                        guard working.stepIndex < self.tape.operations.count else { break }
                        let operation = self.tape.operations[working.stepIndex]
                        Self.apply(operation, to: &working)
                        appliedOperations.append(operation)
                    }
                }
                replaySignposter.endInterval("TickApply", tickInterval)

                for operation in appliedOperations {
                    onStep?(operation)
                    onOperationApplied?(operation)
                }

                if self.state.stepIndex >= self.tape.operations.count { break }
            }
            driver.stop()
            self?.activeDriver = nil
            self?.isPlaying = false
            // Natural completion (the tape ran out, `break` above) never went through `pause()`,
            // so it needs its own close of the active segment — see `closeActiveSegmentIfNeeded`'s
            // doc comment for why this can't be skipped.
            self?.closeActiveSegmentIfNeeded()
        }
        playbackTask = task
        return task
    }

    public func pause() {
        playbackTask?.cancel()
        activeDriver?.stop()
        activeDriver = nil
        isPlaying = false
        closeActiveSegmentIfNeeded()
    }

    /// Binary search for the latest checkpoint at or before `step` — `checkpoints` is sorted
    /// ascending by construction.
    private func nearestCheckpoint(atOrBefore step: Int) -> PlaybackState {
        var low = 0
        var high = checkpoints.count - 1
        var result = checkpoints[0]
        while low <= high {
            let mid = (low + high) / 2
            if checkpoints[mid].stepIndex <= step {
                result = checkpoints[mid]
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    private static func apply(_ operation: SortOperation, to state: inout PlaybackState) {
        switch operation {
        case let .swap(i, j):
            let temp = state.frame[i].value
            state.frame[i].value = state.frame[j].value
            state.frame[j].value = temp
            state.swapCount += 1
            state.mainWriteCount += 2
        case let .setValue(i, value):
            state.frame[i].value = value
            state.mainWriteCount += 1
        case let .mark(marker, index):
            state.frame[index].markers.insert(marker)
        case let .unmark(marker):
            for i in state.frame.indices { state.frame[i].markers.remove(marker) }
        case let .unmarkIndex(marker, index):
            state.frame[index].markers.remove(marker)
        case .unmarkAll:
            for i in state.frame.indices { state.frame[i].markers.removeAll() }
        case .compare:
            state.compareCount += 1
        case let .markSorted(i):
            state.frame[i].isSorted = true
        case let .auxCreate(handle, length):
            state.auxArrays[handle] = Array(repeating: 0, count: length)
        case let .auxWrite(handle, index, value):
            state.auxArrays[handle]![index] = value
            state.auxWriteCount += 1
        case let .auxDelete(handle):
            state.auxArrays.removeValue(forKey: handle)
        case .reversal:
            state.reversalCount += 1
        }
        state.stepIndex += 1
    }
}
