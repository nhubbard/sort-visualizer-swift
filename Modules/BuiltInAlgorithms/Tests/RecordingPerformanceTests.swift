import AlgorithmKit
import Darwin
import Foundation
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

/// Manual-only, mirroring `GrowthModelCalibrationTests`' gating (a plain env var, not a Swift
/// Testing tag, so it stays out of a normal `xcodebuild test` run with zero Test Plan config) --
/// but a distinct, self-contained harness: it measures real tape-recording wall-clock time via
/// `TapeFactory.makeTape` at each algorithm's actual maximum reachable size, not operation-count
/// growth curves. Operation count is a good proxy for most algorithms, but not all -- one that does
/// its hot-loop comparisons via a raw `engine.values[i]` read instead of `engine.compare` (e.g.
/// `CycleSort`) burns real wall-clock time that's completely invisible to `compareCount`/
/// `growthModel`. This exists to find exactly those outliers: algorithms slow enough at recording
/// to cause a real, visible `ProgressView` stall in `SortView` (see `SortSession.start(size:)`).
///
/// The small parallel/timeout infrastructure below (`parallelMap`, `runWithTimeout`, `workerCount`,
/// `envOverride`, `UncheckedBox`, `WorkQueue`) is deliberately duplicated from
/// `GrowthModelCalibrationTests.swift` rather than shared, to keep this a fully isolated, distinct
/// test that can't regress the existing (already delicate) calibration harness.
///
/// Run with: `RUN_RECORDING_PERFORMANCE=1 xcodebuild test -scheme BuiltInAlgorithms -destination
/// 'platform=macOS,variant=Mac Catalyst' -only-testing:BuiltInAlgorithmsTests/
/// RecordingPerformanceTests`. Narrow a run first with `RECORDING_PERFORMANCE_ALGORITHM_FILTER`/
/// `RECORDING_PERFORMANCE_SHUFFLE_FILTER` (substring match against the algorithm/shuffle's
/// `AlgorithmID`/`ShuffleID` raw value) to sanity-check timing/output shape before a full,
/// long-running unfiltered sweep across all 177 sorts x 46 shuffles.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["RUN_RECORDING_PERFORMANCE"] == "1"))
struct RecordingPerformanceTests {
  /// One (algorithm, shuffle) unit of work -- flattening the full cross product (rather than one
  /// worker per algorithm) gives much better load balancing, since per-combination recording cost
  /// varies just as wildly across shuffles as it does across algorithms.
  private struct SortShuffleCombo: Sendable {
    let algorithm: any SortAlgorithm
    let shuffle: any ShuffleAlgorithm
  }

  private struct ComboResult: Sendable {
    let shuffleID: String
    let size: Int
    let mean: Double
    let standardDeviation: Double
    let trialCount: Int
    let convergedByPrecision: Bool
    let hungTrials: Int
    let capExceededTrials: Int
  }

  @Test
  func measureRecordingPerformance() async throws {
    Self.enableLineBuffering()
    let overallStart = Date()

    let sorts = Self.filteredSorts()
    let shuffles = Self.filteredShuffles()
    let combos = sorts.flatMap { sort in shuffles.map { SortShuffleCombo(algorithm: sort, shuffle: $0) } }
    let totalCombinations = combos.count
    let workerCount = Self.workerCount()
    let tolerance = Self.envOverride("RECORDING_PERFORMANCE_TOLERANCE", default: 0.05)
    let minTrials = Int(Self.envOverride("RECORDING_PERFORMANCE_MIN_TRIALS", default: 5))
    let maxTrials = Int(Self.envOverride("RECORDING_PERFORMANCE_MAX_TRIALS", default: 30))
    let trialTimeout = Self.envOverride("RECORDING_PERFORMANCE_TRIAL_TIMEOUT", default: 5.0)
    Self.logProgress(
      "\(sorts.count) algorithms x \(shuffles.count) shuffles = \(totalCombinations) combinations across \(workerCount) worker(s)"
    )

    // Only ever touched from this single `for await` consumer, so no locking needed despite
    // `parallelMap` fanning the actual measurement work across worker threads.
    var resultsByAlgorithm: [String: [ComboResult]] = [:]
    var combinationsDone = 0

    for await (combo, result) in Self.parallelMap(combos, workerCount: workerCount, { combo in
      Self.measureCombo(
        sort: combo.algorithm, shuffle: combo.shuffle, tolerance: tolerance, minTrials: minTrials,
        maxTrials: maxTrials, trialTimeout: trialTimeout)
    }) {
      combinationsDone += 1
      resultsByAlgorithm[combo.algorithm.id.rawValue, default: []].append(result)

      if combinationsDone % 50 == 0 || combinationsDone == totalCombinations {
        let elapsed = Date().timeIntervalSince(overallStart)
        let averagePerCombo = combinationsDone > 0 ? elapsed / Double(combinationsDone) : 0
        let remaining = Double(totalCombinations - combinationsDone) * averagePerCombo
        Self.logProgress(
          "\(combinationsDone)/\(totalCombinations) combos, elapsed \(Self.formatDuration(elapsed)), ETA \(Self.formatDuration(remaining))"
        )
      }
    }

    var practical: [AlgorithmRecordingPerformance] = []
    var impractical: [AlgorithmRecordingPerformance] = []
    for sort in sorts {
      guard let results = resultsByAlgorithm[sort.id.rawValue], !results.isEmpty else { continue }
      let entry = Self.makeAlgorithmEntry(sort: sort, results: results)
      if sort.metadata.category == .impractical {
        impractical.append(entry)
      } else {
        practical.append(entry)
      }
    }
    practical.sort { $0.aggregateMeanSeconds > $1.aggregateMeanSeconds }
    impractical.sort { $0.aggregateMeanSeconds > $1.aggregateMeanSeconds }

    let report = RecordingPerformanceReport(
      operationCap: RecordingEngine.defaultOperationCap, practicalAlgorithms: practical,
      impracticalAlgorithms: impractical)
    try Self.writeReport(report)

    Self.logProgress(
      "done: \(practical.count) practical + \(impractical.count) impractical algorithms in \(Self.formatDuration(Date().timeIntervalSince(overallStart)))"
    )
    Self.printSummary(title: "Slowest practical algorithms", entries: practical, limit: 15)
    Self.printSummary(title: "Slowest impractical algorithms (own list, kept separate so they can't bias the ranking above)", entries: impractical, limit: 5)
  }

  // MARK: - Filtering

  private static func filteredSorts() -> [any SortAlgorithm] {
    guard let filter = ProcessInfo.processInfo.environment["RECORDING_PERFORMANCE_ALGORITHM_FILTER"]
    else { return AllBuiltInAlgorithms.sorts }
    return AllBuiltInAlgorithms.sorts.filter { $0.id.rawValue.contains(filter) }
  }

  private static func filteredShuffles() -> [any ShuffleAlgorithm] {
    guard let filter = ProcessInfo.processInfo.environment["RECORDING_PERFORMANCE_SHUFFLE_FILTER"]
    else { return AllBuiltInAlgorithms.shuffles }
    return AllBuiltInAlgorithms.shuffles.filter { $0.id.rawValue.contains(filter) }
  }

  // MARK: - Measuring one (algorithm, shuffle) combo

  /// Runs real `TapeFactory.makeTape` recordings at `sort`'s actual `effectiveSizeRange` upper
  /// bound -- the largest size a real user could reach via the size chip picker today -- sampling
  /// adaptively via `AdaptiveSampling` (`Support/Statistics.swift`, already in this test target)
  /// until the mean is stable or `maxTrials` is hit. A hung trial (never returns within
  /// `trialTimeout`) or one that throws `.tooLarge` both record `trialTimeout` itself as the
  /// sample -- a well-behaved finite floor ("took at least this long") that keeps a pathological
  /// algorithm visible in the ranking instead of silently vanishing from it.
  private static func measureCombo(
    sort: any SortAlgorithm, shuffle: any ShuffleAlgorithm, tolerance: Double, minTrials: Int,
    maxTrials: Int, trialTimeout: TimeInterval
  ) -> ComboResult {
    let cap = RecordingEngine.defaultOperationCap
    let size = sort.metadata.effectiveSizeRange(operationCap: cap).upperBound
    var hungTrials = 0
    var capExceededTrials = 0

    let sampled = AdaptiveSampling.sample(tolerance: tolerance, minTrials: minTrials, maxTrials: maxTrials) {
      let outcome: Tape?? = runWithTimeout(trialTimeout) {
        try? TapeFactory.makeTape(algorithm: sort, shuffle: shuffle, size: size, operationCap: cap)
      }
      switch outcome {
      case .none:
        hungTrials += 1
        return trialTimeout
      case .some(.none):
        capExceededTrials += 1
        return trialTimeout
      case .some(.some(let tape)):
        return tape.header.recordingDuration
      }
    }

    return ComboResult(
      shuffleID: shuffle.id.rawValue, size: size, mean: sampled.statistics.mean,
      standardDeviation: sampled.statistics.standardDeviation, trialCount: sampled.statistics.count,
      convergedByPrecision: sampled.convergedByPrecision, hungTrials: hungTrials,
      capExceededTrials: capExceededTrials)
  }

  /// Rolls up one algorithm's per-shuffle `ComboResult`s into a single ranked entry. The aggregate
  /// mean is a trial-count-weighted average across shuffles (a shuffle whose sampling needed more
  /// trials to stabilize shouldn't count the same as one that converged instantly), not a rigorous
  /// pooled variance -- that would need reaching into `RunningStatistics`'s private internals for
  /// precision this diagnostic doesn't actually need; `minShuffleMeanSeconds`/`maxShuffleMeanSeconds`
  /// already show the spread across shuffles for a human to judge.
  private static func makeAlgorithmEntry(
    sort: any SortAlgorithm, results: [ComboResult]
  ) -> AlgorithmRecordingPerformance {
    let shuffleTimings = results.sorted { $0.shuffleID < $1.shuffleID }.map {
      ShuffleRecordingTiming(
        shuffleID: $0.shuffleID, meanSeconds: $0.mean, standardDeviation: $0.standardDeviation,
        trialCount: $0.trialCount, convergedByPrecision: $0.convergedByPrecision)
    }
    let totalTrials = results.reduce(0) { $0 + $1.trialCount }
    let weightedMean =
      totalTrials > 0
      ? results.reduce(0.0) { $0 + $1.mean * Double($1.trialCount) } / Double(totalTrials) : 0

    return AlgorithmRecordingPerformance(
      algorithmID: sort.id.rawValue, category: sort.metadata.category.rawValue,
      size: results.first?.size ?? 0, aggregateMeanSeconds: weightedMean,
      aggregateTrialCount: totalTrials,
      minShuffleMeanSeconds: results.map(\.mean).min() ?? 0,
      maxShuffleMeanSeconds: results.map(\.mean).max() ?? 0,
      hungTrialCount: results.reduce(0) { $0 + $1.hungTrials },
      capExceededTrialCount: results.reduce(0) { $0 + $1.capExceededTrials },
      shuffleTimings: shuffleTimings)
  }

  /// Runs `body` on a dedicated background `Thread` and waits up to `timeout` for it to finish --
  /// identical in shape and rationale to `GrowthModelCalibrationTests`'s own `runWithTimeout`
  /// (duplicated, not shared -- see this suite's own doc comment for why): Swift has no safe way
  /// to preempt a synchronous, CPU-bound call once started, so `nil` means only "gave up waiting,"
  /// not "the work stopped." A plain `Thread` (not `DispatchQueue.global()`) avoids GCD's shared
  /// per-QoS thread cap, which a long run's accumulated abandoned hangs would otherwise saturate.
  private static func runWithTimeout<T: Sendable>(
    _ timeout: TimeInterval, _ body: @escaping @Sendable () -> T
  ) -> T? {
    let semaphore = DispatchSemaphore(value: 0)
    let box = UncheckedBox<T>()
    let thread = Thread {
      box.value = body()
      semaphore.signal()
    }
    thread.name = "recording-performance-trial"
    thread.stackSize = 4 << 20
    thread.start()
    guard semaphore.wait(timeout: .now() + timeout) == .success else { return nil }
    return box.value
  }

  private final class UncheckedBox<T>: @unchecked Sendable {
    var value: T?
  }

  /// Defaults to every core on the machine -- overridable for anyone who wants to leave headroom
  /// for other work while a sweep runs.
  private static func workerCount() -> Int {
    Int(envOverride("RECORDING_PERFORMANCE_WORKER_COUNT", default: Double(ProcessInfo.processInfo.activeProcessorCount)))
  }

  /// Lock-protected work-stealing index into `items` -- `@unchecked Sendable` for the same reason
  /// as `UncheckedBox` above: the lock is the actual synchronization, the compiler just can't see
  /// that. Workers pull the next item as they finish their current one rather than being handed a
  /// fixed slice up front, since per-combo cost varies by orders of magnitude here too.
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
  /// `DispatchQueue.global()`/a `TaskGroup`, since every trial already blocks its own caller
  /// synchronously on a semaphore (`runWithTimeout`), and doing that from `N` concurrent Swift
  /// Concurrency `Task`s would tie up `N` threads from the cooperative pool (sized to core count),
  /// starving other async work. Results stream back through an `AsyncStream` in completion order
  /// (not input order), so the caller can do its sequential bookkeeping on a single async context
  /// with no locking of its own.
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

  private static func envOverride(_ key: String, default defaultValue: Double) -> Double {
    ProcessInfo.processInfo.environment[key].flatMap(Double.init) ?? defaultValue
  }

  // MARK: - Progress logging

  /// C stdio defaults to fully-buffered output when stdout isn't a terminal (i.e. under
  /// `xcodebuild`) -- without this, a long run's progress lines wouldn't reach a piped/tee'd log
  /// until the buffer filled or the process exited.
  private static func enableLineBuffering() {
    setvbuf(stdout, nil, _IOLBF, 0)
  }

  private static func logProgress(_ message: String) {
    let timestamp = Self.timestampFormatter.string(from: Date())
    print("[\(timestamp)] [recording-perf] \(message)")
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

  private static func printSummary(title: String, entries: [AlgorithmRecordingPerformance], limit: Int) {
    print("\n=== Recording performance: \(title) ===")
    for entry in entries.prefix(limit) {
      let hangNote = entry.hungTrialCount > 0 ? " [\(entry.hungTrialCount) hung trial(s)]" : ""
      let capNote =
        entry.capExceededTrialCount > 0 ? " [\(entry.capExceededTrialCount) cap-exceeded trial(s)]" : ""
      print(
        "\(entry.algorithmID) (\(entry.category)) @ n=\(entry.size): mean \(String(format: "%.4f", entry.aggregateMeanSeconds))s across \(entry.aggregateTrialCount) trials\(hangNote)\(capNote)"
      )
    }
  }

  // MARK: - Reporting

  struct ShuffleRecordingTiming: Codable {
    let shuffleID: String
    let meanSeconds: Double
    let standardDeviation: Double
    let trialCount: Int
    let convergedByPrecision: Bool
  }

  struct AlgorithmRecordingPerformance: Codable {
    let algorithmID: String
    let category: String
    let size: Int
    let aggregateMeanSeconds: Double
    let aggregateTrialCount: Int
    let minShuffleMeanSeconds: Double
    let maxShuffleMeanSeconds: Double
    let hungTrialCount: Int
    let capExceededTrialCount: Int
    let shuffleTimings: [ShuffleRecordingTiming]
  }

  struct RecordingPerformanceReport: Codable {
    let operationCap: Int
    /// Every non-`.impractical` category, sorted slowest-first.
    let practicalAlgorithms: [AlgorithmRecordingPerformance]
    /// `.impractical` only, sorted slowest-first, kept in its own list so these (already known to
    /// be slow by design) can't drown out the practical-algorithm ranking above.
    let impracticalAlgorithms: [AlgorithmRecordingPerformance]
  }

  private static var outputDirectory: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Tools/RecordingPerformance/output")
  }

  private static func writeReport(_ report: RecordingPerformanceReport) throws {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(report)
    try data.write(to: outputDirectory.appendingPathComponent("recording-performance-report.json"))
  }
}
