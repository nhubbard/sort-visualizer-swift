import AlgorithmKit
import AudioEngineKit
import Foundation
import PersistenceKit
import SettingsKit
import SortEngineKit

public enum SortSessionError: Error, Equatable, Sendable {
  case recordingFailed(String)
  /// A recording (shuffle or sort) hit `RecordingEngine`'s operation cap before finishing —
  /// `compareCount`/`swapCount`/`mainWriteCount`/`auxWriteCount` are the algorithm's true totals
  /// (kept incrementing past the cap, see `RecordingEngine.appendOp`), not just the truncated
  /// tape length, so a caller has real numbers to log or display.
  case recordingTooLarge(
    operationCount: Int, cap: Int,
    compareCount: Int, swapCount: Int, mainWriteCount: Int, auxWriteCount: Int
  )
}

extension SortSessionError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .recordingFailed(let message):
      message
    case .recordingTooLarge(let operationCount, let cap, _, _, _, _):
      "This sort would take an unusually long time to finish (over \(operationCount.formatted()) "
        + "operations, past the \(cap.formatted())-operation limit) at the current settings, "
        + "so it was skipped."
    }
  }
}

/// The orchestrator — the *only* type that owns instances of `RecordingEngine`/`ReplayEngine`,
/// `AudioPlaying`, `AnalyticsService`, and `AppSettings` at once (§3.5). Each algorithm screen
/// constructs its own `SortSession`, matching v1's "each `SortView` gets its own `SortViewModel`"
/// behavior — there is no shared global sort state.
@Observable
@MainActor
public final class SortSession {
  public enum Phase {
    case idle
    case recording
    case ready(Tape)
    case replaying(ReplayEngine)
    case complete(ReplayEngine)
    case failed(SortSessionError)
  }

  public private(set) var phase: Phase = .idle

  /// The most recent `.replaying`/`.complete` replay this session has shown — unlike `phase`'s
  /// own associated value, this survives the `.recording`/`.ready` gap `start(size:)` passes
  /// through before the next run's replay exists, so `SortView` can keep rendering the previous
  /// run's final frame instead of unmounting the canvas for a `ProgressView()` on every
  /// automation iteration. Never explicitly cleared: the next `startReplay(_:)` overwrites it.
  public private(set) var lastReplay: ReplayEngine?

  /// Local to this session, seeded from `AppSettings.soundEnabled` at construction but never
  /// written back — the global setting is the *default* for new sessions, this is the
  /// currently-running sort's own on/off switch (a run-control-bar toggle, not a Settings toggle).
  public var soundEnabled: Bool

  /// The size of whatever's currently running or queued, set by `start(size:)` right after
  /// clamping — same "local, seeded-from-global-default, never-written-back" shape as
  /// `soundEnabled` above, but read-only from outside since changing it always has to go through
  /// `start(size:)` (regenerating the tape), never a bare assignment. Its initial value is a
  /// placeholder overwritten by the first real `start(size:)` call, before any size-dependent UI
  /// can appear.
  public private(set) var arraySize: Int

  /// Whether an automation loop (see `runAutomation(_:)`) is currently driving this session —
  /// the run control bar disables its own manual controls while this is true, so a stray
  /// scrub/resize/pause can't collide with the loop's own repeated `start(size:)` calls.
  public private(set) var isAutomating = false
  /// `nil` outside automation; otherwise the loop's current position, for a progress banner.
  public private(set) var automationProgress:
    (sizeIndex: Int, sizeCount: Int, runIndex: Int, runCount: Int)?
  /// Which registered `Automation` is currently running, if any — lets the Automator menu show a
  /// checkmark next to the right entry, and lets `runAutomation(_:)` tell "toggle this one off"
  /// apart from "switch to a different one" without a second tap.
  public private(set) var runningAutomationID: AutomationID?

  public let algorithm: any SortAlgorithm
  public let shuffle: any ShuffleAlgorithm
  private let audio: any AudioPlaying
  private let analytics: AnalyticsService
  private let settings: AppSettings
  /// Not a public init parameter: the only override this session ever needs is a test injecting
  /// a deterministic tick driver in place of `ReplayEngine`'s real `CADisplayLink` (see
  /// `ReplayEngine`'s own non-public `displayLinkFactory` seam, kept internal for the same
  /// reason) — `@testable import`ing tests are the only callers.
  private let replayEngineFactory: (Tape) -> ReplayEngine
  private var monitorTask: Task<Void, Never>?
  private var automationTask: Task<Void, Never>?
  /// Set by `start(size:)` whenever the most recent call skipped a capped recording instead of
  /// starting a replay — `runAutomation(sizes:runsPerSize:)` checks this right after `start
  /// (size:)` returns to decide whether to `waitUntilComplete()` (a skipped run never starts a
  /// replay, so waiting would hang forever) or move straight to the next size/run.
  private var lastRunWasSkipped = false
  /// Resolved (and cleared) the moment `phase` genuinely reaches `.complete` — lets
  /// `runAutomation` `await` one real, fully-animated run finishing before starting the next,
  /// without polling `phase` itself.
  private var completionContinuations: [CheckedContinuation<Void, Never>] = []

  public init(
    algorithm: any SortAlgorithm,
    shuffle: any ShuffleAlgorithm,
    // NOT AudioService.shared: every test that constructs a SortSession without overriding
    // `audio:` gets a real, running AudioService if this defaulted to the shared instance —
    // undesirable in a test host regardless of backend (see AudioServiceTests.swift's
    // comment). ScrollingSortView — the real app's composition root — passes AudioService
    // .shared explicitly instead (see its own comment), so the real app still hears sound;
    // this default just keeps every other caller (tests, previews) silent unless they ask.
    audio: any AudioPlaying = NoOpAudioService(),
    analytics: AnalyticsService = .shared,
    settings: AppSettings = .shared,
    replayEngineFactory: @escaping (Tape) -> ReplayEngine = { ReplayEngine(tape: $0) }
  ) {
    self.algorithm = algorithm
    self.shuffle = shuffle
    self.audio = audio
    self.analytics = analytics
    self.settings = settings
    self.replayEngineFactory = replayEngineFactory
    self.soundEnabled = settings.soundEnabled
    self.arraySize = algorithm.metadata.sizeRange.lowerBound
  }

  /// Unconditionally clamps into `algorithm.metadata.effectiveSizeRange(operationCap:)` rather
  /// than warning past it — this is ArrayV's own `unreasonableLimit` precedent (a per-sort size
  /// threshold, not a user-toggleable confirmation dialog), enforced here so every caller gets
  /// it, not just whichever view happens to clamp its own slider (§9 of ARCHITECTURE_V2.md).
  public func start(size: Int) async {
    // Stops the current sort's sound/visuals immediately instead of leaving them running
    // until the orphaned `ReplayEngine` self-terminates on its own — see the size stepper and
    // automation loop, both of which call this repeatedly on an already-running session.
    if case .replaying(let replay) = phase { replay.pause() }
    let effectiveSizeRange = algorithm.metadata.effectiveSizeRange(
      operationCap: settings.recordingOperationCap)
    let clampedSize = min(
      max(size, effectiveSizeRange.lowerBound),
      effectiveSizeRange.upperBound)
    arraySize = clampedSize
    // Only meaningful if this call turns out to hit the operation cap under automation (see
    // below) — reverting to whatever was on screen before this call is how automation
    // "pretends" a capped run never happened, instead of showing a warning nobody's watching
    // for mid-sweep.
    let previousPhase = phase
    phase = .recording

    let algorithm = self.algorithm
    let shuffle = self.shuffle
    let operationCap = settings.recordingOperationCap
    do {
      let tape = try await Task.detached(priority: .userInitiated) {
        try SortSession.makeTape(
          algorithm: algorithm, shuffle: shuffle, size: clampedSize, operationCap: operationCap)
      }.value
      lastRunWasSkipped = false
      phase = .ready(tape)
      startReplay(tape)
    } catch {
      let sessionError = (error as? SortSessionError) ?? .recordingFailed("\(error)")
      lastRunWasSkipped = true
      if isAutomating {
        if case .recordingTooLarge(
          _, let cap, let compareCount, let swapCount, let mainWriteCount, let auxWriteCount) =
          sessionError {
          try? await analytics.recordCapExceeded(
            algorithmID: algorithm.id, arraySize: clampedSize, cap: cap,
            compareCount: compareCount, swapCount: swapCount,
            mainWriteCount: mainWriteCount, auxWriteCount: auxWriteCount)
        }
        phase = previousPhase
      } else {
        phase = .failed(sessionError)
      }
    }
  }

  /// Records the shuffle against an identity array, then the sort against the shuffle's output,
  /// concatenating both into one continuous `Tape` — from `ReplayEngine`'s point of view a
  /// shuffle-then-sort is just one longer tape (§2A.4). A free function (well, static method) on
  /// purpose: no `self`, no actor isolation, callable directly from a test or from inside
  /// `Task.detached` without capturing the session itself.
  nonisolated static func makeTape(
    algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, size: Int, operationCap: Int
  ) throws -> Tape {
    let identity = Array(1...size)

    var shuffleEngine = RecordingEngine(values: identity, operationCap: operationCap)
    shuffle.record(into: &shuffleEngine)
    let uniqueValueCount = Set(shuffleEngine.values).count
    // `compare`/`swap`'s auto-retraction (`markPrimarySecondary`) only clears the *previous*
    // pair right before marking a new one — there's nothing to retract whatever pair the
    // shuffle's own last `compare`/`swap` marked, since no further call ever comes along to
    // trigger it. Without this, that leftover primary/secondary would sit on the frame for
    // however long it takes the sort's own first `compare`/`swap` to happen to overwrite it
    // (each `RecordingEngine` instance only tracks the marks *it* applied, so the sort's fresh
    // instance doesn't know to retract them either) — same bug as below, one phase earlier.
    shuffleEngine.unmarkAll()
    let shuffleSummary = shuffleEngine.finish()
    if shuffleSummary.didExceedCap {
      throw SortSessionError.recordingTooLarge(
        operationCount: shuffleSummary.tape.count, cap: operationCap,
        compareCount: shuffleSummary.compareCount, swapCount: shuffleSummary.swapCount,
        mainWriteCount: shuffleSummary.mainWriteCount, auxWriteCount: shuffleSummary.auxWriteCount)
    }

    // recordingDuration measures only the sort, not the shuffle — it's the real algorithmic
    // performance number (§1.1), and a shuffle's cost isn't the algorithm's to answer for.
    let recordingStart = Date()
    var sortEngine = RecordingEngine(values: shuffleEngine.values, operationCap: operationCap)
    algorithm.record(into: &sortEngine)
    let recordingDuration = Date().timeIntervalSince(recordingStart)
    // Same reasoning as `shuffleEngine.unmarkAll()` above, but for the far more visible case:
    // whichever pair the algorithm's very last `compare`/`swap` touched would otherwise stay
    // marked (one red, one blue) forever on the completed, fully-sorted final frame, since
    // nothing ever calls another `compare`/`swap` afterward to retract it. Placed after
    // `recordingDuration` is captured, not before, so this bookkeeping never counts against the
    // algorithm's own measured recording time.
    sortEngine.unmarkAll()
    let sortSummary = sortEngine.finish()
    if sortSummary.didExceedCap {
      throw SortSessionError.recordingTooLarge(
        operationCount: sortSummary.tape.count, cap: operationCap,
        compareCount: sortSummary.compareCount, swapCount: sortSummary.swapCount,
        mainWriteCount: sortSummary.mainWriteCount, auxWriteCount: sortSummary.auxWriteCount)
    }

    return Tape(
      header: TapeHeader(
        algorithmID: algorithm.id.rawValue,
        initialValues: identity,
        visualSeed: UInt64.random(in: .min ... .max),
        compareCount: sortSummary.compareCount,
        swapCount: sortSummary.swapCount,
        mainWriteCount: sortSummary.mainWriteCount,
        auxWriteCount: sortSummary.auxWriteCount,
        reversalCount: sortSummary.reversalCount,
        recordingDuration: recordingDuration,
        recordedAt: Date(),
        shuffleID: shuffle.id.rawValue,
        sortStartIndex: shuffleSummary.tape.count,
        uniqueValueCount: uniqueValueCount
      ),
      operations: shuffleSummary.tape + sortSummary.tape
    )
  }

  /// Loads an externally-supplied `Tape` (from `Tape(archivedData:)`, i.e. an imported `.tape`
  /// file) directly into `.ready`/`.replaying`, skipping `makeTape`'s live recording entirely —
  /// `startReplay(_:)` itself has no opinion on where a `Tape` came from, so the only real
  /// difference from `start(size:)` finishing successfully is that step.
  public func loadImportedTape(_ tape: Tape) {
    if case .replaying(let replay) = phase { replay.pause() }
    arraySize = tape.header.initialValues.count
    lastRunWasSkipped = false
    phase = .ready(tape)
    startReplay(tape)
  }

  private func startReplay(_ tape: Tape) {
    // Automation, Showcase, and manual runs all funnel through this one method, so reading the
    // pacing mode from `settings` unconditionally (no `isAutomating` branch) applies it uniformly
    // to all three, as intended — see IMPLEMENTATION_PLAN.md Phase 12 item 1.
    let playbackTape =
      settings.useFixedDurationPacing && settings.compactPlaybackForFixedDuration
      ? tape.compactedForFastPlayback() : tape
    let replay = replayEngineFactory(playbackTape)
    replay.speed = settings.playbackSpeed
    replay.useFixedDurationPacing = settings.useFixedDurationPacing
    replay.targetDuration = settings.targetPlaybackDuration
    phase = .replaying(replay)
    lastReplay = replay
    beginPlayback(replay)
  }

  /// Starts (or resumes, after a `pause()`) the timed playback loop, and (re-)arms a monitor
  /// that only transitions `phase` to `.complete` — and records analytics — once the replay has
  /// *genuinely* finished (`stepIndex` reached the end), not merely whenever the current
  /// `playbackTask` stops running. A `pause()` also stops that task (by cancellation), so without
  /// this distinction, pausing would immediately look like completion and both mark the sort done
  /// early and double-record analytics on a later real completion.
  private func beginPlayback(_ replay: ReplayEngine) {
    let playbackTask = replay.play(onStep: makeOnStepClosure(for: replay))
    monitorTask?.cancel()
    // `replay` must be captured weakly, same as `self` — this closure `await`s the *entire*
    // remaining playback, however long that takes, so a strong capture here would keep the
    // whole `ReplayEngine` (its full tape, checkpoints, frame) alive for that entire duration
    // even after `self` (and whatever view owned it) is long gone — e.g. navigating away from
    // a still-playing sort. `SortSession`'s own `deinit` below cancels this promptly instead
    // of waiting on it to resolve on its own.
    monitorTask = Task { [weak self, weak replay] in
      await playbackTask.value
      guard let self, let replay, replay.stepIndex >= replay.totalOperationCount else { return }
      self.phase = .complete(replay)
      // Read here, at the exact moment genuine completion is observed — not later, and not
      // cached from an earlier tick — so this reflects the real elapsed wall-clock up to
      // this instant regardless of anything else that might read `elapsedPlaybackDuration`
      // afterward (e.g. `RunControlBar`, still displaying `.complete` state).
      // `replay.speed` is the exact value the user configured and is what fixed-rate mode
      // actually paces against, so it stays the recorded number there — same as before this
      // feature. In fixed-duration mode `speed` is inert (see `ReplayEngine.currentPacingRate`'s
      // doc comment), so record the true achieved average instead
      // (`significantOperationCount / elapsedPlaybackDuration`, matching what `RunControlBar`'s
      // own "ops/sec" stat already computes) rather than a meaningless stored number.
      let recordedSpeed: Double
      if replay.useFixedDurationPacing {
        recordedSpeed =
          replay.elapsedPlaybackDuration > 0
          ? Double(replay.significantOperationCount) / replay.elapsedPlaybackDuration
          : replay.speed
      } else {
        recordedSpeed = replay.speed
      }
      try? await self.analytics.record(
        replay.header, algorithmID: self.algorithm.id,
        playbackDuration: replay.elapsedPlaybackDuration, playbackSpeed: recordedSpeed
      )
      let continuations = self.completionContinuations
      self.completionContinuations = []
      for continuation in continuations { continuation.resume() }
    }
  }

  /// Suspends until the current run reaches `.complete` — used by `runAutomation` to sequence
  /// real, fully-animated runs one after another instead of firing them all at once.
  private func waitUntilComplete() async {
    if case .complete = phase { return }
    await withCheckedContinuation { completionContinuations.append($0) }
  }

  /// Starts a registered `Automation`, or stops it if it's the one already running — tapping a
  /// *different* automation while one is running cancels the old one and starts the new one in
  /// the same call, no second tap needed. Each entry supplies its own sizes (a size sweep or a
  /// single max-size run) and `runsPerSize`; see `AutomationRegistry`. Cancelling mid-run takes
  /// effect once the in-flight sort finishes playing, rather than yanking the tape out from
  /// under `ReplayEngine` mid-playback.
  public func runAutomation(_ automation: Automation) {
    if runningAutomationID == automation.id {
      stopAutomation()
      return
    }
    automationTask?.cancel()
    runningAutomationID = automation.id
    automationTask = Task {
      await runAutomation(
        sizes: automation.sizes(algorithm.metadata), runsPerSize: automation.runsPerSize)
    }
  }

  /// Cancels whichever automation is currently running, if any — the automation banner's "Stop"
  /// button calls this directly rather than looking up which `Automation` is running just to
  /// hand it back to `runAutomation(_:)`.
  public func stopAutomation() {
    automationTask?.cancel()
    runningAutomationID = nil
  }

  /// Runs exactly one full pass at `size`, awaiting genuine completion — the primitive behind
  /// both Showcase's per-algorithm step (`runShowcasePass()` below) and an App-Intents-triggered
  /// "run this once and report back" request, neither of which can just fire-and-forget the way
  /// the keyboard-shortcut/Automator-menu callers of `runAutomation(_:)` do.
  public func runSinglePass(size: Int) async {
    await runAutomation(sizes: [size], runsPerSize: 1)
  }

  /// Runs this algorithm once, at its own `sizeRange.upperBound` — the per-algorithm unit of work
  /// Showcase mode's cross-algorithm loop drives, one fresh `SortSession` at a time.
  public func runShowcasePass() async {
    let effectiveSizeRange = algorithm.metadata.effectiveSizeRange(
      operationCap: settings.recordingOperationCap)
    await runSinglePass(size: effectiveSizeRange.upperBound)
  }

  /// Awaits genuine completion (or an early stop via `stopAutomation()`) of a sweep — the
  /// primitive App Intents needs to report "the sweep is over" back to Shortcuts, rather than
  /// firing the loop and returning immediately the way the keyboard-shortcut/Automator-menu
  /// callers of `runAutomation(_:)` do. Safe on a freshly-constructed session only, since
  /// `runningAutomationID` always starts `nil` here.
  ///
  /// Deliberately does NOT call the fire-and-forget `runAutomation(_:)` above and then poll
  /// `isAutomating`: a freshly spawned `Task`'s body can't run before the *next* suspension point
  /// in the caller, so a `guard isAutomating else { return }` with no intervening `await` always
  /// observes the pre-Task default (`false`) and returns immediately. Awaiting the spawned
  /// `Task`'s own `.value` instead has no such gap.
  public func runAutomationAndWait(_ automation: Automation) async {
    automationTask?.cancel()
    runningAutomationID = automation.id
    let task = Task {
      await runAutomation(
        sizes: automation.sizes(algorithm.metadata), runsPerSize: automation.runsPerSize)
    }
    automationTask = task
    await task.value
  }

  /// Advances `arraySize` to the next value in `algorithm.metadata.sizeRange` (stepped by
  /// `sizeStep`), wrapping back to the smallest past the largest — the same ring-buffer shape as
  /// `AppSettings.cycleVisualizer()`, just over sizes instead of visualizers. Backs `⌘S`.
  public func cycleArraySize() async {
    let effectiveSizeRange = algorithm.metadata.effectiveSizeRange(
      operationCap: settings.recordingOperationCap)
    let sizes = effectiveSizeRange.steppedValues(by: effectiveSizeRange.steppedSizeStep)
    guard !sizes.isEmpty else { return }
    let currentIndex = sizes.firstIndex(of: arraySize) ?? -1
    let nextIndex = (currentIndex + 1) % sizes.count
    await start(size: sizes[nextIndex])
  }

  private func runAutomation(sizes: [Int], runsPerSize: Int) async {
    isAutomating = true
    defer {
      isAutomating = false
      automationProgress = nil
      automationTask = nil
      runningAutomationID = nil
    }
    for (sizeIndex, size) in sizes.enumerated() {
      for runIndex in 0..<runsPerSize {
        guard !Task.isCancelled else { return }
        automationProgress = (sizeIndex, sizes.count, runIndex, runsPerSize)
        await start(size: size)
        if lastRunWasSkipped { continue }
        await waitUntilComplete()
      }
    }
  }

  /// Toggles between playing and paused. In `.replaying`, this is a normal pause/resume.
  ///
  /// In `.complete`, resumes only if `stepIndex` is no longer at the very end. The scrub slider,
  /// step-back, and Reset call `seek(to:)`/`stepBackward()` directly on `replay`, bypassing
  /// `SortSession`, so none of them transition `phase` back to `.replaying` on their own —
  /// without this case, scrubbing backward after completion would leave play looking enabled but
  /// inert. A `.complete` sort still at the very end stays a no-op so a stray tap can't
  /// re-trigger analytics recording.
  public func togglePlayback() {
    switch phase {
    case .replaying(let replay):
      if replay.isPlaying {
        replay.pause()
      } else {
        beginPlayback(replay)
      }
    case .complete(let replay) where replay.stepIndex < replay.totalOperationCount:
      phase = .replaying(replay)
      beginPlayback(replay)
    default:
      break
    }
  }

  /// One note per touched index, keyed on that index's **current** value (post-operation) —
  /// matches v1's "play a note per touched index" behavior (`compare`/`swap` both play both
  /// indices; `setValue` plays the one it touched), but pitch tracks value, not index (§3.1).
  /// Reads `soundEnabled`/`replay.currentPacingRate` live on every call (both are
  /// `weak`/reference-captured), so toggling sound or adjusting speed mid-replay takes effect on
  /// the very next operation. `currentPacingRate`, not `speed` — `speed` is meaningless while
  /// `useFixedDurationPacing` is on (see `ReplayEngine.currentPacingRate`'s doc comment), and notes
  /// need to track the actual cadence either way.
  private func makeOnStepClosure(for replay: ReplayEngine) -> (SortOperation) -> Void {
    let audio = self.audio
    return { [weak self, weak replay] operation in
      guard let self, self.soundEnabled, let replay else { return }
      let holdSeconds = max(1.0 / replay.currentPacingRate, 0.03)
      let range = 1...replay.frame.count
      switch operation {
      case .compare(let i, let j), .swap(let i, let j):
        audio.play(value: replay.frame[i].value, in: range, holdSeconds: holdSeconds)
        audio.play(value: replay.frame[j].value, in: range, holdSeconds: holdSeconds)
      case .setValue(let i, _):
        audio.play(value: replay.frame[i].value, in: range, holdSeconds: holdSeconds)
      default:
        break
      }
    }
  }
}
