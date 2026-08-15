import AlgorithmKit
import SettingsKit

/// Shared `.task` body for `ScrollingSortView` and `NonScrollingSortView` — both mount the exact
/// same `SortSession` lifecycle (Showcase pass, App-Intent/Full-Sweep/Automation pending action,
/// or a plain manual start), differing only in what surrounds `SortView` itself. Factored out
/// once `NonScrollingSortView` needed the identical logic, rather than risking the two drifting
/// apart from independent hand-copies.
///
/// Registered/unregistered around the whole branch below (not just the intent one) —
/// `SortCoordinator`'s live-session hooks (`StopIntent`, `SetPlaybackSpeedIntent`, ...) are meant
/// to reach whichever sort is genuinely on screen, manually-started or not.
@MainActor
func runSortViewLifecycle(
  session: SortSession, algorithm: any SortAlgorithm, arraySize: Int,
  showcaseCompletion: (() -> Void)?, settings: AppSettings
) async {
  SortCoordinator.shared.registerActiveSession(session, for: algorithm.id)
  defer { SortCoordinator.shared.unregisterActiveSession(for: algorithm.id) }

  if let showcaseCompletion {
    await session.runShowcasePass()
    // Lets `RunControlBar`'s final stat values (compares/swaps/elapsed time) finish their
    // `.snappy(duration: 0.15)` settle animation before the view tears down for the next
    // algorithm — comfortably past 0.15s since a spring-based transition asymptotes rather than
    // stopping sharply. `try?` + the `Task.isCancelled` guard below: if Showcase is stopped
    // mid-delay, this just skips the (now-moot) advance instead of surfacing the resulting
    // `CancellationError`.
    try? await Task.sleep(for: .seconds(0.5))
    if !Task.isCancelled { showcaseCompletion() }
  } else if let action = SortCoordinator.shared.consumePendingAction(for: algorithm.id) {
    // An App-Intents-triggered run (`RunSortIntent`/`RunAutomationIntent`) rather than a normal
    // manually-selected screen — same "await genuine completion" contract as the Showcase branch
    // above, just reported back through `SortCoordinator` instead of a `ContentView`-owned
    // closure.
    let token = SortCoordinator.shared.runToken
    switch action {
    case .run(let visualizerID, let size):
      if let visualizerID { settings.selectedVisualizerID = visualizerID }
      await session.runSinglePass(size: size ?? arraySize)
    case .automation(let automationID):
      if let automation = AutomationRegistry.shared.automation(id: automationID) {
        await session.runAutomationAndWait(automation)
      }
    case .loadTape(let tape):
      session.loadImportedTape(tape)
    }
    if !Task.isCancelled { SortCoordinator.shared.resolveCompletion(token: token) }
  } else {
    // SortSession.start(size:) clamps into algorithm.metadata.effectiveSizeRange(...) itself, so
    // every caller gets that enforcement, not just this one.
    await session.start(size: arraySize)
  }
}
