import AlgorithmKit
import Foundation
import SettingsKit
import VisualizationKit
import os

/// Pure, registry-agnostic enumeration logic for "Full Sweep" — deliberately factored out of
/// `CoverageSweepDriver` so `CoverageSweepDriverTests` can exercise it directly against small,
/// synthetic ID lists instead of the real 167 × 46 × 15 registries or the file system.
public enum CoverageSweepEnumerator {
  public struct Combo: Sendable, Equatable, Hashable {
    public let algorithmID: AlgorithmID
    public let shuffleID: ShuffleID
    public let visualizerID: VisualizerID

    public init(algorithmID: AlgorithmID, shuffleID: ShuffleID, visualizerID: VisualizerID) {
      self.algorithmID = algorithmID
      self.shuffleID = shuffleID
      self.visualizerID = visualizerID
    }
  }

  /// Both the composite key `nextUncovered` checks against *and* the exact line format the log
  /// file stores — the two are deliberately the same string, so `parseLog` never needs to
  /// reparse fields back into a differently-shaped key.
  static func key(for combo: Combo) -> String {
    "\(combo.algorithmID.rawValue)\t\(combo.shuffleID.rawValue)\t\(combo.visualizerID.rawValue)"
  }

  /// First combo, in nested (algorithm, shuffle, visualizer) order, whose composite key isn't
  /// already in `completedKeys` — `nil` once every combination has been covered. Registry
  /// composition changes between sessions need no special handling: a newly-added algorithm's
  /// combos simply aren't in `completedKeys` yet and get enumerated normally; a removed one's
  /// combos simply never get enumerated again. This is the whole reason coverage is tracked by
  /// genuine ID strings rather than a positional cursor.
  static func nextUncovered(
    algorithmIDs: [AlgorithmID], shuffleIDs: [ShuffleID], visualizerIDs: [VisualizerID],
    completedKeys: Set<String>
  ) -> Combo? {
    for algorithmID in algorithmIDs {
      for shuffleID in shuffleIDs {
        for visualizerID in visualizerIDs {
          let combo = Combo(algorithmID: algorithmID, shuffleID: shuffleID, visualizerID: visualizerID)
          if !completedKeys.contains(key(for: combo)) {
            return combo
          }
        }
      }
    }
    return nil
  }

  /// Parses the append-only log's contents into the `Set` `nextUncovered` checks against.
  /// Tolerant of a truncated/malformed trailing line (the signature of a crash mid-append) —
  /// silently dropped rather than treated as a parse error, since losing at most the one
  /// in-flight line is the entire point of appending one line at a time instead of rewriting a
  /// single large encoded blob on every completion.
  static func parseLog(_ contents: String) -> Set<String> {
    var keys: Set<String> = []
    for line in contents.split(separator: "\n", omittingEmptySubsequences: true) {
      guard line.split(separator: "\t").count == 3 else { continue }
      keys.insert(String(line))
    }
    return keys
  }
}

/// Drives "Full Sweep": runs every registered algorithm against every shuffle *and* every
/// visualizer at least once (the full cross product — 115,230 combinations at today's registry
/// sizes), with real animated playback, resumable across app launches.
///
/// Coverage is tracked by an append-only local text file, not `PersistenceKit.AnalyticsService`'s
/// CloudKit-synced SwiftData store — bookkeeping at this scale/frequency (potentially one write
/// every few seconds for a week) has no business syncing to the user's real iCloud account. Also
/// deliberately not a positional integer cursor: this app's registries change composition often
/// enough during active development that a cursor would silently desync the moment an algorithm
/// gets added, removed, or reordered mid-sweep — seeing `CoverageSweepEnumerator`'s doc comment
/// for why genuine ID-based tracking sidesteps that entirely.
@Observable
@MainActor
public final class CoverageSweepDriver {
  public static let shared = CoverageSweepDriver()

  public private(set) var completedCount = 0
  public private(set) var currentCombo: CoverageSweepEnumerator.Combo?
  public private(set) var startedAt: Date?
  public var isRunning: Bool { task != nil }

  /// Recomputed on every access rather than cached at init — the registries can grow across app
  /// launches (a new algorithm shipped between sessions), and the confirmation dialog/progress
  /// banner should reflect that immediately rather than an initialization-time snapshot.
  public var totalCount: Int {
    AlgorithmRegistry.shared.algorithms.count * ShuffleRegistry.shared.shuffles.count
      * VisualizerRegistry.shared.visualizers.count
  }

  private var task: Task<Void, Never>?
  private var completedKeys: Set<String> = []
  private var activityToken: NSObjectProtocol?
  private let logURL: URL

  private static let logger = Logger(subsystem: "com.nhubbard.Sort2.mobile", category: "CoverageSweep")
  /// `category: "PointsOfInterest"` specifically — Instruments' Time Profiler/Metal System Trace
  /// templates only capture os-signposts from that exact category by default (confirmed the hard
  /// way: `ReplayEngine`'s own `TickApply`/`TickDispatch` signposts, under category
  /// `"ReplayEngine"`, never showed up in either template's exported `os-signpost` table at all).
  /// Brackets each combo with its full identity, so a future trace's Points of Interest track can
  /// attribute any CPU/GPU timeline anomaly to the exact algorithm/shuffle/visualizer/size running
  /// at that instant — the missing piece investigating a real Hanoi Towers large-array freeze.
  private static let signposter = OSSignposter(
    subsystem: "com.nhubbard.Sort2.mobile", category: "PointsOfInterest")

  public init(logURL: URL? = nil) {
    self.logURL = logURL ?? Self.defaultLogURL()
  }

  /// Reads the log file (if any) and updates `completedCount` — called on `start()`, and safe to
  /// call any time beforehand (e.g. so a confirmation dialog can show real prior progress before
  /// the user commits to starting/resuming).
  public func loadProgress() {
    completedKeys = Self.readLog(at: logURL)
    completedCount = completedKeys.count
  }

  public func start() {
    guard task == nil else { return }
    loadProgress()
    startedAt = Date()
    activityToken = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiated, .idleSystemSleepDisabled], reason: "Sort Symphony Full Sweep")
    task = Task { [weak self] in
      await self?.runLoop()
    }
  }

  /// Cooperative, same shape as `SortSession.runAutomation`'s cancellation: the combo currently
  /// playing always finishes cleanly, `runLoop`'s own `Task.isCancelled` check (only reached
  /// between combos) is what actually stops the sweep.
  public func stop() {
    task?.cancel()
  }

  /// `elapsed / completedCount * remaining` — the simplest possible estimate, recomputed from
  /// scratch each call rather than smoothed/tracked incrementally. Deliberately approximate: run
  /// duration varies enormously by algorithm/size, so this is "roughly how much longer," not a
  /// precise countdown.
  public func estimatedTimeRemaining() -> TimeInterval? {
    guard let startedAt, completedCount > 0 else { return nil }
    let remaining = totalCount - completedCount
    guard remaining > 0 else { return 0 }
    let elapsed = Date().timeIntervalSince(startedAt)
    return elapsed / Double(completedCount) * Double(remaining)
  }

  private func runLoop() async {
    defer {
      currentCombo = nil
      task = nil
      if let activityToken {
        ProcessInfo.processInfo.endActivity(activityToken)
      }
      activityToken = nil
    }
    while !Task.isCancelled {
      guard
        let combo = CoverageSweepEnumerator.nextUncovered(
          algorithmIDs: AlgorithmRegistry.shared.algorithms.map(\.id),
          shuffleIDs: ShuffleRegistry.shared.shuffles.map(\.id),
          visualizerIDs: VisualizerRegistry.shared.visualizers.map(\.id),
          completedKeys: completedKeys),
        let algorithm = AlgorithmRegistry.shared.algorithm(id: combo.algorithmID)
      else { break }

      currentCombo = combo
      Self.logger.notice(
        """
        running \(combo.algorithmID.rawValue, privacy: .public) + \
        \(combo.shuffleID.rawValue, privacy: .public) + \
        \(combo.visualizerID.rawValue, privacy: .public) \
        (\(self.completedCount + 1, privacy: .public)/\(self.totalCount, privacy: .public))
        """)

      let size = algorithm.metadata.effectiveSizeRange(
        operationCap: AppSettings.shared.recordingOperationCap
      ).upperBound
      let comboInterval = Self.signposter.beginInterval(
        "FullSweepCombo", id: Self.signposter.makeSignpostID(),
        "\(combo.algorithmID.rawValue) \(combo.shuffleID.rawValue) \(combo.visualizerID.rawValue) n=\(size)"
      )
      await SortCoordinator.shared.runSort(
        algorithm: algorithm, visualizerID: combo.visualizerID, shuffleID: combo.shuffleID,
        size: size)
      Self.signposter.endInterval("FullSweepCombo", comboInterval)

      Self.appendToLog(combo, at: logURL)
      completedKeys.insert(CoverageSweepEnumerator.key(for: combo))
      completedCount = completedKeys.count
    }
  }

  private static func defaultLogURL() -> URL {
    let directory =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("full-sweep-coverage.tsv")
  }

  private static func readLog(at url: URL) -> Set<String> {
    guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    return CoverageSweepEnumerator.parseLog(contents)
  }

  private static func appendToLog(_ combo: CoverageSweepEnumerator.Combo, at url: URL) {
    let line = CoverageSweepEnumerator.key(for: combo) + "\n"
    guard let data = line.data(using: .utf8) else { return }
    if let handle = try? FileHandle(forWritingTo: url) {
      defer { try? handle.close() }
      handle.seekToEndOfFile()
      handle.write(data)
    } else {
      try? data.write(to: url)
    }
  }
}
