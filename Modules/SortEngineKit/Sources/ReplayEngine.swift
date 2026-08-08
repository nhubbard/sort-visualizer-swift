import Foundation
import Observation
import QuartzCore
import os

/// Labels `play()`'s per-tick batch-apply interval for a manual Instruments capture — the exact
/// mechanism behind a past perf bug (see `state`'s doc comment) was invisible in a generic Time
/// Profiler trace until it was traced back to this call by hand; a signpost interval here means a
/// future trace shows "TickApply" spans directly, with the batch size as its message, instead of
/// requiring that same manual detective work again.
private let replaySignposter = OSSignposter(
  subsystem: "com.nhubbard.Sort2.SortEngineKit", category: "ReplayEngine")

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
    /// Count of applied operations where `SortOperation.isSignificantForPacing` is `true` —
    /// the real-work numerator behind `RunControlBar`'s displayed "ops/sec" stat, matching
    /// exactly what `play()`'s pacing loop actually paces against. `stepIndex` alone would
    /// overstate throughput by however many bookkeeping mark/unmark entries rode along for
    /// free alongside each real step (see `play()`'s own doc comment).
    public internal(set) var significantOperationCount: Int

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
  /// `swapCount`/`mainWriteCount`/`auxWriteCount`/`reversalCount`/`stepIndex` below. These used to
  /// be five separate stored properties, each firing its own Observable dirty-propagation on every
  /// tick, which pegged the main thread in SwiftUI's AttributeGraph machinery rather than any view
  /// body. Bundling them into one value written exactly once per mutation
  /// (`stepForward`/`seek`/each `play()` tick) fixed it — any new ArrayV-parity statistic must be
  /// added as a `PlaybackState` field, not a separate stored property, or the fan-out returns.
  public private(set) var state: PlaybackState

  public var frame: [BarState] { state.frame }
  public var auxArrays: [Int: [Int]] { state.auxArrays }
  public var stepIndex: Int { state.stepIndex }
  public var compareCount: Int { state.compareCount }
  public var swapCount: Int { state.swapCount }
  public var mainWriteCount: Int { state.mainWriteCount }
  public var auxWriteCount: Int { state.auxWriteCount }
  public var reversalCount: Int { state.reversalCount }
  public var significantOperationCount: Int { state.significantOperationCount }

  /// Live element count across all currently-allocated auxiliary/scratch buffers (ArrayV's
  /// "Items in External Arrays" — `Writes.allocAmount`). Derived on demand from `auxArrays`
  /// rather than tracked as its own counter — the live buffer contents are already `state`,
  /// so a separate stored count would just be a second source of truth for the same number.
  public var externalArrayItemCount: Int {
    state.auxArrays.values.reduce(0) { $0 + $1.count }
  }

  /// A second, independent per-operation observer, orthogonal to `play(onStep:)`. Lets an
  /// incremental renderer repaint just the touched positions without `SortEngineKit`/
  /// `SortSession` needing to know renderers exist — set directly on the `ReplayEngine` instance a
  /// view holds. Fires immediately after `onStep`, with the same post-batch `frame` state.
  public var onOperationApplied: ((SortOperation) -> Void)?

  public private(set) var isPlaying = false

  /// Operations per second — a live knob, not a one-shot parameter: `play()`'s loop re-reads
  /// this on every iteration, so a caller (e.g. a run-control slider) can change it while
  /// replay is in progress and see the cadence change on the very next step. Only consulted when
  /// `useFixedDurationPacing` is `false`.
  public var speed: Double = 30.0

  /// Mode switch, live like `speed` — when `true`, `play()` paces against `targetDuration`
  /// instead of a flat `speed`, recomputing the required rate every tick from how much
  /// significant work and wall-clock time actually remain (see `play()`'s tick loop), so a run's
  /// length converges on `targetDuration` regardless of tape size or per-tick overhead, rather
  /// than approximating it from one upfront number.
  public var useFixedDurationPacing: Bool = false

  /// Target wall-clock length for the whole replay. Only consulted when `useFixedDurationPacing`
  /// is `true`.
  public var targetDuration: Double = 10.0

  /// The rate actually being applied as of the most recent tick — equal to `speed` in the flat
  /// mode, but the freshly recomputed deadline rate in fixed-duration mode (where `speed` itself
  /// stays an unrelated stored value). Updated once per tick (not per operation), so callers that
  /// need "the current cadence" for something other than the tick loop itself — e.g. sizing an
  /// audio note's hold duration in `SortSession.makeOnStepClosure` — read the real rate regardless
  /// of pacing mode, instead of `speed`, which is meaningless while fixed-duration pacing is on.
  public private(set) var currentPacingRate: Double = 30.0

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
  /// `currentSegmentStart` — shared by `pause()` and `play()`'s natural-completion path.
  /// Idempotent, so whichever of "tape ran out" or "user paused" happens first wins. Without
  /// closing on natural completion too, `elapsedPlaybackDuration`'s getter would keep growing on
  /// every read after a sort finishes on its own, since `RunControlBar` reads it every body
  /// evaluation.
  private func closeActiveSegmentIfNeeded() {
    if let currentSegmentStart {
      activePlaybackDuration += Date().timeIntervalSince(currentSegmentStart)
      self.currentSegmentStart = nil
    }
  }

  public let tape: Tape
  /// Every `checkpointInterval` operations, so `seek(to:)` never replays more than that many ops
  /// from the nearest one.
  private let checkpoints: [PlaybackState]
  private var playbackTask: Task<Void, Never>?
  /// The driver behind whatever `play()` call is currently in flight, kept here (not just
  /// captured locally inside `play()`'s `Task`) so `pause()` can silence it immediately instead
  /// of waiting for the `Task`'s own cancellation check to run on the next tick.
  private var activeDriver: DisplayLinkDriving?
  private let displayLinkFactory: () -> DisplayLinkDriving

  /// A checkpoint stores a full `PlaybackState` -- including `frame`/`auxArrays`, each O(N) --
  /// and each one crossed forces a copy-on-write duplication of those arrays on the next mutation.
  /// A fixed 500 was fine while every array topped out at 256 elements (`checkpointCount * N` was
  /// trivially small either way), but `effectiveSizeRange` now lets well-behaved algorithms run
  /// into the thousands while tape length stays capped near the same `operationCap` ceiling
  /// regardless of N -- so a fixed interval means `checkpointCount * N` (total checkpoint memory
  /// and the one-time `init` cost of building them) grows linearly with N alone. Scaling the
  /// interval with N keeps that product roughly constant instead: `checkpointCount` shrinks as N
  /// grows, trading a proportionally longer (but still fast to replay forward) worst-case `seek`
  /// distance on huge arrays for bounded memory and startup cost. `500` remains the floor, so
  /// nothing changes for every existing algorithm/test at N <= 500.
  static func checkpointInterval(forArrayCount n: Int) -> Int {
    Swift.max(500, n)
  }

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
      mainWriteCount: 0, auxWriteCount: 0, reversalCount: 0, stepIndex: 0,
      significantOperationCount: 0
    )
    self.state = initialState

    let checkpointInterval = Self.checkpointInterval(forArrayCount: initialFrame.count)
    var checkpoints = [initialState]
    var working = initialState
    let sortStartIndex = tape.header.sortStartIndex
    for operation in tape.operations {
      Self.apply(operation, to: &working, sortStartIndex: sortStartIndex)
      if working.stepIndex.isMultiple(of: checkpointInterval) {
        checkpoints.append(working)
      }
    }
    self.checkpoints = checkpoints
  }

  public func stepForward() {
    guard state.stepIndex < tape.operations.count else { return }
    mutatingState { working in
      Self.apply(
        tape.operations[working.stepIndex], to: &working,
        sortStartIndex: tape.header.sortStartIndex)
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
    let sortStartIndex = tape.header.sortStartIndex
    mutatingState { working in
      working = checkpoint
      while working.stepIndex < target {
        Self.apply(tape.operations[working.stepIndex], to: &working, sortStartIndex: sortStartIndex)
      }
    }
  }

  /// Routes the mutation through `@Observable`'s synthesized `_modify` accessor for `state` (via
  /// `&state`) rather than `var working = state; ...; state = working`, which would keep two
  /// references to `frame` alive until the write-back and force a copy-on-write copy on the first
  /// element mutation. `_modify` also calls `willSet`/`didSet` exactly once for the whole access
  /// instead of per assignment — incidental here since batched callers always mutate `state`
  /// directly; this helper exists for the copy-avoidance, not to dodge the equality check.
  private func mutatingState(_ body: (inout PlaybackState) -> Void) {
    body(&state)
  }

  /// Elapsed time between ticks is clamped to this before feeding the accumulator, so a real
  /// gap (backgrounding, a debugger pause, a genuine hitch) can't turn into one enormous burst
  /// of operations applied in a single tick.
  private static let maxCatchUpInterval: TimeInterval = 0.25

  /// Caps how many operations `play()`'s tick loop applies in one `mutatingState` call before
  /// yielding back to the run loop — a real, reported freeze on a throttled host (the iPadOS
  /// Simulator has no true vsync and can stall `CADisplayLink` under load): in fixed-duration
  /// mode, `effectiveSpeed` recomputes its rate from wall-clock `elapsedPlaybackDuration`, which
  /// keeps advancing even while no ticks arrive to make progress, so a stalled-then-recovered tick
  /// can compute a rate high enough that `opsToApply` wants the *entire remaining tape* applied in
  /// one shot. `maxCatchUpInterval` above bounds a tick's own elapsed time, but not `speed`/
  /// `effectiveSpeed` itself, so it doesn't help here. Applying in bounded chunks with a
  /// `Task.yield()` between them (see `play()`) spreads a huge burst across multiple run-loop
  /// turns instead of monopolizing the main actor for the whole thing — which both lets SwiftUI
  /// actually redraw along the way and stops the burst itself from further starving tick delivery
  /// (the freeze was compounding: no ticks -> huge rate -> long synchronous burst -> no ticks).
  private static let maxOperationsPerChunk = 2000

  /// The pure pacing math, factored out of `play()` so it's directly unit-testable without a
  /// driver: how many *significant* operations (see `SortOperation.isSignificantForPacing`) are
  /// due given `elapsed` real seconds at `speed` operations per second, carrying any fractional
  /// remainder forward in `accumulator` so slow speeds don't lose operations to rounding, and
  /// never returning more than `remaining` (raw tape entries left — a safe, if loose, upper
  /// bound, since the tape can never contain fewer significant entries than raw ones; `play()`'s
  /// own tick loop is what actually stops at the true end of tape).
  static func opsToApply(
    elapsed: TimeInterval, speed: Double, accumulator: inout Double, remaining: Int
  ) -> Int {
    accumulator += min(elapsed, maxCatchUpInterval) * speed
    let ops = min(Int(accumulator), remaining)
    accumulator -= Double(ops)
    return ops
  }

  /// The pacing rate to feed `opsToApply` this tick. `false` (`useFixedDurationPacing`) just
  /// passes `speed` through unchanged — today's flat-rate behavior. `true` recomputes a deadline
  /// rate every tick from how much significant work and wall-clock time actually remain, rather
  /// than a single rate computed once up front: if a tick runs slow for any reason,
  /// `elapsedPlaybackDuration` (real time) advances by that same amount regardless of how much
  /// work got done, so `remainingTime` shrinks and the next tick's rate rises to compensate —
  /// self-correcting toward `targetDuration` instead of drifting from a stale estimate. Flooring
  /// `remainingTime` (rather than special-casing "deadline passed") means at or past the deadline
  /// this naturally returns a huge rate that `opsToApply`'s own `min(Int(accumulator), remaining)`
  /// clamp saturates to "apply everything left this tick" — no separate catch-up path needed.
  ///
  /// Returns exactly `0` once `remainingSignificantOperationCount` reaches `0` — there's no rate
  /// left to divide toward. `play()`'s tick loop must never feed that straight into `opsToApply`
  /// (a `0` rate can never make progress, however much time passes) — it special-cases this by
  /// flushing whatever's left in the tape immediately instead. See `play()`'s own doc comment.
  static func effectiveSpeed(
    speed: Double, useFixedDurationPacing: Bool, targetDuration: Double,
    remainingSignificantOperationCount: Int, elapsedPlaybackDuration: TimeInterval
  ) -> Double {
    guard useFixedDurationPacing else { return speed }
    let remainingTime = max(targetDuration - elapsedPlaybackDuration, 0.001)
    return Double(remainingSignificantOperationCount) / remainingTime
  }

  /// Returns the playback `Task` so callers (e.g. `SortSession`) can `await` its completion
  /// instead of polling `isPlaying`.
  ///
  /// `onStep` fires per operation immediately after it's applied — the seam `SortSession` uses to
  /// fire audio per touched index without `SortEngineKit` knowing `AudioPlaying`/`AppSettings`
  /// exist. Scoped to this loop, not `stepForward()`, so scrubbing never triggers audio. `speed` is
  /// read fresh every tick so a live change takes effect immediately.
  ///
  /// Ticks come from `displayLinkFactory()` (real vsync via `CADisplayLinkDriver` in production, a
  /// deterministic fake in tests) rather than a sleep interval derived from `speed`, decoupling
  /// simulation (`opsToApply`'s uncapped `elapsed × speed` accumulator) from render — a faster
  /// machine just applies more operations per vsync interval. A tick with nothing due is skipped
  /// entirely, with no `mutatingState` write or redraw.
  ///
  /// `opsToApply` budgets only *significant* operations (`SortOperation.isSignificantForPacing`):
  /// bookkeeping `.mark`/`.unmarkIndex` entries around each `.compare`/`.swap` still apply, and
  /// still reach `onStep`/`onOperationApplied`, but don't count against the budget — otherwise a
  /// flat per-tick entry cap would spend most of it on marker bookkeeping instead of real
  /// algorithmic progress.
  ///
  /// In fixed-duration mode, once every significant operation has been applied there's nothing
  /// left for `effectiveSpeed` to pace against — it returns exactly `0`, and a `0` rate can never
  /// make progress through `opsToApply`'s `elapsed × speed` accumulator no matter how many more
  /// ticks arrive. But `SortSession.makeTape` always appends a trailing, non-significant
  /// `unmarkAll()` after the shuffle and after the sort (to retract whatever bar the algorithm's
  /// very last `compare`/`swap` highlighted), so every tape ends on exactly this kind of entry —
  /// without the flush below, fixed-duration replay would hang forever one cosmetic operation
  /// short of genuine completion, on every single run.
  @discardableResult
  public func play(onStep: ((SortOperation) -> Void)? = nil) -> Task<Void, Never> {
    isPlaying = true
    currentSegmentStart = Date()

    // Computed once per `play()` call (not per tick — this scans the whole tape) so the
    // fixed-duration branch below only ever needs an O(1) subtraction against the live
    // `state.significantOperationCount` counter to know how much work remains.
    let totalSignificantOperationCount = tape.significantOperationCount

    let driver = displayLinkFactory()
    activeDriver = driver
    let (stream, continuation) = AsyncStream<TimeInterval>.makeStream()
    driver.start { elapsed in continuation.yield(elapsed) }

    let task = Task { [weak self] in
      var accumulator = 0.0
      tickLoop: for await elapsed in stream {
        guard let self, !Task.isCancelled else { break }
        let remaining = self.tape.operations.count - self.state.stepIndex
        guard remaining > 0 else { break }
        let sortStartIndex = self.tape.header.sortStartIndex

        let remainingSignificantOperationCount =
          max(0, totalSignificantOperationCount - self.state.significantOperationCount)
        let effectiveSpeed = Self.effectiveSpeed(
          speed: self.speed,
          useFixedDurationPacing: self.useFixedDurationPacing,
          targetDuration: self.targetDuration,
          remainingSignificantOperationCount: remainingSignificantOperationCount,
          elapsedPlaybackDuration: self.elapsedPlaybackDuration
        )
        self.currentPacingRate = effectiveSpeed
        // See `effectiveSpeed`'s and this method's own doc comments: a `0` rate (only possible
        // in fixed-duration mode, once no significant work remains) can never clear the
        // cosmetic-only remainder through the normal accumulator math, so flush it directly.
        let opsToApply =
          self.useFixedDurationPacing && remainingSignificantOperationCount == 0
          ? remaining
          : Self.opsToApply(
            elapsed: elapsed, speed: effectiveSpeed, accumulator: &accumulator,
            remaining: remaining
          )
        guard opsToApply > 0 else { continue }

        // Applied in bounded chunks, yielding between them — see `maxOperationsPerChunk`'s doc
        // comment for the freeze this avoids. Identical to the old single-shot behavior whenever
        // `opsToApply <= maxOperationsPerChunk` (the overwhelming majority of ticks).
        var stillToApply = opsToApply
        while stillToApply > 0 {
          guard !Task.isCancelled else { break tickLoop }
          let chunkTarget = min(stillToApply, Self.maxOperationsPerChunk)

          var appliedOperations: [SortOperation] = []
          appliedOperations.reserveCapacity(chunkTarget)
          let tickInterval = replaySignposter.beginInterval(
            "TickApply", id: replaySignposter.makeSignpostID(), "\(chunkTarget) ops")
          self.mutatingState { working in
            var significantApplied = 0
            while significantApplied < chunkTarget, working.stepIndex < self.tape.operations.count {
              let operation = self.tape.operations[working.stepIndex]
              Self.apply(operation, to: &working, sortStartIndex: sortStartIndex)
              appliedOperations.append(operation)
              if operation.isSignificantForPacing {
                significantApplied += 1
              }
            }
          }
          replaySignposter.endInterval("TickApply", tickInterval)

          for operation in appliedOperations {
            onStep?(operation)
            onOperationApplied?(operation)
          }

          if self.state.stepIndex >= self.tape.operations.count { break tickLoop }
          stillToApply -= chunkTarget
          if stillToApply > 0 { await Task.yield() }
        }
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

  /// `sortStartIndex` gates the five ArrayV-parity counters (`compareCount`/`swapCount`/
  /// `mainWriteCount`/`auxWriteCount`/`reversalCount`) so a recorded shuffle's own operations
  /// (§2A.4, `TapeHeader.sortStartIndex`) animate the frame but never inflate the stats
  /// `RunControlBar` displays, matching `TapeHeader`'s already-sort-only totals. `state.stepIndex`
  /// here is still *pre-increment* (bumped at the end of this function) — the raw tape index of
  /// the operation being applied right now, exactly what needs comparing against `sortStartIndex`.
  private static func apply(
    _ operation: SortOperation, to state: inout PlaybackState, sortStartIndex: Int
  ) {
    let countsTowardStats = state.stepIndex >= sortStartIndex
    switch operation {
    case .swap(let i, let j):
      let temp = state.frame[i].value
      state.frame[i].value = state.frame[j].value
      state.frame[j].value = temp
      if countsTowardStats {
        state.swapCount += 1
        state.mainWriteCount += 2
      }
    case .setValue(let i, let value):
      state.frame[i].value = value
      if countsTowardStats {
        state.mainWriteCount += 1
      }
    case .mark(let marker, let index):
      state.frame[index].markers.insert(marker)
    case .unmark(let marker):
      for i in state.frame.indices { state.frame[i].markers.remove(marker) }
    case .unmarkIndex(let marker, let index):
      state.frame[index].markers.remove(marker)
    case .unmarkAll:
      for i in state.frame.indices { state.frame[i].markers.removeAll() }
    case .compare:
      if countsTowardStats {
        state.compareCount += 1
      }
    case .markSorted(let i):
      state.frame[i].isSorted = true
    case .auxCreate(let handle, let length):
      state.auxArrays[handle] = Array(repeating: 0, count: length)
    case .auxWrite(let handle, let index, let value):
      state.auxArrays[handle]![index] = value
      if countsTowardStats {
        state.auxWriteCount += 1
      }
    case .auxDelete(let handle):
      state.auxArrays.removeValue(forKey: handle)
    case .reversal:
      if countsTowardStats {
        state.reversalCount += 1
      }
    }
    if operation.isSignificantForPacing {
      state.significantOperationCount += 1
    }
    state.stepIndex += 1
  }
}
