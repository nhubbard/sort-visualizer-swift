import AlgorithmKit
import AudioEngineKit
import Foundation
import PersistenceKit
import SettingsKit
import SortEngineKit

public enum SortSessionError: Error, Equatable, Sendable {
    case recordingFailed(String)
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
    /// own associated value, this deliberately *survives* the `.recording`/`.ready` gap `start
    /// (size:)` passes through before the next run's replay exists, so `SortView` can keep
    /// rendering the previous run's final frame instead of unmounting the canvas for a
    /// `ProgressView()` on every single automation iteration (a real, reported flash — see
    /// `SortView.content`'s own doc comment). Never explicitly cleared: the next `startReplay(_:)`
    /// simply overwrites it, and the old `ReplayEngine` deallocates once nothing else (this
    /// property included) still holds it.
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
    public private(set) var automationProgress: (sizeIndex: Int, sizeCount: Int, runIndex: Int, runCount: Int)?
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

    /// Unconditionally clamps into `algorithm.metadata.sizeRange` rather than warning past it —
    /// this is ArrayV's own `unreasonableLimit` precedent (a per-sort size threshold, not a
    /// user-toggleable confirmation dialog), enforced here so every caller gets it, not just
    /// whichever view happens to clamp its own slider (§9 of ARCHITECTURE_V2.md).
    public func start(size: Int) async {
        // Stops the current sort's sound/visuals immediately instead of leaving them running
        // until the orphaned `ReplayEngine` self-terminates on its own — see the size stepper and
        // automation loop, both of which call this repeatedly on an already-running session.
        if case let .replaying(replay) = phase { replay.pause() }
        let clampedSize = min(
            max(size, algorithm.metadata.sizeRange.lowerBound),
            algorithm.metadata.sizeRange.upperBound)
        arraySize = clampedSize
        phase = .recording

        let algorithm = self.algorithm
        let shuffle = self.shuffle
        let tape = await Task.detached(priority: .userInitiated) {
            SortSession.makeTape(algorithm: algorithm, shuffle: shuffle, size: clampedSize)
        }.value

        phase = .ready(tape)
        startReplay(tape)
    }

    /// Records the shuffle against an identity array, then the sort against the shuffle's output,
    /// concatenating both into one continuous `Tape` — from `ReplayEngine`'s point of view a
    /// shuffle-then-sort is just one longer tape (§2A.4). A free function (well, static method) on
    /// purpose: no `self`, no actor isolation, callable directly from a test or from inside
    /// `Task.detached` without capturing the session itself.
    nonisolated static func makeTape(algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, size: Int) -> Tape {
        let identity = Array(1...size)

        var shuffleEngine = RecordingEngine(values: identity)
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

        // recordingDuration measures only the sort, not the shuffle — it's the real algorithmic
        // performance number (§1.1), and a shuffle's cost isn't the algorithm's to answer for.
        let recordingStart = Date()
        var sortEngine = RecordingEngine(values: shuffleEngine.values)
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

    private func startReplay(_ tape: Tape) {
        let replay = replayEngineFactory(tape)
        replay.speed = settings.playbackSpeed
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
            try? await self.analytics.record(
                replay.header, algorithmID: self.algorithm.id,
                playbackDuration: replay.elapsedPlaybackDuration, playbackSpeed: replay.speed
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
            await runAutomation(sizes: automation.sizes(algorithm.metadata), runsPerSize: automation.runsPerSize)
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
        await runSinglePass(size: algorithm.metadata.sizeRange.upperBound)
    }

    /// Awaits genuine completion (or an early stop via `stopAutomation()`) of a sweep — the
    /// primitive App Intents needs to report "the sweep is over" back to Shortcuts, rather than
    /// firing the loop and returning immediately the way the keyboard-shortcut/Automator-menu
    /// callers of `runAutomation(_:)` do. Safe on a freshly-constructed session only:
    /// `runAutomation(_:)`'s own "tap again to stop" toggle can't trigger here, since
    /// `runningAutomationID` always starts `nil`.
    ///
    /// Deliberately does NOT call the fire-and-forget `runAutomation(_:)` above and then poll
    /// `isAutomating` to decide whether to wait — that shape had a real, deterministic (not just
    /// racy) bug: a freshly spawned `Task`'s body cannot run any sooner than the *next* suspension
    /// point in the caller, so a `guard isAutomating else { return }` checked on the very next line
    /// with no intervening `await` always observed the pre-Task default (`false`) and returned
    /// immediately, before the sweep had done any real work — this is what silently skipped
    /// almost every algorithm in `RunFullSizeSweepIntent`, each just flashing `.idle` before the
    /// next one replaced it. Awaiting the spawned `Task`'s own `.value` instead has no such gap.
    public func runAutomationAndWait(_ automation: Automation) async {
        automationTask?.cancel()
        runningAutomationID = automation.id
        let task = Task {
            await runAutomation(sizes: automation.sizes(algorithm.metadata), runsPerSize: automation.runsPerSize)
        }
        automationTask = task
        await task.value
    }

    /// Advances `arraySize` to the next value in `algorithm.metadata.sizeRange` (stepped by
    /// `sizeStep`), wrapping back to the smallest past the largest — the same ring-buffer shape as
    /// `AppSettings.cycleVisualizer()`, just over sizes instead of visualizers. Backs `⌘S`.
    public func cycleArraySize() async {
        let sizes = algorithm.metadata.sizeRange.steppedValues(by: algorithm.metadata.sizeStep)
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
                await waitUntilComplete()
            }
        }
    }

    /// Toggles between playing and paused. In `.replaying`, this is a normal pause/resume.
    ///
    /// In `.complete`, it resumes only if `stepIndex` is no longer at the very end — the scrub
    /// slider, step-back, and Reset all call `seek(to:)`/`stepBackward()` directly on `replay`,
    /// bypassing `SortSession` entirely, so none of them ever transition `phase` back to
    /// `.replaying` on their own; without this case, scrubbing backward after a sort finishes
    /// would leave the play button looking enabled but silently doing nothing. A `.complete` sort
    /// still sitting at the very end remains a no-op — a stray tap on a play button the UI failed
    /// to disable can't re-trigger analytics recording.
    public func togglePlayback() {
        switch phase {
        case let .replaying(replay):
            if replay.isPlaying {
                replay.pause()
            } else {
                beginPlayback(replay)
            }
        case let .complete(replay) where replay.stepIndex < replay.totalOperationCount:
            phase = .replaying(replay)
            beginPlayback(replay)
        default:
            break
        }
    }

    /// One note per touched index, keyed on that index's **current** value (post-operation) —
    /// matches v1's "play a note per touched index" behavior (`compare`/`swap` both play both
    /// indices; `setValue` plays the one it touched), but pitch tracks value, not index (§3.1).
    /// Reads `soundEnabled`/`replay.speed` live on every call (both are `weak`/reference-captured),
    /// so toggling sound or adjusting speed mid-replay takes effect on the very next operation.
    private func makeOnStepClosure(for replay: ReplayEngine) -> (SortOperation) -> Void {
        let audio = self.audio
        return { [weak self, weak replay] operation in
            guard let self, self.soundEnabled, let replay else { return }
            let holdSeconds = max(1.0 / replay.speed, 0.03)
            let range = 1...replay.frame.count
            switch operation {
            case let .compare(i, j), let .swap(i, j):
                audio.play(value: replay.frame[i].value, in: range, holdSeconds: holdSeconds)
                audio.play(value: replay.frame[j].value, in: range, holdSeconds: holdSeconds)
            case let .setValue(i, _):
                audio.play(value: replay.frame[i].value, in: range, holdSeconds: holdSeconds)
            default:
                break
            }
        }
    }
}
