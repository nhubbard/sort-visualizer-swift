import AlgorithmKit
import Foundation
import SettingsKit
import SortEngineKit
import VisualizationKit

/// The bridge App Intents needs and `ContentView`/`ScrollingSortView` never did before: neither
/// `SortSession` (one per algorithm screen, owned locally) nor `ContentView`'s sidebar `selection`/
/// `showcaseIndex` (private `@State`) were reachable from outside SwiftUI's own view tree. An
/// `AppIntent.perform()` runs detached from any specific view, so it needs one shared, `@MainActor`
/// singleton — this type — to say "select this algorithm and run it" and later find out the run
/// actually finished, mirroring the exact "select via the same path a manual tap would use, await
/// genuine completion" shape `ContentView`'s existing Showcase mode already established.
@Observable
@MainActor
public final class SortCoordinator {
  public static let shared = SortCoordinator()

  /// One entry per algorithm with an intent-triggered run still waiting to be picked up —
  /// consumed exactly once, by whichever `ScrollingSortView.task` mounts for that algorithm next.
  public enum PendingAction: Sendable {
    case run(visualizerID: VisualizerID?, size: Int?)
    case automation(AutomationID)
    /// An imported tape (`Tape(archivedData:)`), routed the same way as an intent-triggered run —
    /// see `loadTape(_:algorithm:)` below.
    case loadTape(Tape)
  }

  /// `ContentView`'s sidebar `List(selection:)` binds directly to this (via `@Bindable`) instead
  /// of owning its own `selection` `@State` — so a `RunSortIntent`/`RunAutomationIntent`
  /// navigating the app looks, to the sidebar, exactly like a manual tap, and so a manual tap
  /// while the app is already open is just as visible to anything reading this from outside the
  /// view tree. Same precedent as `ContentView`'s own Showcase mode driving `selection` itself.
  public var selectedAlgorithmID: AlgorithmID? {
    didSet {
      // Snapshotted here, at the exact moment `beginRun` sets both `pendingActions[algorithmID]`
      // and `selectedAlgorithmID` together, rather than read live from `pendingActionWillAutomate`
      // wherever it's needed — that method's answer flips to `false` the instant `.task` calls
      // `consumePendingAction`, which happens almost immediately, well before the run it kicked
      // off actually finishes. `ContentView.detailContent` used to branch on the live method
      // directly, so any unrelated re-render during that run's ~1s of real animation (a Full
      // Sweep progress update, anything) flipped the branch back to `ScrollingSortView` mid-flight
      // — tearing down `NonScrollingSortView` and cancelling its `.task` before it ever reached
      // `resolveCompletion`, hanging `runSort`'s continuation forever. `CoverageSweepDriver
      // .runLoop`'s `await SortCoordinator.shared.runSort(...)` then just sat there: no TSV
      // append, no advance to the next combo, indistinguishable from "stuck after one sort." This
      // snapshot instead stays fixed for a selection's whole lifetime, only changing in lockstep
      // with `selectedAlgorithmID`/`runToken` themselves (both flip together on the next real
      // selection change) — so `detailContent`'s branch and its `.id(...)` never disagree.
      currentSelectionWillAutomate = selectedAlgorithmID.map(pendingActionWillAutomate(for:)) ?? false
    }
  }
  /// Stable per-selection snapshot of `pendingActionWillAutomate(for:)` — see `selectedAlgorithmID`
  /// `didSet` above for why this exists instead of calling that method live from `ContentView`.
  public private(set) var currentSelectionWillAutomate = false
  /// `ContentView`'s Settings sheet binds directly to this instead of owning its own
  /// `@State` — the scene-level `SortCommands` menu (⌘,) needs somewhere reachable to request the
  /// sheet from outside the view tree, same rationale as `selectedAlgorithmID` above.
  public var isSettingsRequested = false
  /// Bumped on every intent-triggered run — folded into `ScrollingSortView`'s `.id(...)` so
  /// re-running the *same* algorithm from a Shortcut always mounts a genuinely fresh
  /// `SortSession` instead of silently no-op'ing against one that already reached `.complete`.
  public private(set) var runToken = 0

  private var pendingActions: [AlgorithmID: PendingAction] = [:]
  private var pendingShuffleOverrides: [AlgorithmID: ShuffleID] = [:]
  private var completions: [Int: CheckedContinuation<Void, Never>] = [:]

  /// The one `SortSession` currently on screen, if any — `weak` because `ScrollingSortView`'s own
  /// `@State` is the sole rightful owner; registering here must never be what keeps a finished or
  /// navigated-away-from session alive (see the replay-leak fix this project already shipped).
  /// Only ever one at a time: `ContentView`'s `NavigationSplitView` shows exactly one detail pane.
  private weak var activeSession: SortSession?
  private var activeSessionAlgorithmID: AlgorithmID?

  public init() {}

  // MARK: - ContentView / ScrollingSortView integration

  /// Read (without consuming) by `ContentView.detailContent` before constructing a
  /// `ScrollingSortView` — `shuffle` is a one-shot `SortSession` constructor argument, fixed for
  /// that session's whole lifetime, so an override has to be known *before* construction, unlike
  /// the rest of `PendingAction`, which `ScrollingSortView.task` only needs once mounted.
  public func pendingShuffleOverride(for algorithmID: AlgorithmID) -> ShuffleID? {
    pendingShuffleOverrides[algorithmID]
  }

  /// Read (without consuming) by `ScrollingSortView.init`, same rationale as
  /// `pendingShuffleOverride(for:)` above: whether the pending action this view is about to
  /// consume will run the session through `SortSession.runAutomation(sizes:runsPerSize:)` (and
  /// therefore set `isAutomating`) has to be known *before* construction, so `SortSession` can be
  /// seeded with the right initial `isAutomating` value instead of starting `false` and only
  /// catching up once its `.task` actually calls `runSinglePass`/`runAutomationAndWait` — a real,
  /// measured gap that let `AlgorithmDetailSection` mount transiently on every Full Sweep combo
  /// before this fix. `.run`/`.automation` both lead there unconditionally (see
  /// `ScrollingSortView.body`'s `.task`); `.loadTape` does not (it only replaces the session's
  /// tape, no automation pass).
  public func pendingActionWillAutomate(for algorithmID: AlgorithmID) -> Bool {
    switch pendingActions[algorithmID] {
    case .run, .automation: true
    case .loadTape, nil: false
    }
  }

  /// Consumed exactly once by `ScrollingSortView.task` on mount — clears both the action and any
  /// paired shuffle override together, since `runSort`/`runAutomation` below always set them in
  /// the same call.
  public func consumePendingAction(for algorithmID: AlgorithmID) -> PendingAction? {
    pendingShuffleOverrides.removeValue(forKey: algorithmID)
    return pendingActions.removeValue(forKey: algorithmID)
  }

  /// `ScrollingSortView` calls this on mount and clears it again on teardown — the only way any
  /// intent gets a handle to a *live*, already-open session (for `StopIntent`, or a setting
  /// intent that also wants to nudge the sort currently on screen).
  public func registerActiveSession(_ session: SortSession, for algorithmID: AlgorithmID) {
    activeSession = session
    activeSessionAlgorithmID = algorithmID
  }

  public func unregisterActiveSession(for algorithmID: AlgorithmID) {
    guard activeSessionAlgorithmID == algorithmID else { return }
    activeSession = nil
    activeSessionAlgorithmID = nil
  }

  /// Resolved by `ScrollingSortView.task` once the pending action it consumed has genuinely
  /// finished — lets `runSort`/`runAutomation` below `await` the real result instead of returning
  /// the moment the app merely opens to the right screen.
  public func resolveCompletion(token: Int) {
    completions.removeValue(forKey: token)?.resume()
  }

  // MARK: - Live-session hooks (for intents that only make sense against an open sort)

  /// `nil` when nothing is currently on screen — every intent that reads this treats that as "no
  /// effect," not an error, since a purely-settings-scoped intent (e.g. `SetPlaybackSpeedIntent`)
  /// is still meaningful with the app closed; it just has nothing live left to also nudge.
  public var activeSortSession: SortSession? { activeSession }

  // MARK: - Intent entry points

  /// Selects `algorithm` and awaits one fully-animated pass at `size` (falling back to whatever
  /// size `ContentView` would otherwise use) — the primitive behind `RunSortIntent`, and, chained
  /// with `FindAlgorithmsIntent` + Shortcuts' own "Repeat with Each," a full replacement for
  /// Showcase mode's cross-algorithm loop, implemented entirely in the Shortcuts app instead of
  /// this one.
  public func runSort(
    algorithm: any SortAlgorithm, visualizerID: VisualizerID?, shuffleID: ShuffleID?, size: Int?
  ) async {
    let token = beginRun(
      algorithm: algorithm.id, shuffleID: shuffleID,
      action: .run(visualizerID: visualizerID, size: size))
    await withCheckedContinuation { completions[token] = $0 }
  }

  /// Selects `algorithm` and awaits an entire registered `Automation` sweep — the primitive
  /// behind `RunAutomationIntent`, replacing the ⌘⇧A/⌘⌥⇧A keyboard shortcuts and Automator menu's
  /// *reachability* without touching the `SortSession.runAutomation(_:)` engine underneath either
  /// of them.
  public func runAutomation(algorithm: any SortAlgorithm, automationID: AutomationID) async {
    let token = beginRun(algorithm: algorithm.id, shuffleID: nil, action: .automation(automationID))
    await withCheckedContinuation { completions[token] = $0 }
  }

  /// Stops whatever the currently-open session is running — `StopIntent`'s entire body. A no-op
  /// if nothing is open or nothing is running, same as tapping the automation banner's Stop
  /// button when it isn't shown.
  public func stop() {
    activeSession?.stopAutomation()
  }

  /// Selects `algorithm` and routes `tape` to whichever `ScrollingSortView.task` mounts for it
  /// next — the "Import Tape" entry point's primitive. Deliberately synchronous, unlike
  /// `runSort`/`runAutomation` above: those `await` a genuine completion because an App Intent
  /// needs to report back to Shortcuts, but nothing here needs to wait on anything, so this
  /// skips the `completions`/`beginRun`-continuation machinery entirely.
  public func loadTape(_ tape: Tape, algorithm: any SortAlgorithm) {
    _ = beginRun(algorithm: algorithm.id, shuffleID: nil, action: .loadTape(tape))
  }

  /// The result of `importTape(from:)` — a plain value instead of `throws`, since one of its
  /// failure modes (`unrecognizedAlgorithm`) isn't an `Error` at all, just a `String` this build's
  /// `AlgorithmRegistry` doesn't have an entry for.
  public enum TapeImportResult: Sendable, Equatable {
    case success
    case unrecognizedAlgorithm(algorithmID: String)
    case decodeFailed(String)
  }

  /// Decodes `data` (an exported `.tape` file's contents) and, if it names an algorithm this
  /// build actually has registered, routes it through `loadTape(_:algorithm:)` above — keeps
  /// `Tape`/`TapeArchiveError` entirely inside `SortEngineKit`/`SortFeature` rather than leaking
  /// into `ContentView`, which only needs to turn a `.fileImporter` result into user-facing text.
  public func importTape(from data: Data) -> TapeImportResult {
    let tape: Tape
    do {
      tape = try Tape(archivedData: data)
    } catch {
      return .decodeFailed("\(error)")
    }
    guard
      let algorithm = AlgorithmRegistry.shared.algorithm(
        id: AlgorithmID(rawValue: tape.header.algorithmID))
    else {
      return .unrecognizedAlgorithm(algorithmID: tape.header.algorithmID)
    }
    loadTape(tape, algorithm: algorithm)
    return .success
  }

  private func beginRun(
    algorithm algorithmID: AlgorithmID, shuffleID: ShuffleID?, action: PendingAction
  ) -> Int {
    runToken += 1
    pendingActions[algorithmID] = action
    pendingShuffleOverrides[algorithmID] = shuffleID
    selectedAlgorithmID = algorithmID
    return runToken
  }

  /// Selects `algorithmID` and always bumps `runToken`, even when `algorithmID` already equals
  /// `selectedAlgorithmID` — a plain assignment in that case is a silent no-op (`@Observable`
  /// elides the change notification for an equal value), so `ContentView.detailContent`'s
  /// `.id(...)` never changes and `ScrollingSortView` never remounts. Showcase mode hit exactly
  /// this: starting it while already viewing the alphabetically-first algorithm (the one Showcase
  /// itself starts with) left the old, non-showcase-aware view/task running untouched underneath
  /// the showcase banner. Mirrors `beginRun`'s `runToken` bump without its `pendingActions`/
  /// `pendingShuffleOverrides` bookkeeping — Showcase drives completion via `ScrollingSortView`'s
  /// `showcaseCompletion`/`showcaseStop` parameters directly, not the `PendingAction` mechanism.
  public func selectAlgorithmForFreshView(_ algorithmID: AlgorithmID) {
    runToken += 1
    selectedAlgorithmID = algorithmID
  }
}
