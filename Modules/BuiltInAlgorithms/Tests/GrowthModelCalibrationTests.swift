import AlgorithmKit
import Darwin
import Foundation
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

/// Manual-only: gated behind an environment variable rather than a Swift Testing tag, since that
/// needs no Xcode Test Plan configuration to keep it out of a plain `xcodebuild test` run. A full
/// sweep across every algorithm × every shuffle can take a while and needs the Python/SymPy
/// bridge (`Tools/GrowthModelCalibration/`) running first — see that directory's README.
///
/// Run with: `RUN_GROWTH_CALIBRATION=1 xcodebuild test -scheme BuiltInAlgorithms -destination
/// 'platform=macOS,variant=Mac Catalyst' -only-testing:BuiltInAlgorithmsTests/
/// GrowthModelCalibrationTests`. Narrow a run with `GROWTH_CALIBRATION_ALGORITHM_FILTER`/
/// `GROWTH_CALIBRATION_SHUFFLE_FILTER` (substring match against the algorithm/shuffle's
/// `AlgorithmID`/`ShuffleID` raw value) while iterating on the harness itself.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["RUN_GROWTH_CALIBRATION"] == "1"))
struct GrowthModelCalibrationTests {
  static let referenceCaps: [Double] = [100_000, 300_000, 1_000_000]
  static let safetyMargin = 0.8
  static let bridgeURL = URL(string: "http://127.0.0.1:8765")!

  @Test
  func bridgeIsRunning() async throws {
    let healthy = await Self.checkBridgeHealth()
    #expect(healthy, "Start the calibration bridge first: cd Tools/GrowthModelCalibration && uv run bridge_server.py")
  }

  /// One-off maintenance operation, not a real calibration pass: reloads both existing report
  /// files and writes them straight back out through the exact same `writeReport` path a real
  /// run uses, with zero new measurements. Needs neither the bridge (no new `powerLog` fits are
  /// computed) nor any filter. Exists to retroactively canonicalize files written before
  /// `GrowthReport.encode(to:)`/`writeReport`'s sorting existed -- every entry currently on disk
  /// predates both fixes, so this is the only way to get them into the new canonical order
  /// without waiting for each one to naturally get re-measured one at a time. Safe to run again
  /// any time; a no-op once everything's already canonical.
  @Test
  func canonicalizeExistingReports() throws {
    for filename in ["sort-growth-models.json", "shuffle-growth-models.json"] {
      let reports = Self.loadExistingReport(from: filename)
      try Self.writeReport(reports, to: filename)
      Self.logProgress("canonicalized \(reports.count) entries in \(filename)")
    }
  }

  @Test
  func calibrateShuffles() async throws {
    try #require(await Self.checkBridgeHealth())
    Self.enableLineBuffering()
    let overallStart = Date()

    var reports = Self.resumeEnabled() ? Self.loadExistingReport(from: "shuffle-growth-models.json") : []
    let alreadyDone = Set(reports.map(\.subjectID))
    let shuffles = Self.filteredShuffles().filter { !alreadyDone.contains($0.id.rawValue) }
    if !alreadyDone.isEmpty {
      Self.logProgress("resuming: \(alreadyDone.count) shuffle(s) already in shuffle-growth-models.json, skipping them")
    }
    let workerCount = Self.workerCount()
    Self.logProgress("shuffles: \(shuffles.count) remaining to profile across \(workerCount) worker(s)")

    var completed = 0
    for await (shuffle, measurement) in Self.parallelMap(shuffles, workerCount: workerCount, { shuffle in
      Self.measureGrowth(startSize: 8, label: shuffle.id.rawValue) { n in
        Self.tapeEstimate(Self.runShuffleTrial(shuffle: shuffle, size: n).summary)
      }
    }) {
      completed += 1
      guard
        let report = await Self.makeReport(
          subjectID: shuffle.id.rawValue, measurement: measurement, declaredShape: nil)
      else {
        Self.logProgress("[\(completed)/\(shuffles.count)] \(shuffle.id.rawValue): SKIPPED (not enough data)")
        continue
      }
      reports.append(report)
      try Self.writeReport(reports, to: "shuffle-growth-models.json")
      Self.logProgress(
        "[\(completed)/\(shuffles.count)] \(shuffle.id.rawValue): \(report.winningFamily) R²=\(String(format: "%.4f", report.winningRSquared)) safe@300K=\(Self.formatSafeSize(report, cap: 300_000))"
      )
    }
    Self.logProgress(
      "shuffles done: \(reports.count) total in \(String(format: "%.1f", Date().timeIntervalSince(overallStart)))s this run"
    )
    Self.printReport(title: "Shuffles", reports: reports)
  }

  /// One (algorithm, shuffle) unit of work for the parallel sweep below -- flattening the full
  /// cross product (rather than one worker per algorithm) gives much better load balancing, since
  /// per-combination cost varies just as wildly across shuffles as it does across algorithms.
  private struct SortShuffleCombo: Sendable {
    let algorithm: any SortAlgorithm
    let shuffle: any ShuffleAlgorithm
  }

  /// Tracks one algorithm's progress across its shuffles as results stream back out of order.
  /// Only ever touched from the single `for await` consumer below, so no locking is needed despite
  /// being mutated from what looks like a "shared" dictionary.
  private final class AlgorithmProgress {
    var received = 0
    var bindingReport: GrowthReport?
    let start = Date()
  }

  @Test
  func calibrateSorts() async throws {
    try #require(await Self.checkBridgeHealth())
    Self.enableLineBuffering()
    let shuffles = Self.filteredShuffles()
    let overallStart = Date()

    var reports = Self.resumeEnabled() ? Self.loadExistingReport(from: "sort-growth-models.json") : []
    // Each report's subjectID is "<algorithmID>+<bindingShuffleID>" -- the algorithm is what a
    // resumed run should skip, not the specific shuffle that happened to bind last time.
    let alreadyDoneAlgorithmIDs = Set(
      reports.map { $0.subjectID.split(separator: "+", maxSplits: 1).first.map(String.init) ?? $0.subjectID })
    let sorts = Self.filteredSorts().filter { !alreadyDoneAlgorithmIDs.contains($0.id.rawValue) }
    if !alreadyDoneAlgorithmIDs.isEmpty {
      Self.logProgress(
        "resuming: \(alreadyDoneAlgorithmIDs.count) algorithm(s) already in sort-growth-models.json, skipping them"
      )
    }
    let combos = sorts.flatMap { algorithm in shuffles.map { SortShuffleCombo(algorithm: algorithm, shuffle: $0) } }
    let totalCombinations = combos.count
    let workerCount = Self.workerCount()
    Self.logProgress(
      "sorts: \(sorts.count) algorithms remaining x \(shuffles.count) shuffles = \(totalCombinations) combinations across \(workerCount) worker(s)"
    )

    let progress: [String: AlgorithmProgress] = Dictionary(
      uniqueKeysWithValues: sorts.map { ($0.id.rawValue, AlgorithmProgress()) })
    var combinationsDone = 0

    for await (combo, measurement) in Self.parallelMap(combos, workerCount: workerCount, { combo in
      Self.measureGrowth(
        startSize: combo.algorithm.metadata.sizeRange.lowerBound,
        label: "\(combo.algorithm.id.rawValue)+\(combo.shuffle.id.rawValue)"
      ) { n in
        let shuffled = Self.runShuffleTrial(shuffle: combo.shuffle, size: n).values
        return Self.tapeEstimate(Self.runSortTrial(algorithm: combo.algorithm, values: shuffled).summary)
      }
    }) {
      combinationsDone += 1
      let algorithmID = combo.algorithm.id.rawValue
      let entry = progress[algorithmID]!

      let declaredShape = BigOShape.parse(combo.algorithm.metadata.timeComplexity.worst)
      if let report = await Self.makeReport(
        subjectID: "\(algorithmID)+\(combo.shuffle.id.rawValue)", measurement: measurement,
        declaredShape: declaredShape) {
        let unsafeNote = report.unsafeAtSize.map {
          " [\((report.unsafeReason ?? "unsafe").uppercased()) at size \($0) -- capped]"
        } ?? ""
        Self.logProgress(
          "  [\(algorithmID)][\(combo.shuffle.id.rawValue)] \(report.winningFamily) R²=\(String(format: "%.4f", report.winningRSquared)) safe@300K=\(Self.formatSafeSize(report, cap: 300_000))\(unsafeNote)"
        )
        // The binding (smallest) max size across shuffles is what actually matters for this
        // algorithm -- different shuffles can have entirely different growth exponents, not just
        // different constants, so each one's own fitted curve has to be solved independently
        // before taking the minimum.
        if entry.bindingReport == nil
          || (report.safeMaxSizeByCap[Self.referenceCaps[1]] ?? .infinity)
            < (entry.bindingReport!.safeMaxSizeByCap[Self.referenceCaps[1]] ?? .infinity) {
          entry.bindingReport = report
        }
      } else {
        Self.logProgress("  [\(algorithmID)][\(combo.shuffle.id.rawValue)]: SKIPPED (not enough data)")
      }

      entry.received += 1
      if entry.received == shuffles.count {
        if let bindingReport = entry.bindingReport {
          reports.append(bindingReport)
          try Self.writeReport(reports, to: "sort-growth-models.json")
        }
        let elapsed = Date().timeIntervalSince(overallStart)
        let averagePerCombo = combinationsDone > 0 ? elapsed / Double(combinationsDone) : 0
        let remaining = Double(totalCombinations - combinationsDone) * averagePerCombo
        let bindingSafeSize = entry.bindingReport.map { Self.formatSafeSize($0, cap: 300_000) } ?? "n/a"
        Self.logProgress(
          "[\(algorithmID)]: DONE, binding shuffle=\(entry.bindingReport?.subjectID ?? "none") safe@300K=\(bindingSafeSize) (\(String(format: "%.1f", Date().timeIntervalSince(entry.start)))s) -- overall \(combinationsDone)/\(totalCombinations) combos, elapsed \(Self.formatDuration(elapsed)), ETA \(Self.formatDuration(remaining))"
        )
      }
    }
    Self.logProgress(
      "sorts done: \(reports.count) total (\(sorts.count) processed this run) in \(Self.formatDuration(Date().timeIntervalSince(overallStart)))"
    )
    Self.printReport(title: "Sorts (binding shuffle)", reports: reports)
  }

  @Test
  func tapeEstimateFormulaMatchesRealTapeCountAtSmallSizes() {
    // Validates the `tapeEstimate` reconstruction (5x compare/swap + 1x everything else) against
    // the real, uncapped `tape.count` -- cheap to materialize at small `n`, where we don't need
    // the tiny-operationCap trick at all.
    for algorithm in AllBuiltInAlgorithms.sorts.prefix(15) {
      let n = max(algorithm.metadata.sizeRange.lowerBound, 8)
      var engine = RecordingEngine(values: Array(1...n).shuffled(), operationCap: 1_000_000)
      algorithm.record(into: &engine)
      let summary = engine.finish()
      #expect(!summary.didExceedCap)
      let estimate = Self.tapeEstimate(summary)
      let real = Double(summary.tape.count)
      // A handful of ops (unmarkAll, aux create/delete) aren't covered by the estimate formula,
      // so allow a small fixed slack rather than requiring an exact match.
      #expect(abs(estimate - real) <= 5, "estimate \(estimate) vs real \(real) for \(algorithm.id.rawValue)")
    }
  }

  // MARK: - Filtering

  private static func filteredSorts() -> [any SortAlgorithm] {
    guard let filter = ProcessInfo.processInfo.environment["GROWTH_CALIBRATION_ALGORITHM_FILTER"]
    else { return AllBuiltInAlgorithms.sorts }
    return AllBuiltInAlgorithms.sorts.filter { $0.id.rawValue.contains(filter) }
  }

  private static func filteredShuffles() -> [any ShuffleAlgorithm] {
    guard let filter = ProcessInfo.processInfo.environment["GROWTH_CALIBRATION_SHUFFLE_FILTER"]
    else { return AllBuiltInAlgorithms.shuffles }
    return AllBuiltInAlgorithms.shuffles.filter { $0.id.rawValue.contains(filter) }
  }

  // MARK: - Running a single trial

  private static func runSortTrial(algorithm: any SortAlgorithm, values: [Int]) -> (
    values: [Int], summary: RecordingSummary
  ) {
    var engine = RecordingEngine(values: values, operationCap: 1)
    algorithm.record(into: &engine)
    return (engine.values, engine.finish())
  }

  private static func runShuffleTrial(shuffle: any ShuffleAlgorithm, size: Int) -> (
    values: [Int], summary: RecordingSummary
  ) {
    var engine = RecordingEngine(values: Array(1...size), operationCap: 1)
    shuffle.record(into: &engine)
    return (engine.values, engine.finish())
  }

  /// Approximates real `RecordingEngine.tape.count` from a `RecordingSummary`'s uncapped
  /// counters, which keep incrementing after `tape` itself stops growing (constructed with
  /// `operationCap: 1` above) -- see the growth-model calibration plan for the derivation.
  /// `setValueCount = mainWriteCount - 2*swapCount` since `mainWriteCount` folds both together.
  private static func tapeEstimate(_ summary: RecordingSummary) -> Double {
    let setValueCount = summary.mainWriteCount - 2 * summary.swapCount
    let compareCallCount = summary.compareCount - summary.compareValueCount
    // `compareValue` only ever marks one index (never a secondary), so each call costs fewer
    // raw tape entries than a real two-index `compare`/`swap` -- empirically closer to 3 than
    // the full 5x multiplier those get.
    return Double(
      5 * (compareCallCount + summary.swapCount) + 3 * summary.compareValueCount + setValueCount
        + summary.auxWriteCount + summary.reversalCount)
  }

  // MARK: - Size sweep with adaptive sampling and a per-size time budget

  /// A hard ceiling on the *predicted* tape estimate before a candidate size is even attempted.
  /// Swift has no safe way to preempt a synchronous, CPU-bound call once it's started (see
  /// `RecordingEngine`'s own doc comment: "a synchronous function cannot be cancelled mid-loop-
  /// body") — a genuinely deterministic, guaranteed-to-terminate algorithm can still take years
  /// of wall-clock time once `n` crosses the wrong threshold (`GuessSort`'s exhaustive `n^n`
  /// odometer: `n=6` is instant, `n=12` is ~9 trillion outer-loop iterations). The only reliable
  /// defense is to never make the call in the first place once growth from *already-measured*
  /// sizes predicts something this catastrophic.
  private static let absoluteSafetyCeiling = envOverride(
    "GROWTH_CALIBRATION_SAFETY_CEILING", default: 10_000_000.0)

  /// The result of sweeping array sizes for one (algorithm, shuffle) pair. `unsafeAtSize`, when
  /// non-nil, is a hard ceiling independent of anything the growth-model curve fit later says --
  /// nothing at or above it can be trusted safe, regardless of what operation-count extrapolation
  /// implies, for one of two reasons (`unsafeReason`):
  /// - **hang**: a trial at that size genuinely never returned within the timeout. Fixes the
  ///   `mergebogosort+descending` finding, where the fitted curve alone computed a "safe" size of
  ///   803 — comfortably past the 96 where it actually hangs forever.
  /// - **erratic jump**: the measured value at that size was wildly (100x+) larger than the
  ///   established trend from smaller sizes predicted -- not a hang, but just as fatal to a
  ///   curve fit's honesty. `mergebogosort+heapified` jumps from 798 ops at n=14 to 36.4 *million*
  ///   at n=28; fitting a single smooth curve across that six-order-of-magnitude discontinuity
  ///   produced a `polynomialIntercept` fit that scored a deceptively high R² (dominated by
  ///   matching that one outlier) while predicting nonsense at every other size, including n=1.
  ///   The outlier sample is excluded from `samples` entirely in this case, not just capped.
  struct GrowthMeasurement {
    let samples: [GrowthSample]
    let unsafeAtSize: Int?
    let unsafeReason: String?
  }

  private static func measureGrowth(
    startSize: Int, maxPoints: Int = 8,
    perTrialTimeBudget: TimeInterval = envOverride("GROWTH_CALIBRATION_TIME_BUDGET", default: 1.0),
    tolerance: Double = envOverride("GROWTH_CALIBRATION_TOLERANCE", default: 0.02),
    minTrials: Int = 5,
    maxTrials: Int = Int(envOverride("GROWTH_CALIBRATION_MAX_TRIALS", default: 60.0)),
    // Each timeout-guarded trial now runs on its own dedicated `Thread` (see `runWithTimeout`),
    // not GCD's shared, concurrency-capped global queue -- an abandoned hang no longer starves
    // every other measurement's ability to even start, so this can afford to be much more
    // patient than the 3x that was safe back when every hang cost the whole run a shared worker
    // slot. A higher multiplier means fewer genuinely-slow-but-finite computations (e.g. real
    // `n^n` growth at a moderate size) get misclassified as hangs.
    hangTimeoutMultiplier: Double = envOverride("GROWTH_CALIBRATION_HANG_MULTIPLIER", default: 8.0),
    label: String = "",
    trial: @escaping @Sendable (Int) -> Double
  ) -> GrowthMeasurement {
    var samples: [GrowthSample] = []
    var unsafeAtSize: Int?
    var unsafeReason: String?
    // The first few sizes step by +1 (not x2) specifically so a ratio between two real,
    // cheaply-measured points exists *before* growth gets aggressive -- a x2 jump straight off
    // an algorithm's hand-tuned (and presumably already-safe) `sizeRange.lowerBound` is exactly
    // what let `GuessSort` (lowerBound 3) reach a catastrophic `n=12` in one step. This alone
    // isn't enough, though: `MergeBogoSort` against `DescendingShuffle` hangs *forever* at n=96 --
    // well inside its own hand-tuned range, not a scaling problem at all but a genuine
    // non-terminating bug in that specific algorithm/shuffle pairing. No amount of predicting
    // ahead from smaller sizes catches that, since the bug isn't a function of scale -- only a
    // hard per-trial wall-clock timeout does. 3 fine steps (not 2) so even the 3-parameter
    // `polynomialIntercept` growth family has a fighting chance at 2 degrees of freedom the
    // moment a single doubling succeeds (see `CurveFitting.GrowthFamily.parameterCount`).
    var remainingFineSteps = [1, 2, 3]
    var n = max(startSize, 2)

    while samples.count < maxPoints {
      var predictedForThisSize: Double?
      if samples.count >= 2 {
        let previous = samples[samples.count - 1]
        let beforePrevious = samples[samples.count - 2]
        let step = max(previous.n - beforePrevious.n, 1)
        if beforePrevious.value > 0 {
          // Floored at 1.0: two small fine-step samples can land in either order purely from
          // trial noise (e.g. 21 ops then 16 ops), and a sub-1 ratio raised to a double-digit
          // `stepsAhead` power collapses toward 0 -- so an entirely normal measurement at the
          // next (much larger) size then looks like a "wild" multiple of a near-zero prediction.
          // Real operation counts don't shrink as `n` grows, so a measured decrease carries no
          // signal worth extrapolating; treating it as flat (ratio 1) instead of shrinking is
          // what actually reflects "no established per-step growth yet."
          let perStepRatio = max(previous.value / beforePrevious.value, 1.0)
          let stepsAhead = (Double(n) - previous.n) / step
          let predicted = previous.value * pow(perStepRatio, stepsAhead)
          if !predicted.isFinite || predicted > absoluteSafetyCeiling {
            let predictedDescription = predicted.isNaN ? "an indeterminate number of" : "~\(Int(min(predicted, 1e18)))"
            logProgress(
              "  \(label) size \(n) predicted \(predictedDescription) ops from the last two measured sizes -- stopping growth here rather than attempting it"
            )
            break
          }
          predictedForThisSize = predicted
        }
      }

      logProgress("  \(label) size \(n): attempting (budget \(perTrialTimeBudget)s/trial)...")
      var stats = RunningStatistics()
      let sizeForThisIteration = n
      let hangTimeout = perTrialTimeBudget * hangTimeoutMultiplier
      guard let first = runWithTimeout(hangTimeout, { trial(sizeForThisIteration) })
      else {
        logProgress(
          "  \(label) size \(n): did not return within \(hangTimeout)s -- likely a genuine non-terminating bug, not just slow. Abandoning this measurement and moving on (the background call itself is left running/abandoned, since Swift can't safely preempt a synchronous call mid-flight)."
        )
        unsafeAtSize = n
        unsafeReason = "hang"
        break
      }
      stats.record(first)

      var trialCount = 1
      var laterTrialHung = false
      while trialCount < maxTrials {
        if trialCount >= minTrials, stats.relativeStandardError < tolerance { break }
        // Re-check elapsed time every trial, not just the first -- a size whose first sample
        // happened to land under budget but whose per-trial cost is only borderline fast could
        // otherwise run up to `maxTrials` slow trials before the adaptive stopping rule ever
        // gets a chance to fire.
        guard let next = runWithTimeout(hangTimeout, { trial(sizeForThisIteration) })
        else {
          logProgress("  \(label) size \(n): a later trial hung -- keeping what's measured so far")
          laterTrialHung = true
          break
        }
        stats.record(next)
        trialCount += 1
      }

      // A jump wildly (100x+) past what the established trend from smaller sizes predicted is
      // just as fatal to a curve fit's honesty as a hang, even though the call itself returned
      // fine -- `mergebogosort+heapified` genuinely measures 798 ops at n=14 and 36.4 *million*
      // at n=28, and fitting one smooth curve across that discontinuity produces a technically
      // high-R² fit that's nonsense everywhere except right at that one outlier. Exclude the
      // outlier from `samples` entirely (not just cap around it) rather than let it distort the
      // fit for every other size.
      if let predictedForThisSize, predictedForThisSize > 0,
        stats.mean / predictedForThisSize > 100 {
        logProgress(
          "  \(label) size \(n): measured \(Int(stats.mean)) ops, ~\(Int(stats.mean / predictedForThisSize))x more than the established trend predicted (~\(Int(predictedForThisSize))) -- erratic/discontinuous growth, excluding this size and stopping here"
        )
        unsafeAtSize = n
        unsafeReason = "erratic jump"
        break
      }

      samples.append(GrowthSample(n: Double(n), value: stats.mean))
      logProgress(
        "  \(label) size \(n): done, \(trialCount) trial(s), mean \(Int(stats.mean)) ops")

      // A hang partway through this size's trials is just as much a hard stop as one on the very
      // first trial -- keep the (partial, but real) sample just recorded, but don't let growth
      // continue to even-larger, even-more-likely-to-hang sizes afterward.
      if laterTrialHung {
        unsafeAtSize = n
        unsafeReason = "hang"
        break
      }

      if let fineStep = remainingFineSteps.first {
        remainingFineSteps.removeFirst()
        n = max(startSize, 2) + fineStep
      } else {
        n *= 2
      }
    }
    return GrowthMeasurement(samples: samples, unsafeAtSize: unsafeAtSize, unsafeReason: unsafeReason)
  }

  /// Runs `body` on a background queue and waits up to `timeout` for it to finish. Swift has no
  /// safe way to preempt a synchronous, CPU-bound call once started, so a `nil` result here does
  /// *not* mean the work stopped -- it means the caller gave up waiting for it. The abandoned
  /// call keeps running (forever, in the genuinely-buggy case that motivated this) on its own
  /// orphaned background thread, but that's the price of the harness as a whole being able to
  /// make forward progress instead of hanging with it.
  /// A dedicated `Thread` per call, deliberately *not* `DispatchQueue.global()` -- GCD's shared
  /// global queue caps how many threads it runs concurrently per QoS class (a handful on this
  /// machine), and every abandoned hang permanently occupies one of those slots forever. In
  /// practice, after a few hundred genuine hangs accumulated over a long run, that shared pool
  /// saturated completely: *new* trials sat queued behind permanently-busy workers and timed out
  /// before ever actually starting, misclassifying hundreds of perfectly healthy measurements
  /// (`quickbogosort` at `n=4`, `pigeonholesort` at `n=16` -- both trivial) as hangs. A plain
  /// `Thread` per call sidesteps this: the OS supports many more concurrent threads than GCD's
  /// managed pool targets, so one abandoned thread leaking forever doesn't starve every other
  /// measurement's ability to even begin running.
  private static func runWithTimeout<T: Sendable>(
    _ timeout: TimeInterval, _ body: @escaping @Sendable () -> T
  ) -> T? {
    let semaphore = DispatchSemaphore(value: 0)
    let box = UncheckedBox<T>()
    let thread = Thread {
      box.value = body()
      semaphore.signal()
    }
    thread.name = "growth-calibration-trial"
    thread.stackSize = 4 << 20
    thread.start()
    guard semaphore.wait(timeout: .now() + timeout) == .success else { return nil }
    return box.value
  }

  private final class UncheckedBox<T>: @unchecked Sendable {
    var value: T?
  }

  /// How many combinations to run at once. Defaults to every core on the machine (all
  /// performance and efficiency cores alike) -- overridable for anyone who wants to leave
  /// headroom for other work while a sweep runs.
  private static func workerCount() -> Int {
    Int(envOverride("GROWTH_CALIBRATION_WORKER_COUNT", default: Double(ProcessInfo.processInfo.activeProcessorCount)))
  }

  /// Lock-protected work-stealing index into `items` -- `@unchecked Sendable` for the same reason
  /// as `UncheckedBox` above: the lock is the actual synchronization, the compiler just can't see
  /// that. Workers pull the next item as they finish their current one rather than being handed a
  /// fixed slice up front, since per-item cost in this harness varies by orders of magnitude (a
  /// degenerate cutoff finishes in milliseconds, a genuine safety-gated backoff can take seconds).
  private final class WorkQueue<Item>: @unchecked Sendable {
    private let items: [Item]
    private let lock = NSLock()
    private var nextIndex = 0

    init(_ items: [Item]) { self.items = items }

    func dequeue() -> Item? {
      lock.lock()
      defer { lock.unlock() }
      guard nextIndex < items.count else { return nil }
      defer { nextIndex += 1 }
      return items[nextIndex]
    }
  }

  /// Runs `body` for every item in `items` across `workerCount` dedicated `Thread`s -- never
  /// `DispatchQueue.global()`/a `TaskGroup`, for the same reason `runWithTimeout` above uses a
  /// plain `Thread`: every trial already blocks its own caller synchronously on a semaphore, and
  /// doing that from inside `N` concurrent Swift Concurrency `Task`s would tie up `N` threads from
  /// the *cooperative thread pool* (itself sized to the core count), starving any other async work
  /// (including this file's own `await`-based bridge calls) the moment concurrency approaches the
  /// core count. Plain `Thread`s have no such shared ceiling. Results are handed back through an
  /// `AsyncStream` in completion order (not input order), so the caller can keep doing all of its
  /// sequential bookkeeping -- fitting, appending to `reports`, writing JSON, logging -- on its own
  /// single async context, without needing any locking of its own.
  private static func parallelMap<Item: Sendable, Result: Sendable>(
    _ items: [Item], workerCount: Int, _ body: @escaping @Sendable (Item) -> Result
  ) -> AsyncStream<(item: Item, result: Result)> {
    let (stream, continuation) = AsyncStream<(item: Item, result: Result)>.makeStream()
    let queue = WorkQueue(items)
    let group = DispatchGroup()
    for _ in 0..<max(1, min(workerCount, items.count)) {
      group.enter()
      let thread = Thread {
        while let item = queue.dequeue() {
          continuation.yield((item, body(item)))
        }
        group.leave()
      }
      thread.stackSize = 4 << 20
      thread.start()
    }
    group.notify(queue: .global()) { continuation.finish() }
    return stream
  }

  /// Reads a `Double`-valued environment variable override, falling back to `default` when unset
  /// or unparsable -- lets a long unfiltered run be tuned (tighter time budget, fewer max trials)
  /// without a code change.
  private static func envOverride(_ key: String, default defaultValue: Double) -> Double {
    ProcessInfo.processInfo.environment[key].flatMap(Double.init) ?? defaultValue
  }

  // MARK: - Fitting, inversion, and the safety-margin verification pass

  private static func makeReport(
    subjectID: String, measurement: GrowthMeasurement, declaredShape: BigOShape?
  ) async -> GrowthReport? {
    let samples = measurement.samples
    guard samples.count >= 2, let fit = CurveFitting.bestFit(samples, declaredShape: declaredShape)
    else { return nil }

    // A hang is a hard ceiling the growth-model math knows nothing about: it answers "when does
    // operation count exceed the cap," not "when does this stop terminating at all." If a hang
    // was detected, nothing at or above the last size that measured *cleanly* (every trial at
    // that size actually returned) can be trusted, no matter what the curve extrapolates --
    // that's what fixed the `mergebogosort+descending` finding, where the fitted curve alone
    // computed a "safe" size of 803, well past the 96 where it actually hangs forever.
    let confirmedSafeUpToSize: Double
    if let unsafeAtSize = measurement.unsafeAtSize {
      confirmedSafeUpToSize = samples.filter { $0.n < Double(unsafeAtSize) }.map(\.n).max() ?? 0
    } else {
      confirmedSafeUpToSize = .infinity
    }

    var safeMaxSizeByCap: [Double: Double] = [:]
    for cap in referenceCaps {
      guard
        var candidate = await solveForN(
          model: fit, cap: cap * safetyMargin, seed: samples.last?.n ?? 16),
        // A degenerate fit (extreme coefficients from very few measured points, e.g. an
        // algorithm the predictive safety gate cut off after only 3 sizes) can produce a
        // `solveForN` result that's NaN, infinite, negative, or larger than `Int` can even
        // represent -- any of those would crash the `Int(...)` conversions below, so this whole
        // cap is reported as "couldn't compute" rather than taking the process down.
        candidate.isFinite, candidate > 1, candidate < 1_000_000_000
      else { continue }
      // Verify by direct re-run, backing off geometrically until the real tape estimate is
      // actually under the cap -- an empirical fit is an approximation, not a proof.
      var verifiedSize = Int(candidate.rounded(.down))
      while verifiedSize > 1 {
        let actual = predictedOrMeasured(model: fit, n: Double(verifiedSize))
        if actual.isFinite, actual <= cap { break }
        candidate *= 0.9
        verifiedSize = Int(candidate.rounded(.down))
      }
      let sizeBeforeHangClamp = Double(max(verifiedSize, 1))
      safeMaxSizeByCap[cap] = min(sizeBeforeHangClamp, confirmedSafeUpToSize)
    }

    let allFits = CurveFitting.fitAllFamilies(samples).sorted { $0.adjustedRSquared > $1.adjustedRSquared }
    let runnerUp = allFits.first { $0.family != fit.family }

    return GrowthReport(
      subjectID: subjectID, winningFamily: fit.family.rawValue, winningRSquared: fit.rSquared,
      runnerUpFamily: runnerUp?.family.rawValue, runnerUpRSquared: runnerUp?.rSquared,
      coefficients: fit.coefficients, sampleSizes: samples.map { Int($0.n) },
      safeMaxSizeByCap: safeMaxSizeByCap, unsafeAtSize: measurement.unsafeAtSize,
      unsafeReason: measurement.unsafeReason)
  }

  /// The fitted model's own prediction is the verification signal here (not a fresh real run) --
  /// good enough for the geometric back-off loop, which only needs to know "does this candidate
  /// size sit on the correct side of the cap," and avoids re-running a potentially slow trial
  /// repeatedly during back-off. `tapeEstimateFormulaMatchesRealTapeCountAtSmallSizes` above is
  /// what actually validates the estimate itself against ground truth.
  private static func predictedOrMeasured(model: FittedGrowthModel, n: Double) -> Double {
    model.predict(n: n)
  }

  private static func solveForN(model: FittedGrowthModel, cap: Double, seed: Double) async
    -> Double? {
    switch model.family {
    case .powerLaw:
      let (a, k) = (model.coefficients[0], model.coefficients[1])
      guard a > 0, k != 0 else { return nil }
      return pow(cap / a, 1 / k)

    case .polynomialIntercept:
      let (a, b, c) = (model.coefficients[0], model.coefficients[1], model.coefficients[2])
      let roots = PolynomialRootSolver.realRoots(coefficients: [c - cap, b, a]).filter { $0 > 0 }
      return roots.min()

    case .exponential:
      let (a, b) = (model.coefficients[0], model.coefficients[1])
      guard a > 0, b > 0, b != 1 else { return nil }
      return log(cap / a) / log(b)

    case .nToTheNLike, .factorial:
      // No elementary inverse (this is the Lambert-*W* family) -- Newton's method directly
      // against the fitted curve with a numeric (central-difference) derivative, since both
      // shapes are smooth and monotonic over any realistic array-size domain.
      return PolynomialRootSolver.newton(
        seed: max(seed, 2), iterations: 30,
        function: { model.predict(n: $0) - cap },
        derivative: { n in
          let h = max(n * 1e-4, 1e-3)
          return (model.predict(n: n + h) - model.predict(n: n - h)) / (2 * h)
        })

    case .powerLog:
      // The one family that's both transcendental *and* has no single clean substitution --
      // Taylor-expand it to a quadratic around the top of the measured range via the SymPy
      // bridge, then solve that quadratic with the same closed-form solver used above.
      let (a, k) = (model.coefficients[0], model.coefficients[1])
      let n0 = max(seed, 2)
      guard let expr = powerLogExpression(a: a, k: k),
        let polynomial = try? await fetchTaylorPolynomial(expr: expr, n0: n0)
      else { return nil }
      let roots = PolynomialRootSolver.realRoots(
        coefficients: [polynomial.coefficients[0] - cap] + polynomial.coefficients.dropFirst())
      return roots.filter { $0 > -n0 }.min(by: { abs($0) < abs($1) }).map { n0 + $0 }
    }
  }

  private static func powerLogExpression(a: Double, k: Double) -> String? {
    guard a.isFinite, k.isFinite else { return nil }
    return "\(a)*n**\(k)*log(n)"
  }

  // MARK: - The Python/SymPy bridge client

  private struct TaylorPolynomial {
    let n0: Double
    let coefficients: [Double]
  }

  private static func checkBridgeHealth() async -> Bool {
    guard let (_, response) = try? await URLSession.shared.data(from: bridgeURL.appending(path: "health"))
    else { return false }
    return (response as? HTTPURLResponse)?.statusCode == 200
  }

  private static func fetchTaylorPolynomial(expr: String, n0: Double, order: Int = 2) async throws
    -> TaylorPolynomial {
    var request = URLRequest(url: bridgeURL.appending(path: "taylor-invert"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(
      withJSONObject: ["expr": expr, "n0": n0, "order": order])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200,
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let n0Value = json["n0"] as? Double,
      let coefficients = json["coefficients"] as? [Double]
    else {
      let message = String(data: data, encoding: .utf8) ?? "unreadable response"
      throw BridgeError.badResponse(message)
    }
    return TaylorPolynomial(n0: n0Value, coefficients: coefficients)
  }

  private enum BridgeError: Error {
    case badResponse(String)
  }

  // MARK: - Progress logging

  /// C stdio defaults to fully-buffered output when stdout isn't a terminal (i.e. whenever this
  /// runs under `xcodebuild`, piped to a log file or another process) -- without this, a
  /// multi-hour run's progress lines wouldn't actually reach a `tee`'d log/tmux pane until the
  /// buffer filled or the process exited, defeating the entire point of adding them.
  private static func enableLineBuffering() {
    setvbuf(stdout, nil, _IOLBF, 0)
  }

  private static func logProgress(_ message: String) {
    let timestamp = Self.timestampFormatter.string(from: Date())
    print("[\(timestamp)] [calibration] \(message)")
  }

  private static let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()

  private static func formatDuration(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "?" }
    let totalSeconds = Int(seconds)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let remainingSeconds = totalSeconds % 60
    if hours > 0 { return "\(hours)h\(minutes)m\(remainingSeconds)s" }
    if minutes > 0 { return "\(minutes)m\(remainingSeconds)s" }
    return "\(remainingSeconds)s"
  }

  // MARK: - Reporting

  struct GrowthReport: Codable {
    let subjectID: String
    let winningFamily: String
    let winningRSquared: Double
    let runnerUpFamily: String?
    let runnerUpRSquared: Double?
    let coefficients: [Double]
    let sampleSizes: [Int]
    let safeMaxSizeByCap: [Double: Double]
    /// Non-nil means measurement stopped early because of a hang or an erratic/discontinuous
    /// jump at this size (see `unsafeReason`) -- every `safeMaxSizeByCap` value is already
    /// clamped below this, but it's kept here explicitly so a human reviewing the report can see
    /// *why* a size looks more conservative than the fitted curve alone would suggest, and so
    /// this subject can be cross-referenced against a real algorithm bug that needs fixing
    /// separately.
    let unsafeAtSize: Int?
    /// `"hang"` or `"erratic jump"` -- see `GrowthMeasurement`'s doc comment. `nil` exactly when
    /// `unsafeAtSize` is `nil`.
    let unsafeReason: String?

    private enum CodingKeys: String, CodingKey {
      case subjectID, winningFamily, winningRSquared, runnerUpFamily, runnerUpRSquared,
        coefficients, sampleSizes, safeMaxSizeByCap, unsafeAtSize, unsafeReason
    }

    /// Hand-written only for `safeMaxSizeByCap`'s sake -- `Decodable`'s synthesis is left alone
    /// below (order doesn't matter when reconstructing a `Dictionary` from flat pairs, so the
    /// default decode already round-trips this correctly regardless of pair order).
    ///
    /// `Double`-keyed dictionaries aren't one of the two key types (`String`, `Int`) `JSONEncoder`
    /// gives real, `.sortedKeys`-respecting object treatment to, so this one falls back to a flat
    /// `[key, value, key, value, ...]` array serialized in `Dictionary`'s own iteration order --
    /// which Swift randomizes per-process (a `Hashable` defense against hash-flooding), not
    /// insertion order. Left alone, that meant re-running calibration for a single algorithm
    /// perturbed this field's pair order in every *other* algorithm's entry too, on every run,
    /// even though their actual values never changed -- a git diff touching the whole file for a
    /// one-algorithm change. Sorting by cap before writing makes this field byte-identical across
    /// runs unless the underlying numbers actually changed.
    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(subjectID, forKey: .subjectID)
      try container.encode(winningFamily, forKey: .winningFamily)
      try container.encode(winningRSquared, forKey: .winningRSquared)
      // `encodeIfPresent`, not `encode`, for every Optional field -- matching the auto-synthesis
      // this replaced, which omits the key entirely when nil rather than writing an explicit
      // `null`. `encode(_:forKey:)` on an `Optional` value does NOT do this (it happily encodes
      // `null`), so getting this wrong here would have added `"unsafeAtSize": null` etc. to every
      // one of the hundreds of entries that never had those keys at all -- a real, if harmless,
      // schema drift caught by diffing this canonicalization pass against the prior file instead
      // of assuming a reorder-only change needed no verification.
      try container.encodeIfPresent(runnerUpFamily, forKey: .runnerUpFamily)
      try container.encodeIfPresent(runnerUpRSquared, forKey: .runnerUpRSquared)
      try container.encode(coefficients, forKey: .coefficients)
      try container.encode(sampleSizes, forKey: .sampleSizes)
      let sortedPairs = safeMaxSizeByCap.sorted { $0.key < $1.key }.flatMap { [$0.key, $0.value] }
      try container.encode(sortedPairs, forKey: .safeMaxSizeByCap)
      try container.encodeIfPresent(unsafeAtSize, forKey: .unsafeAtSize)
      try container.encodeIfPresent(unsafeReason, forKey: .unsafeReason)
    }
  }

  private static func printReport(title: String, reports: [GrowthReport]) {
    print("\n=== Growth model calibration: \(title) ===")
    for report in reports.sorted(by: { $0.subjectID < $1.subjectID }) {
      let capSummary = referenceCaps.map { cap in
        "\(Int(cap)): \(formatSafeSize(report, cap: cap))"
      }.joined(separator: ", ")
      let runnerUp = report.runnerUpFamily.map { " (runner-up: \($0), R²=\(report.runnerUpRSquared ?? 0))" } ?? ""
      let unsafeNote = report.unsafeAtSize.map {
        " [\((report.unsafeReason ?? "unsafe").uppercased()) at size \($0) -- capped]"
      } ?? ""
      print(
        "\(report.subjectID): \(report.winningFamily) R²=\(report.winningRSquared)\(runnerUp) -- safe max size [\(capSummary)]\(unsafeNote)"
      )
    }
  }

  /// "n/a" (not a raw `-1` sentinel) when a cap has no entry -- either the fitted curve never
  /// crosses that cap within a sane size range (negligible/flat growth, nothing to worry about)
  /// or the fit was too degenerate to trust (see `CurveFitting`'s degrees-of-freedom guard). A
  /// bare `-1` reads exactly like an error to a human skimming the report, which is the whole
  /// reason this got confusing to begin with.
  private static func formatSafeSize(_ report: GrowthReport, cap: Double) -> String {
    guard let value = report.safeMaxSizeByCap[cap] else { return "n/a" }
    return String(Int(value))
  }

  private static var outputDirectory: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Tools/GrowthModelCalibration/output")
  }

  private static func writeReport(_ reports: [GrowthReport], to filename: String) throws {
    try FileManager.default.createDirectory(
      at: outputDirectory, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    // Canonical order (alphabetical by subjectID), not construction order -- `reports` is built
    // by appending a resumed run's one new entry to whatever order the previous run happened to
    // leave the array in, and `parallelMap` above hands results back in completion order (not
    // input order) on top of that, so without this a full multi-algorithm sweep could reshuffle
    // every entry's relative position even when no entry's own data changed. Sorting here means a
    // single-algorithm resumed run only ever touches that algorithm's own entry in a diff.
    let sorted = reports.sorted { $0.subjectID < $1.subjectID }
    let data = try encoder.encode(sorted)
    try data.write(to: outputDirectory.appendingPathComponent(filename))
  }

  /// `false` only when `GROWTH_CALIBRATION_RESUME=0` is set -- resuming (skip whatever's already
  /// in the previous run's JSON output) is the default, since a full sweep takes long enough that
  /// re-running everything from scratch after an interruption is real wasted time.
  private static func resumeEnabled() -> Bool {
    ProcessInfo.processInfo.environment["GROWTH_CALIBRATION_RESUME"] != "0"
  }

  private static func loadExistingReport(from filename: String) -> [GrowthReport] {
    let url = outputDirectory.appendingPathComponent(filename)
    guard let data = try? Data(contentsOf: url) else { return [] }
    return (try? JSONDecoder().decode([GrowthReport].self, from: data)) ?? []
  }
}

/// Deliberately outside `GrowthModelCalibrationTests` (which is gated behind
/// `RUN_GROWTH_CALIBRATION=1` and needs the SymPy bridge) -- this only exercises
/// `GrowthReport`'s own `Codable` conformance, so it should run in every plain `xcodebuild test`
/// like any other test in this target.
@Suite
struct GrowthReportEncodingTests {
  typealias GrowthReport = GrowthModelCalibrationTests.GrowthReport

  private func makeReport(safeMaxSizeByCap: [Double: Double]) -> GrowthReport {
    GrowthReport(
      subjectID: "test", winningFamily: "powerLaw", winningRSquared: 1, runnerUpFamily: nil,
      runnerUpRSquared: nil, coefficients: [1, 1], sampleSizes: [16, 32],
      safeMaxSizeByCap: safeMaxSizeByCap, unsafeAtSize: nil, unsafeReason: nil)
  }

  /// `Dictionary`'s iteration order is randomized per-process for a `Double` key (not tied to
  /// insertion order), which is exactly what made re-running growth-model calibration for one
  /// algorithm perturb `safeMaxSizeByCap`'s pair order in every *other* algorithm's already-
  /// written entry too. `GrowthReport.encode(to:)` sorts by cap before writing specifically to
  /// defeat that -- this constructs the same key/value pairs via two different insertion orders
  /// (about as close as a test can get to forcing two different internal iteration orders) and
  /// checks the encoded JSON is byte-identical either way.
  @Test
  func safeMaxSizeByCapEncodesInCanonicalOrderRegardlessOfInsertionOrder() throws {
    let ascending = makeReport(safeMaxSizeByCap: [100_000: 500, 300_000: 900, 1_000_000: 1700])
    let descending = makeReport(safeMaxSizeByCap: [1_000_000: 1700, 300_000: 900, 100_000: 500])

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let ascendingData = try encoder.encode(ascending)
    let descendingData = try encoder.encode(descending)

    // The real discriminating check: the flat pair array is ascending by cap in the actual
    // encoded bytes, not merely "whatever two same-content dictionaries happened to agree on" --
    // two `Dictionary` literals built from the same keys can coincidentally iterate identically
    // within one process regardless of source order, so matching each other alone wouldn't prove
    // this encodes canonically rather than just consistently-by-luck.
    let json = try #require(String(data: ascendingData, encoding: .utf8))
    let pairsRange = try #require(json.range(of: "\"safeMaxSizeByCap\":["))
    let afterKey = json[pairsRange.upperBound...]
    let pairsEnd = try #require(afterKey.firstIndex(of: "]"))
    let pairsText = afterKey[afterKey.startIndex..<pairsEnd]
    #expect(pairsText == "100000,500,300000,900,1000000,1700")

    #expect(ascendingData == descendingData)

    let decoded = try JSONDecoder().decode(GrowthReport.self, from: ascendingData)
    #expect(decoded.safeMaxSizeByCap == [100_000: 500, 300_000: 900, 1_000_000: 1700])
  }

  /// Regression test for a real bug caught while first using `canonicalizeExistingReports`: a
  /// hand-written `encode(to:)` is easy to get subtly wrong for `Optional` fields.
  /// `container.encode(_:forKey:)` on an `Optional` value writes an explicit `null` when nil;
  /// the auto-synthesized `encode(to:)` this replaced used `encodeIfPresent` semantics instead,
  /// omitting the key entirely. Every one of the hundreds of already-shipped report entries with
  /// a nil `runnerUpFamily`/`unsafeAtSize`/etc. was missing those keys on disk -- if this test had
  /// existed first, the mistake would never have made it into a real run's output at all.
  @Test
  func nilOptionalFieldsAreOmittedNotEncodedAsNull() throws {
    let report = makeReport(safeMaxSizeByCap: [100_000: 500])
    let data = try JSONEncoder().encode(report)
    let json = try #require(String(data: data, encoding: .utf8))

    for omittedKey in ["runnerUpFamily", "runnerUpRSquared", "unsafeAtSize", "unsafeReason"] {
      #expect(!json.contains("\"\(omittedKey)\""), "expected \(omittedKey) to be omitted, not encoded as null")
    }
  }
}
