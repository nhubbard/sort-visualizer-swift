import Foundation
import Observation

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

    public private(set) var isPlaying = false

    /// Operations per second — a live knob, not a one-shot parameter: `play()`'s loop re-reads
    /// this on every iteration, so a caller (e.g. a run-control slider) can change it while
    /// replay is in progress and see the cadence change on the very next step.
    public var speed: Double = 30.0

    /// So consumers (e.g. `VisualizationCanvas`, for `colorSeed`) can read tape metadata without
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

    private let tape: Tape
    /// Every ~500 operations, so `seek(to:)` never replays more than ~500 ops from the nearest one.
    private let checkpoints: [PlaybackState]
    private var playbackTask: Task<Void, Never>?

    private static let checkpointInterval = 500

    public init(tape: Tape) {
        self.tape = tape

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
        var working = state
        Self.apply(tape.operations[working.stepIndex], to: &working)
        state = working
    }

    public func stepBackward() {
        guard state.stepIndex > 0 else { return }
        seek(to: state.stepIndex - 1)
    }

    public func seek(to index: Int) {
        pause()
        let target = max(0, min(index, tape.operations.count))
        var working = nearestCheckpoint(atOrBefore: target)
        while working.stepIndex < target {
            Self.apply(tape.operations[working.stepIndex], to: &working)
        }
        state = working
    }

    /// Above this many renders per second, a batch of operations is applied per tick instead of
    /// one, capped at `maxOpsPerTick` — see `play()`'s doc comment for why both exist.
    private static let targetRenderHz = 30.0
    private static let maxOpsPerTick = 20

    /// Returns the playback `Task` so callers (e.g. `SortSession`) can `await` its completion
    /// instead of polling `isPlaying`.
    ///
    /// `onStep`, when provided, is called with each operation immediately after it's applied —
    /// this is the seam `SortSession` uses to fire audio per touched index (§3.1 of
    /// ARCHITECTURE_V2.md) without `SortEngineKit` itself knowing `AudioPlaying`/`AppSettings`
    /// exist. Deliberately scoped to this loop only, not `stepForward()` itself, so scrubbing via
    /// `stepForward()`/`stepBackward()`/`seek(to:)` directly never triggers audio.
    ///
    /// Reads `speed` fresh on every iteration (rather than capturing it once as a parameter) so a
    /// caller can change it live, mid-replay, and see the new cadence take effect on the next tick.
    ///
    /// Applies a *batch* of operations per tick rather than one, sized so ticks never demand more
    /// than `targetRenderHz` renders per second, capped at `maxOpsPerTick`. The batch is
    /// accumulated into a local `PlaybackState` and written back to `state` **exactly once per
    /// tick**, not once per operation — calling `stepForward()` in a loop would still mutate the
    /// observed state once per operation, leaving the same total mutation count as before
    /// batching, since coalescing render *requests* doesn't reduce how many times observed state
    /// actually changed.
    ///
    /// Measured on-device throughput at high `speed` used to fall well short of what this formula
    /// alone predicts. Instruments profiling traced the gap to `ReplayEngine` previously exposing
    /// `frame`/`auxArrays`/`compareCount`/`swapCount`/`stepIndex` as five separately-mutated
    /// `@Observable` properties — each tick fired five independent AttributeGraph dirty-propagation
    /// events instead of one, and that fan-out (not any view's own rendering cost) dominated the
    /// main thread. Consolidating them into the single `state: PlaybackState` write above is the
    /// fix; `maxOpsPerTick` still keeps this fixed-formula version bounded and predictable on top
    /// of that.
    @discardableResult
    public func play(onStep: ((SortOperation) -> Void)? = nil) -> Task<Void, Never> {
        isPlaying = true
        currentSegmentStart = Date()
        let task = Task { [weak self] in
            while let self, self.state.stepIndex < self.tape.operations.count, !Task.isCancelled {
                let opsPerTick = max(1, min(Self.maxOpsPerTick, Int((self.speed / Self.targetRenderHz).rounded())))

                var working = self.state
                var appliedOperations: [SortOperation] = []
                appliedOperations.reserveCapacity(opsPerTick)

                for _ in 0..<opsPerTick {
                    guard working.stepIndex < self.tape.operations.count else { break }
                    let operation = self.tape.operations[working.stepIndex]
                    Self.apply(operation, to: &working)
                    appliedOperations.append(operation)
                }

                // One assignment to `state` per tick, regardless of opsPerTick.
                self.state = working

                for operation in appliedOperations {
                    onStep?(operation)
                }

                guard self.state.stepIndex < self.tape.operations.count else { break }
                try? await Task.sleep(for: .seconds(Double(appliedOperations.count) / self.speed))
            }
            self?.isPlaying = false
        }
        playbackTask = task
        return task
    }

    public func pause() {
        playbackTask?.cancel()
        isPlaying = false
        if let currentSegmentStart {
            activePlaybackDuration += Date().timeIntervalSince(currentSegmentStart)
        }
        currentSegmentStart = nil
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
