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
    public struct BarState: Identifiable, Sendable {
        public let id: UUID
        public internal(set) var value: Int
        public internal(set) var markers: Set<Int> = []
        public internal(set) var isSorted = false

        init(id: UUID, value: Int) {
            self.id = id
            self.value = value
        }
    }

    public private(set) var frame: [BarState]
    /// `AuxHandle.rawValue` -> current contents, for `VisualizationContext`.
    public private(set) var auxArrays: [Int: [Int]] = [:]
    public private(set) var stepIndex = 0
    public private(set) var isPlaying = false
    public private(set) var compareCount = 0

    /// So consumers (e.g. `VisualizationCanvas`, for `colorSeed`) can read tape metadata without
    /// `ReplayEngine` handing out the operations array itself.
    public var header: TapeHeader { tape.header }

    private let tape: Tape
    /// Every ~500 operations, so `seek(to:)` never replays more than ~500 ops from the nearest one.
    private let checkpoints: [Checkpoint]
    private var playbackTask: Task<Void, Never>?

    private static let checkpointInterval = 500

    private struct Checkpoint {
        let step: Int
        let frame: [BarState]
        let auxArrays: [Int: [Int]]
        let compareCount: Int
    }

    public init(tape: Tape) {
        self.tape = tape

        let initialFrame = tape.header.initialValues.map { BarState(id: UUID(), value: $0) }
        self.frame = initialFrame
        self.auxArrays = [:]
        self.compareCount = 0
        self.stepIndex = 0

        var checkpoints = [Checkpoint(step: 0, frame: initialFrame, auxArrays: [:], compareCount: 0)]
        var workingFrame = initialFrame
        var workingAuxArrays: [Int: [Int]] = [:]
        var workingCompareCount = 0
        for (index, operation) in tape.operations.enumerated() {
            Self.apply(operation, to: &workingFrame, auxArrays: &workingAuxArrays, compareCount: &workingCompareCount)
            let step = index + 1
            if step.isMultiple(of: Self.checkpointInterval) {
                checkpoints.append(Checkpoint(
                    step: step,
                    frame: workingFrame,
                    auxArrays: workingAuxArrays,
                    compareCount: workingCompareCount
                ))
            }
        }
        self.checkpoints = checkpoints
    }

    public func stepForward() {
        guard stepIndex < tape.operations.count else { return }
        Self.apply(tape.operations[stepIndex], to: &frame, auxArrays: &auxArrays, compareCount: &compareCount)
        stepIndex += 1
    }

    public func stepBackward() {
        guard stepIndex > 0 else { return }
        seek(to: stepIndex - 1)
    }

    public func seek(to index: Int) {
        pause()
        let target = max(0, min(index, tape.operations.count))
        let checkpoint = nearestCheckpoint(atOrBefore: target)
        frame = checkpoint.frame
        auxArrays = checkpoint.auxArrays
        compareCount = checkpoint.compareCount
        stepIndex = checkpoint.step
        while stepIndex < target {
            stepForward()
        }
    }

    /// Returns the playback `Task` so callers (e.g. `SortSession`) can `await` its completion
    /// instead of polling `isPlaying`.
    ///
    /// `onStep`, when provided, is called with each operation immediately after it's applied —
    /// this is the seam `SortSession` uses to fire audio per touched index (§3.1 of
    /// ARCHITECTURE_V2.md) without `SortEngineKit` itself knowing `AudioPlaying`/`AppSettings`
    /// exist. Deliberately scoped to this loop only, not `stepForward()` itself, so a future
    /// scrub UI (Phase 12) calling `stepForward()`/`stepBackward()`/`seek(to:)` directly never
    /// triggers audio from rapid manual scrubbing.
    @discardableResult
    public func play(operationsPerSecond: Double, onStep: ((SortOperation) -> Void)? = nil) -> Task<Void, Never> {
        isPlaying = true
        let task = Task { [weak self] in
            while let self, self.stepIndex < self.tape.operations.count, !Task.isCancelled {
                let operation = self.tape.operations[self.stepIndex]
                self.stepForward()
                onStep?(operation)
                try? await Task.sleep(for: .seconds(1.0 / operationsPerSecond))
            }
            self?.isPlaying = false
        }
        playbackTask = task
        return task
    }

    public func pause() {
        playbackTask?.cancel()
        isPlaying = false
    }

    /// Binary search for the latest checkpoint at or before `step` — `checkpoints` is sorted
    /// ascending by construction.
    private func nearestCheckpoint(atOrBefore step: Int) -> Checkpoint {
        var low = 0
        var high = checkpoints.count - 1
        var result = checkpoints[0]
        while low <= high {
            let mid = (low + high) / 2
            if checkpoints[mid].step <= step {
                result = checkpoints[mid]
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    private static func apply(
        _ operation: SortOperation,
        to frame: inout [BarState],
        auxArrays: inout [Int: [Int]],
        compareCount: inout Int
    ) {
        switch operation {
        case let .swap(i, j):
            let temp = frame[i].value
            frame[i].value = frame[j].value
            frame[j].value = temp
        case let .setValue(i, value):
            frame[i].value = value
        case let .mark(marker, index):
            frame[index].markers.insert(marker)
        case let .unmark(marker):
            for i in frame.indices { frame[i].markers.remove(marker) }
        case .unmarkAll:
            for i in frame.indices { frame[i].markers.removeAll() }
        case .compare:
            compareCount += 1
        case let .markSorted(i):
            frame[i].isSorted = true
        case let .auxCreate(handle, length):
            auxArrays[handle] = Array(repeating: 0, count: length)
        case let .auxWrite(handle, index, value):
            auxArrays[handle]![index] = value
        case let .auxDelete(handle):
            auxArrays.removeValue(forKey: handle)
        }
    }
}
