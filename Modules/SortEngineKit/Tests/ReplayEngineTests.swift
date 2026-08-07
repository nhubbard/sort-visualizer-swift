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
  private func makeTape(
    initialValues: [Int], operations: [SortOperation], sortStartIndex: Int = 0
  ) -> Tape {
    Tape(
      header: TapeHeader(
        algorithmID: "test",
        initialValues: initialValues,
        visualSeed: 0,
        compareCount: 0,
        swapCount: 0,
        recordingDuration: 0,
        recordedAt: Date(timeIntervalSince1970: 0),
        sortStartIndex: sortStartIndex
      ),
      operations: operations
    )
  }

  @Test
  func stepForwardAppliesOperationsInOrder() {
    let tape = makeTape(
      initialValues: [3, 1, 2],
      operations: [
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
    engine.speed = 5.0  // 0.2s/op

    _ = engine.play()
    driver.fireTick(elapsed: 0)  // the very first tick always carries zero elapsed time
    driver.fireTick(elapsed: 0.1)  // 0.5 ops due at speed 5 — not enough to apply one yet
    try? await Task.sleep(for: .milliseconds(20))
    #expect(
      engine.stepIndex == 0, "half an operation's worth of elapsed time shouldn't apply anything")

    engine.speed = 100_000.0  // crank it up immediately, mid-playback
    driver.fireTick(elapsed: 1.0)  // hugely overdue at the new speed
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
    batched.speed = 100_000.0  // one tick's worth of elapsed time covers the whole tape

    let task = batched.play()
    driver.fireTick(elapsed: 0)
    driver.fireTick(elapsed: 1.0)  // 100,000 ops due, capped by `remaining` at exactly 50
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
    driver.fireTick(elapsed: 0)  // the very first tick always carries zero elapsed time
    driver.fireTick(elapsed: 0.05)  // 0.5 ops due — not enough
    try? await Task.sleep(for: .milliseconds(20))
    #expect(engine.stepIndex == 0)

    driver.fireTick(elapsed: 0.06)  // accumulator now at 1.1 ops due — exactly one applies
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
    driver.fireTick(elapsed: 0)  // the very first tick always carries zero elapsed time
    // Simulate one second of real 60Hz vsync ticks, split into 60 discrete frames.
    for _ in 0..<60 {
      driver.fireTick(elapsed: 1.0 / 60.0)
    }
    try? await Task.sleep(for: .milliseconds(50))

    #expect(abs(engine.stepIndex - 200) <= 1)
    engine.pause()
  }

  /// Direct regression test for the marker-bookkeeping throughput bug: `RecordingEngine`'s
  /// auto mark/unmark bookkeeping around every `.compare`/`.swap` must not eat into the pacing
  /// budget — a tape mixing bookkeeping with significant operations must play through its
  /// significant operations at (approximately) the configured `speed`, exactly as fast as an
  /// equivalent tape with no bookkeeping at all, since the bookkeeping now rides along for free.
  @Test
  func bookkeepingOperationsDoNotCountAgainstThePacingBudget() async {
    // 100 logical compares, each preceded by the same up-to-4-entry mark/unmark bookkeeping
    // `RecordingEngine.markPrimarySecondary` emits — 5 raw tape entries per logical compare
    // after the first. Old pacing (raw tape-entry count) would need 5x the ticks to apply all
    // 100 compares; new pacing (significant-op count) must apply all 100 in ~1 second.
    var recording = RecordingEngine(values: [1, 2])
    for _ in 0..<100 { _ = recording.compare(0, 1) }
    let operations = recording.finish().tape
    #expect(operations.count > 100 * 4, "sanity check: bookkeeping really does inflate this tape")

    let tape = makeTape(initialValues: [1, 2], operations: operations)
    let driver = ManualTickDriver()
    let engine = ReplayEngine(tape: tape, displayLinkFactory: { driver })
    engine.speed = 100.0  // 100 significant ops/sec

    _ = engine.play()
    driver.fireTick(elapsed: 0)  // the very first tick always carries zero elapsed time
    // Simulate slightly over one second of real 60Hz vsync ticks — a few extra ticks of
    // headroom past the exact 100-op budget absorbs floating-point summation error, without
    // which the old (pre-fix) behavior would still be nowhere close to finishing.
    for _ in 0..<65 {
      driver.fireTick(elapsed: 1.0 / 60.0)
    }
    try? await Task.sleep(for: .milliseconds(50))

    #expect(engine.compareCount == 100, "all 100 significant compares must finish within ~1s")
    #expect(engine.stepIndex == tape.operations.count, "and every bookkeeping entry along the way")
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
    let first = ReplayEngine.opsToApply(
      elapsed: 0.1, speed: 25.0, accumulator: &accumulator, remaining: 1000)
    let second = ReplayEngine.opsToApply(
      elapsed: 0.1, speed: 25.0, accumulator: &accumulator, remaining: 1000)
    let third = ReplayEngine.opsToApply(
      elapsed: 0.1, speed: 25.0, accumulator: &accumulator, remaining: 1000)

    #expect(first + second + third == 7)
    #expect(accumulator == 0.5)  // the 0.5 op not yet due is still waiting, not discarded
  }

  @Test
  func opsToApplyNeverExceedsRemaining() {
    var accumulator = 0.0
    let ops = ReplayEngine.opsToApply(
      elapsed: 1.0, speed: 100.0, accumulator: &accumulator, remaining: 3)
    #expect(ops == 3)
  }

  /// A pathologically large elapsed gap (backgrounding, a debugger pause, a genuine hitch) must
  /// not translate into a single tick applying thousands of operations — it should be clamped
  /// well below the raw, unclamped `elapsed * speed` value.
  @Test
  func opsToApplyClampsPathologicallyLargeElapsedTime() {
    var accumulator = 0.0
    let ops = ReplayEngine.opsToApply(
      elapsed: 1000.0, speed: 4.0, accumulator: &accumulator, remaining: 1_000_000)
    #expect(ops < 100)
  }

  @Test
  func effectiveSpeedPassesSpeedThroughUnchangedWhenFixedDurationPacingIsOff() {
    let rate = ReplayEngine.effectiveSpeed(
      speed: 42, useFixedDurationPacing: false, targetDuration: 10,
      remainingSignificantOperationCount: 1000, elapsedPlaybackDuration: 3)
    #expect(rate == 42)
  }

  @Test
  func effectiveSpeedDividesRemainingWorkByRemainingTimeWhenOn() {
    // 5s target, 2s elapsed -> 3s remaining; 300 significant ops remaining -> 100 ops/sec due.
    let rate = ReplayEngine.effectiveSpeed(
      speed: 1000, useFixedDurationPacing: true, targetDuration: 5,
      remainingSignificantOperationCount: 300, elapsedPlaybackDuration: 2)
    #expect(rate == 100)
  }

  /// The self-correcting property the deadline controller depends on: if two runs have the
  /// *same* remaining work but one has already burned more of its time budget (a slow tick, or
  /// simply more wall-clock having passed), the one with less time left must compute a higher
  /// rate — this is what makes the run converge on `targetDuration` rather than drift from a
  /// stale one-shot estimate.
  @Test
  func effectiveSpeedRisesAsElapsedTimeEatsIntoTheBudget() {
    let earlyRate = ReplayEngine.effectiveSpeed(
      speed: 1000, useFixedDurationPacing: true, targetDuration: 10,
      remainingSignificantOperationCount: 500, elapsedPlaybackDuration: 1)
    let lateRate = ReplayEngine.effectiveSpeed(
      speed: 1000, useFixedDurationPacing: true, targetDuration: 10,
      remainingSignificantOperationCount: 500, elapsedPlaybackDuration: 8)
    #expect(lateRate > earlyRate)
  }

  /// At or past the deadline, the controller must not divide by zero or go negative — it should
  /// instead saturate to an enormous rate, which `opsToApply`'s own `remaining` clamp then turns
  /// into "apply everything left this tick," guaranteeing the run can't hang past its deadline
  /// waiting on a rate that never arrives.
  @Test
  func effectiveSpeedSaturatesAtOrPastTheDeadlineInsteadOfDividingByZero() {
    let atDeadline = ReplayEngine.effectiveSpeed(
      speed: 1000, useFixedDurationPacing: true, targetDuration: 10,
      remainingSignificantOperationCount: 5000, elapsedPlaybackDuration: 10)
    let pastDeadline = ReplayEngine.effectiveSpeed(
      speed: 1000, useFixedDurationPacing: true, targetDuration: 10,
      remainingSignificantOperationCount: 5000, elapsedPlaybackDuration: 15)
    #expect(atDeadline > 100_000)
    #expect(pastDeadline > 100_000)

    var accumulator = 0.0
    let ops = ReplayEngine.opsToApply(
      elapsed: 1.0 / 60, speed: atDeadline, accumulator: &accumulator, remaining: 5000)
    #expect(ops == 5000)
  }

  @Test
  func auxArraysCreateWriteAndDeleteAcrossReplay() {
    let tape = makeTape(
      initialValues: [1, 2],
      operations: [
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

    let deleteTape = makeTape(
      initialValues: [1], operations: tape.operations + [.auxDelete(handle: 0)])
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
    seeking.seek(to: 733)  // deliberately not a checkpoint boundary
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
    let tape = makeTape(
      initialValues: [1, 2, 3],
      operations: [
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
    let tape = makeTape(
      initialValues: [1, 2, 3],
      operations: [
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
    engine.speed = 100_000.0  // one tick's worth of elapsed time covers the whole tape

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

  /// Direct test of the shuffle/sort stat-separation fix: operations before `sortStartIndex`
  /// (a recorded shuffle) must animate the frame but never move the live ArrayV-parity
  /// counters `RunControlBar` displays.
  @Test
  func shuffleOperationsDoNotIncrementLiveCountersUntilSortStartIndex() {
    let operations: [SortOperation] = [
      .compare(0, 1), .swap(0, 1), .compare(1, 2),  // "shuffle" — indices 0-2
      .compare(0, 1), .swap(0, 1)  // "sort" — indices 3-4
    ]
    let tape = makeTape(initialValues: [3, 1, 2], operations: operations, sortStartIndex: 3)
    let engine = ReplayEngine(tape: tape)

    for _ in 0..<3 { engine.stepForward() }
    #expect(engine.compareCount == 0)
    #expect(engine.swapCount == 0)
    #expect(engine.mainWriteCount == 0)
  }

  /// Counting must begin exactly at `sortStartIndex`, with no off-by-one in either direction.
  @Test
  func countingBeginsExactlyAtSortStartIndexWithNoOffByOne() {
    let operations: [SortOperation] = [
      .compare(0, 1), .swap(0, 1),  // shuffle — indices 0-1
      .swap(0, 1)  // sort — index 2, the first counted operation
    ]
    let tape = makeTape(initialValues: [3, 1, 2], operations: operations, sortStartIndex: 2)
    let engine = ReplayEngine(tape: tape)

    engine.stepForward()  // index 0: shuffle compare
    engine.stepForward()  // index 1: shuffle swap
    #expect(engine.compareCount == 0)
    #expect(engine.swapCount == 0)

    engine.stepForward()  // index 2: the first sort operation
    #expect(engine.swapCount == 1)
    #expect(engine.mainWriteCount == 2)
  }

  /// Scrubbing backward into the shuffle region must zero the gated counters again, and
  /// scrubbing forward past `sortStartIndex` must match a fresh, independently-stepped
  /// reference engine — the strongest guarantee against double-counting or missed counts
  /// across `seek(to:)`'s checkpoint-replay path.
  @Test
  func seekingBackwardIntoShuffleThenForwardPastSortStartProducesCorrectCounts() {
    let operations: [SortOperation] = (0..<1200).map { i in
      i.isMultiple(of: 2) ? .compare(0, 1) : .swap(0, 1)
    }
    let tape = makeTape(initialValues: [1, 2], operations: operations, sortStartIndex: 600)

    let engine = ReplayEngine(tape: tape)
    for _ in 0..<1000 { engine.stepForward() }
    #expect(engine.compareCount > 0)
    #expect(engine.swapCount > 0)

    engine.seek(to: 400)  // inside the shuffle region
    #expect(engine.compareCount == 0)
    #expect(engine.swapCount == 0)

    engine.seek(to: 900)  // past sortStartIndex
    let reference = ReplayEngine(tape: tape)
    for _ in 0..<900 { reference.stepForward() }
    #expect(engine.compareCount == reference.compareCount)
    #expect(engine.swapCount == reference.swapCount)
    #expect(engine.stepIndex == reference.stepIndex)
  }

  /// `sortStartIndex` deliberately falls strictly between two ~500-op checkpoint boundaries
  /// (`ReplayEngine.checkpointInterval`) — confirms checkpoints built in `init` already carry
  /// correctly-gated counts, with no extra boundary-awareness needed in `seek(to:)` itself.
  @Test
  func checkpointsStraddlingSortStartIndexProduceCorrectGatedCounts() {
    let operations: [SortOperation] = (0..<1200).map { i in
      i.isMultiple(of: 2) ? .compare(0, 1) : .swap(0, 1)
    }
    let tape = makeTape(initialValues: [1, 2], operations: operations, sortStartIndex: 550)

    let engine = ReplayEngine(tape: tape)
    engine.seek(to: 520)  // shuffle region, past the 500 checkpoint
    #expect(engine.compareCount == 0)
    #expect(engine.swapCount == 0)

    engine.seek(to: 700)  // past sortStartIndex; nearest checkpoint (500) is pre-boundary
    let reference = ReplayEngine(tape: tape)
    for _ in 0..<700 { reference.stepForward() }
    #expect(engine.compareCount == reference.compareCount)
    #expect(engine.swapCount == reference.swapCount)
  }

  // MARK: - Checkpoint interval scaling (see `checkpointInterval(forArrayCount:)`'s doc comment)

  /// A checkpoint stores a full O(N) `PlaybackState`; a fixed interval means total checkpoint
  /// memory/init cost grows linearly with N alone once `effectiveSizeRange` lets algorithms run at
  /// N well past the old 256-element cap. The interval scales with N above the 500 floor so
  /// `checkpointCount * N` stays roughly constant instead -- every existing algorithm/test stays
  /// at N <= 500 and sees the unchanged interval.
  @Test
  func checkpointIntervalScalesWithArrayCountButNeverBelowFiveHundred() {
    #expect(ReplayEngine.checkpointInterval(forArrayCount: 10) == 500)
    #expect(ReplayEngine.checkpointInterval(forArrayCount: 256) == 500)
    #expect(ReplayEngine.checkpointInterval(forArrayCount: 500) == 500)
    #expect(ReplayEngine.checkpointInterval(forArrayCount: 5000) == 5000)
  }

  /// Correctness regression at the array sizes the growth-model feature newly makes reachable --
  /// mirrors `seekToNonCheckpointIndexThenContinueMatchesUninterruptedStepping` above, but at
  /// N = 2000 (past the 500 floor, so the checkpoint interval is scaled rather than fixed) and
  /// seeking across multiple checkpoint boundaries at once.
  @Test
  func seekRemainsCorrectAtALargeArrayCountWithAScaledCheckpointInterval() {
    let n = 2000
    let initialValues = Array(0..<n)
    let operations: [SortOperation] = (0..<5000).map { .swap($0 % n, ($0 + 1) % n) }
    let tape = makeTape(initialValues: initialValues, operations: operations)

    let seeking = ReplayEngine(tape: tape)
    seeking.seek(to: 2500)  // deliberately not a multiple of the scaled interval (2000)

    let reference = ReplayEngine(tape: tape)
    for _ in 0..<2500 { reference.stepForward() }

    #expect(seeking.frame.map(\.value) == reference.frame.map(\.value))
    #expect(seeking.stepIndex == reference.stepIndex)
  }
}
