import Foundation
import Testing
@testable import SortEngineKit

/// Deterministic test stand-in for `DisplayLinkDriving` (see `ReplayEngine.swift`) — gives a test
/// full, instant control over "how much time just passed" via `fireTick(elapsed:)`, without
/// waiting on real time or depending on a real `CADisplayLink` firing inside this module's
/// host-less `.unitTests` bundle.
final class ManualTickDriver: DisplayLinkDriving {
    private var onTick: ((TimeInterval) -> Void)?

    func start(onTick: @escaping (TimeInterval) -> Void) {
        self.onTick = onTick
    }

    func stop() {
        onTick = nil
    }

    func fireTick(elapsed: TimeInterval) {
        onTick?(elapsed)
    }
}

@MainActor
@Suite
struct ReplayEngineTests {
    private func makeTape(initialValues: [Int], operations: [SortOperation]) -> Tape {
        Tape(
            header: TapeHeader(
                algorithmID: "test",
                initialValues: initialValues,
                visualSeed: 0,
                compareCount: 0,
                swapCount: 0,
                recordingDuration: 0,
                recordedAt: Date(timeIntervalSince1970: 0)
            ),
            operations: operations
        )
    }

    @Test
    func stepForwardAppliesOperationsInOrder() {
        let tape = makeTape(initialValues: [3, 1, 2], operations: [
            .mark(marker: Marker.primary, index: 0),
            .mark(marker: Marker.secondary, index: 1),
            .compare(0, 1),
            .swap(0, 1),
            .markSorted(0)
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(engine.frame.map(\.value) == [1, 3, 2])
        #expect(engine.frame[0].isSorted)
        #expect(engine.compareCount == 1)
        #expect(engine.swapCount == 1)
        // A swap is two array writes (ArrayV's `Writes.updateSwap` convention).
        #expect(engine.mainWriteCount == 2)
        #expect(engine.auxWriteCount == 0)
        #expect(engine.stepIndex == tape.operations.count)
    }

    @Test
    func seekToNonCheckpointIndexRestoresSwapCountAlongsideCompareCount() {
        let operations: [SortOperation] = (0..<1200).map { i in
            i.isMultiple(of: 2) ? .compare(0, 1) : .swap(0, 1)
        }
        let tape = makeTape(initialValues: [1, 2], operations: operations)

        let reference = ReplayEngine(tape: tape)
        for _ in 0..<900 { reference.stepForward() }

        let seeking = ReplayEngine(tape: tape)
        seeking.seek(to: 733)
        for _ in 733..<900 { seeking.stepForward() }

        #expect(seeking.swapCount == reference.swapCount)
    }

    /// The direct regression test for the reported bug: changing `speed` while `play()` is
    /// already running must change the cadence of the *current* replay, not just future ones.
    @Test
    func liveSpeedChangeDuringPlayAffectsCurrentReplayImmediately() async {
        let operations: [SortOperation] = (0..<20).map { _ in .compare(0, 1) }
        let tape = makeTape(initialValues: [1, 2], operations: operations)
        let driver = ManualTickDriver()
        let engine = ReplayEngine(tape: tape, displayLinkFactory: { driver })
        engine.speed = 5.0 // 0.2s/op

        _ = engine.play()
        driver.fireTick(elapsed: 0) // the very first tick always carries zero elapsed time
        driver.fireTick(elapsed: 0.1) // 0.5 ops due at speed 5 — not enough to apply one yet
        try? await Task.sleep(for: .milliseconds(20))
        #expect(engine.stepIndex == 0, "half an operation's worth of elapsed time shouldn't apply anything")

        engine.speed = 100_000.0 // crank it up immediately, mid-playback
        driver.fireTick(elapsed: 1.0) // hugely overdue at the new speed
        try? await Task.sleep(for: .milliseconds(20))

        // If `play()` had captured the original speed instead of reading it live, this would
        // still be stuck at step 0 after a mere 1.1s of simulated elapsed time (at 5 ops/sec).
        #expect(engine.stepIndex == tape.operations.count)
    }

    /// Regression test for the render-rate decoupling fix: batching operations per tick at high
    /// speed must not change *what* gets applied — every operation still lands in order, with the
    /// same final compare/swap counts as stepping through one at a time.
    @Test
    func highSpeedBatchedPlaybackAppliesEveryOperationInOrder() async {
        let operations: [SortOperation] = (0..<50).map { i in
            i.isMultiple(of: 2) ? .compare(0, 1) : .swap(0, 1)
        }
        let tape = makeTape(initialValues: [1, 2], operations: operations)

        let reference = ReplayEngine(tape: tape)
        for _ in 0..<operations.count { reference.stepForward() }

        let driver = ManualTickDriver()
        let batched = ReplayEngine(tape: tape, displayLinkFactory: { driver })
        batched.speed = 100_000.0 // one tick's worth of elapsed time covers the whole tape

        let task = batched.play()
        driver.fireTick(elapsed: 0)
        driver.fireTick(elapsed: 1.0) // 100,000 ops due, capped by `remaining` at exactly 50
        await task.value

        #expect(batched.stepIndex == reference.stepIndex)
        #expect(batched.frame.map(\.value) == reference.frame.map(\.value))
        #expect(batched.compareCount == reference.compareCount)
        #expect(batched.swapCount == reference.swapCount)
    }

    /// A tick whose elapsed time accumulates to less than one full operation at the configured
    /// `speed` must apply nothing at all — no operation, no `mutatingState` write — while the
    /// fractional remainder still carries forward, so the next tick that pushes the accumulator
    /// past 1.0 applies exactly the (single) operation now due.
    @Test
    func ticksBelowOneOperationsWorthOfElapsedTimeApplyNothingUntilEnoughAccumulates() async {
        let operations: [SortOperation] = (0..<3).map { _ in .compare(0, 1) }
        let tape = makeTape(initialValues: [1, 2], operations: operations)
        let driver = ManualTickDriver()
        let engine = ReplayEngine(tape: tape, displayLinkFactory: { driver })
        engine.speed = 10.0

        _ = engine.play()
        driver.fireTick(elapsed: 0) // the very first tick always carries zero elapsed time
        driver.fireTick(elapsed: 0.05) // 0.5 ops due — not enough
        try? await Task.sleep(for: .milliseconds(20))
        #expect(engine.stepIndex == 0)

        driver.fireTick(elapsed: 0.06) // accumulator now at 1.1 ops due — exactly one applies
        try? await Task.sleep(for: .milliseconds(20))
        #expect(engine.stepIndex == 1)

        engine.pause()
    }

    /// Direct regression test for the reported throughput ceiling: sustained playback at a
    /// configured `speed` must apply (approximately) that many operations per second of
    /// *simulated* elapsed time, regardless of how many discrete ticks that time is split across
    /// — the accumulator, not the tick count or any assumed render rate, governs throughput.
    @Test
    func sustainedPlaybackAtConfiguredSpeedAppliesApproximatelyThatManyOperations() async {
        let operations: [SortOperation] = (0..<200).map { _ in .compare(0, 1) }
        let tape = makeTape(initialValues: [1, 2], operations: operations)
        let driver = ManualTickDriver()
        let engine = ReplayEngine(tape: tape, displayLinkFactory: { driver })
        engine.speed = 200.0

        _ = engine.play()
        driver.fireTick(elapsed: 0) // the very first tick always carries zero elapsed time
        // Simulate one second of real 60Hz vsync ticks, split into 60 discrete frames.
        for _ in 0..<60 {
            driver.fireTick(elapsed: 1.0 / 60.0)
        }
        try? await Task.sleep(for: .milliseconds(50))

        #expect(abs(engine.stepIndex - 200) <= 1)
        engine.pause()
    }

    /// The pure accumulator underlying `play()`'s pacing, tested directly without any driver: no
    /// operation is ever lost to rounding — a fractional remainder from one call carries forward
    /// into the next.
    @Test
    func opsToApplyCarriesFractionalRemainderForwardAcrossCalls() {
        var accumulator = 0.0
        // 3 ticks of 0.1 simulated seconds each (well under the 0.25s catch-up clamp) at 25
        // ops/sec = 2.5 ops due per tick, 7.5 ops due in total.
        let first = ReplayEngine.opsToApply(elapsed: 0.1, speed: 25.0, accumulator: &accumulator, remaining: 1000)
        let second = ReplayEngine.opsToApply(elapsed: 0.1, speed: 25.0, accumulator: &accumulator, remaining: 1000)
        let third = ReplayEngine.opsToApply(elapsed: 0.1, speed: 25.0, accumulator: &accumulator, remaining: 1000)

        #expect(first + second + third == 7)
        #expect(accumulator == 0.5) // the 0.5 op not yet due is still waiting, not discarded
    }

    @Test
    func opsToApplyNeverExceedsRemaining() {
        var accumulator = 0.0
        let ops = ReplayEngine.opsToApply(elapsed: 1.0, speed: 100.0, accumulator: &accumulator, remaining: 3)
        #expect(ops == 3)
    }

    /// A pathologically large elapsed gap (backgrounding, a debugger pause, a genuine hitch) must
    /// not translate into a single tick applying thousands of operations — it should be clamped
    /// well below the raw, unclamped `elapsed * speed` value.
    @Test
    func opsToApplyClampsPathologicallyLargeElapsedTime() {
        var accumulator = 0.0
        let ops = ReplayEngine.opsToApply(elapsed: 1000.0, speed: 4.0, accumulator: &accumulator, remaining: 1_000_000)
        #expect(ops < 100)
    }

    @Test
    func auxArraysCreateWriteAndDeleteAcrossReplay() {
        let tape = makeTape(initialValues: [1, 2], operations: [
            .auxCreate(handle: 0, length: 2),
            .auxWrite(handle: 0, index: 0, value: 9),
            .auxWrite(handle: 0, index: 1, value: 4)
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(engine.auxArrays[0] == [9, 4])
        #expect(engine.auxWriteCount == 2)
        #expect(engine.mainWriteCount == 0)
        // `auxCreate` allocates a 2-element buffer up front — "items in external arrays" reflects
        // the live buffer size, not the number of writes into it.
        #expect(engine.externalArrayItemCount == 2)

        let deleteTape = makeTape(initialValues: [1], operations: tape.operations + [.auxDelete(handle: 0)])
        let deleteEngine = ReplayEngine(tape: deleteTape)
        for _ in 0..<deleteTape.operations.count { deleteEngine.stepForward() }
        #expect(deleteEngine.auxArrays[0] == nil)
        #expect(deleteEngine.externalArrayItemCount == 0)
    }

    @Test
    func reversalMarkerIsStructurallyInertButCountsAndStepsLikeAnyOtherOperation() {
        var recording = RecordingEngine(values: [1, 2, 3, 4, 5])
        recording.reversal(0, 4)
        let tape = makeTape(initialValues: [1, 2, 3, 4, 5], operations: recording.finish().tape)

        let engine = ReplayEngine(tape: tape)
        // Step to just past the `.reversal` marker itself (before the swaps it's built from) —
        // it must count immediately without touching `frame`, matching `.compare`'s "counted,
        // structurally inert" behavior.
        engine.stepForward()
        #expect(engine.reversalCount == 1)
        #expect(engine.frame.map(\.value) == [1, 2, 3, 4, 5])

        for _ in 1..<tape.operations.count { engine.stepForward() }
        #expect(engine.frame.map(\.value) == [5, 4, 3, 2, 1])
        #expect(engine.reversalCount == 1)
        #expect(engine.swapCount == 2)
    }

    @Test
    func seekToNonCheckpointIndexThenContinueMatchesUninterruptedStepping() {
        // 1,200 operations spans more than two ~500-op checkpoint boundaries.
        let operations: [SortOperation] = (0..<1200).map { i in
            i.isMultiple(of: 2) ? .compare(0, 1) : .swap(0, 1)
        }
        let tape = makeTape(initialValues: [1, 2], operations: operations)

        let reference = ReplayEngine(tape: tape)
        for _ in 0..<900 { reference.stepForward() }

        let seeking = ReplayEngine(tape: tape)
        seeking.seek(to: 733) // deliberately not a checkpoint boundary
        for _ in 733..<900 { seeking.stepForward() }

        #expect(seeking.frame.map(\.value) == reference.frame.map(\.value))
        #expect(seeking.compareCount == reference.compareCount)
        #expect(seeking.stepIndex == reference.stepIndex)
    }

    @Test
    func stepBackwardMatchesReDerivingFromScratch() {
        let operations: [SortOperation] = [
            .compare(0, 1), .swap(0, 1),
            .compare(1, 2), .swap(1, 2),
            .markSorted(2)
        ]
        let tape = makeTape(initialValues: [3, 1, 2], operations: operations)

        let engine = ReplayEngine(tape: tape)
        for _ in 0..<4 { engine.stepForward() }
        engine.stepBackward()

        let fresh = ReplayEngine(tape: tape)
        for _ in 0..<3 { fresh.stepForward() }

        #expect(engine.frame.map(\.value) == fresh.frame.map(\.value))
        #expect(engine.frame.map(\.isSorted) == fresh.frame.map(\.isSorted))
        #expect(engine.stepIndex == fresh.stepIndex)
    }

    @Test
    func unmarkClearsMarkerFromEveryIndexNotJustOne() {
        let tape = makeTape(initialValues: [1, 2, 3], operations: [
            .mark(marker: Marker.pivot, index: 0),
            .mark(marker: Marker.pivot, index: 2),
            .unmark(marker: Marker.pivot)
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(engine.frame.allSatisfy { !$0.markers.contains(Marker.pivot) })
    }

    @Test
    func unmarkIndexClearsOnlyTheOneIndexNotEveryIndex() {
        let tape = makeTape(initialValues: [1, 2, 3], operations: [
            .mark(marker: Marker.primary, index: 0),
            .mark(marker: Marker.primary, index: 2),
            .unmarkIndex(marker: Marker.primary, index: 0)
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(!engine.frame[0].markers.contains(Marker.primary))
        #expect(engine.frame[2].markers.contains(Marker.primary))
    }

    /// End-to-end regression test for the "everything turns red and stays red" bug: recording a
    /// realistic sequence of compares/swaps (not just replaying hand-authored ops) must leave at
    /// most one index carrying `.primary` and one carrying `.secondary` at any point along the
    /// tape, never an ever-growing accumulation of every index a sort has ever touched.
    @Test
    func recordedComparesAndSwapsNeverLeaveMoreThanOnePrimaryOrSecondaryMarkedAtOnce() {
        var recording = RecordingEngine(values: [5, 3, 8, 1, 9, 2])
        _ = recording.compare(0, 1)
        recording.swap(0, 1)
        _ = recording.compare(1, 2)
        _ = recording.compare(2, 3)
        recording.swap(2, 3)
        _ = recording.compare(3, 4)
        recording.swap(3, 4)
        let operations = recording.finish().tape

        let tape = makeTape(initialValues: [5, 3, 8, 1, 9, 2], operations: operations)
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count {
            engine.stepForward()
            let primaryCount = engine.frame.filter { $0.markers.contains(Marker.primary) }.count
            let secondaryCount = engine.frame.filter { $0.markers.contains(Marker.secondary) }.count
            #expect(primaryCount <= 1)
            #expect(secondaryCount <= 1)
        }
    }

    /// Regression test for a real bug found while wiring up persisted playback timing: `play()`'s
    /// natural-completion path (the tape running out, as opposed to an explicit `pause()`) used to
    /// skip closing the active timing segment, so `elapsedPlaybackDuration`'s getter — which adds
    /// live `Date()` time for any still-open segment — kept growing on every subsequent read, with
    /// no bound, until the next `pause()`/`seek(to:)` happened to close it. Two reads with real
    /// time elapsing in between, after the tape has genuinely finished, must return the same value.
    @Test
    func elapsedPlaybackDurationStopsGrowingAfterNaturalCompletion() async {
        let operations: [SortOperation] = (0..<3).map { _ in .compare(0, 1) }
        let tape = makeTape(initialValues: [1, 2], operations: operations)
        let driver = ManualTickDriver()
        let engine = ReplayEngine(tape: tape, displayLinkFactory: { driver })
        engine.speed = 100_000.0 // one tick's worth of elapsed time covers the whole tape

        let task = engine.play()
        driver.fireTick(elapsed: 0)
        driver.fireTick(elapsed: 1.0)
        await task.value
        #expect(engine.stepIndex == tape.operations.count, "the tape must have genuinely finished")

        let firstRead = engine.elapsedPlaybackDuration
        try? await Task.sleep(for: .milliseconds(50))
        let secondRead = engine.elapsedPlaybackDuration

        #expect(firstRead == secondRead)
    }

    /// Same guarantee, but for the already-working `pause()` path — a regression check that
    /// extracting `closeActiveSegmentIfNeeded()` out of `pause()` (to share it with the natural-
    /// completion fix above) didn't change `pause()`'s own existing behavior.
    @Test
    func elapsedPlaybackDurationStopsGrowingAfterPause() async {
        let operations: [SortOperation] = (0..<3).map { _ in .compare(0, 1) }
        let tape = makeTape(initialValues: [1, 2], operations: operations)
        let driver = ManualTickDriver()
        let engine = ReplayEngine(tape: tape, displayLinkFactory: { driver })
        engine.speed = 10.0

        _ = engine.play()
        driver.fireTick(elapsed: 0)
        driver.fireTick(elapsed: 0.1)
        try? await Task.sleep(for: .milliseconds(20))
        engine.pause()

        let firstRead = engine.elapsedPlaybackDuration
        try? await Task.sleep(for: .milliseconds(50))
        let secondRead = engine.elapsedPlaybackDuration

        #expect(firstRead == secondRead)
    }
}
