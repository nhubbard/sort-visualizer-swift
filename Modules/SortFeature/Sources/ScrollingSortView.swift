import AlgorithmKit
import AudioEngineKit
import SettingsKit
import SwiftUI

public struct ScrollingSortView: View {
  let algorithm: any SortAlgorithm
  let arraySize: Int
  /// Non-`nil` when this instance is one step of Showcase mode (`ContentView`) rather than a
  /// normal manually-selected algorithm screen — swaps `.task` from a plain `start(size:)` to
  /// `session.runShowcasePass()` (locking `RunControlBar` via `isAutomating`) and reports back
  /// when that pass finishes so `ContentView` can advance to the next algorithm. Guarded by
  /// `!Task.isCancelled` at the call site: `ContentView` stops Showcase by changing `selection`,
  /// which tears this view down and cancels its `.task` — without the guard, a run already
  /// finishing at that exact moment could still fire "advance" once more.
  let showcaseCompletion: (() -> Void)?
  /// Non-`nil` under the same condition as `showcaseCompletion` (both come from `ContentView`'s
  /// `showcaseIndex != nil`) — wired to `ContentView.stopShowcase()`, for `SortView`'s embedded
  /// automation-banner Stop button to call instead of `SortSession.stopAutomation()` (a no-op
  /// during Showcase, since it never goes through `SortSession.automationTask`; see
  /// `SortSession.runShowcasePass()`'s doc comment).
  let showcaseStop: (() -> Void)?
  @State private var session: SortSession
  @Environment(AppSettings.self) private var settings

  @MainActor
  public init(
    algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, arraySize: Int = 48,
    showcaseCompletion: (() -> Void)? = nil, showcaseStop: (() -> Void)? = nil
  ) {
    self.algorithm = algorithm
    self.arraySize = arraySize
    self.showcaseCompletion = showcaseCompletion
    self.showcaseStop = showcaseStop
    // AudioService.shared, not the NoOpAudioService default: `AudioService.play()`'s `try?
    // start()` already fails silently if a host has no usable audio route (e.g. a sandboxed CI
    // runner), so this is safe even off-device. `AppSettings.soundEnabled` still gates whether a
    // sort plays anything at all; this is just which backend answers when it does.
    _session = State(
      wrappedValue: SortSession(algorithm: algorithm, shuffle: shuffle, audio: AudioService.shared))
  }

  public var body: some View {
    // Matches Legacy/Shared/Views/Main/ScrollingSortView.swift's own GeometryReader approach:
    // the sort visualization fills the whole visible viewport on first appearance (not a
    // fixed/minimum height), with the detail section sitting below the fold — a deliberate
    // "the animation is the main event" layout, not a byproduct of ScrollView's own sizing.
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          SortView(session: session, showcaseStop: showcaseStop)
            .frame(width: geometry.size.width, height: geometry.size.height)
          // `session.isAutomating` covers Showcase, Full Sweep, App-Intent single runs, and
          // classic Automations alike (all four route through the same private
          // `SortSession.runAutomation(sizes:runsPerSize:)`) — every case where a fresh combo
          // arrives roughly once a second and nobody has time to scroll down and actually read
          // the description/complexity/code/correlation chart before it changes again. Skipping
          // `AlgorithmDetailSection` entirely here avoids its full cost (SwiftData fetch, code
          // highlighting, math rendering) rather than just hiding an already-built view — found
          // via the same Full Sweep profiling round that fixed `CodeTheme`'s hex parsing and
          // `AnalyticsService.fetchSummaries`'s cache-defeating write/read cycle.
          if session.isAutomating {
            Text("Details hidden during automation")
              .font(.callout)
              .foregroundStyle(.secondary)
              .padding()
              .accessibilityIdentifier("algorithmDetailAutomationPlaceholder")
          } else {
            AlgorithmDetailSection(algorithm: algorithm, availableWidth: geometry.size.width)
          }
        }
      }
    }
    .navigationTitle(algorithm.metadata.displayName)
    .task {
      // Registered/unregistered around the whole branch below (not just the intent one) —
      // `SortCoordinator`'s live-session hooks (`StopIntent`, `SetPlaybackSpeedIntent`, ...)
      // are meant to reach whichever sort is genuinely on screen, manually-started or not.
      SortCoordinator.shared.registerActiveSession(session, for: algorithm.id)
      defer { SortCoordinator.shared.unregisterActiveSession(for: algorithm.id) }

      if let showcaseCompletion {
        await session.runShowcasePass()
        // Lets `RunControlBar`'s final stat values (compares/swaps/elapsed time) finish their
        // `.snappy(duration: 0.15)` settle animation before the view tears down for the next
        // algorithm — comfortably past 0.15s since a spring-based transition asymptotes rather
        // than stopping sharply. `try?` + the `Task.isCancelled` guard below: if Showcase is
        // stopped mid-delay, this just skips the (now-moot) advance instead of surfacing the
        // resulting `CancellationError`.
        try? await Task.sleep(for: .seconds(0.5))
        if !Task.isCancelled { showcaseCompletion() }
      } else if let action = SortCoordinator.shared.consumePendingAction(for: algorithm.id) {
        // An App-Intents-triggered run (`RunSortIntent`/`RunAutomationIntent`) rather than
        // a normal manually-selected screen — same "await genuine completion" contract as
        // the Showcase branch above, just reported back through `SortCoordinator` instead
        // of a `ContentView`-owned closure.
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
        // SortSession.start(size:) clamps into algorithm.metadata.effectiveSizeRange(...) itself,
        // so every caller gets that enforcement, not just this one.
        await session.start(size: arraySize)
      }
    }
  }
}
