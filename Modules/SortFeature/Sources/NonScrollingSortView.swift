import AlgorithmKit
import AudioEngineKit
import SettingsKit
import SwiftUI

/// The lean counterpart to `ScrollingSortView`, mounted instead of it whenever `ContentView`
/// already knows — before either view is even constructed — that this mount is about to run
/// through `SortSession.runAutomation`: Showcase, Full Sweep, an App-Intent-triggered run, or a
/// classic Automation. All four cycle through a fresh algorithm/shuffle/visualizer combo roughly
/// once a second, with nobody able to scroll down and read `AlgorithmDetailSection`'s content
/// before it changes again.
///
/// `ScrollingSortView` already stopped *rendering* that content in this case (see its own
/// `session.isAutomating` check), but its `GeometryReader`/`ScrollView`/`VStack` wrapper still had
/// to mount and lay out fresh on every single combo regardless — a real, visible cost a Full
/// Sweep profiling round's `AlgorithmDetailSection.highlightAllSamples` measurement (156 samples
/// despite that skip already being in place) pointed back to. This view skips that wrapper
/// entirely: just `SortView`, filling the available space, nothing else to mount or lay out.
///
/// Deliberately NOT used for the "started manual, later flipped to automating via the Automator
/// menu" case — that transition happens on an already-mounted `ScrollingSortView` (`session
/// .runAutomation(_:)` called directly, no fresh mount), which is exactly why `ScrollingSortView`
/// itself still needs its own reactive `session.isAutomating` check. This view exists purely for
/// the "we already know at mount time" cases, decided once by `ContentView`, via the same
/// `SortCoordinator.pendingActionWillAutomate`/`showcaseCompletion` signals `SortSession
/// .startsAutomating` is seeded from.
public struct NonScrollingSortView: View {
  let algorithm: any SortAlgorithm
  let arraySize: Int
  let showcaseCompletion: (() -> Void)?
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
    // Always true in practice — `ContentView` only ever constructs this view once it's already
    // determined the mount will automate — but computed the same defensive way
    // `ScrollingSortView.init` does rather than hardcoded, in case a future caller constructs
    // this directly without going through that same predicate.
    let startsAutomating =
      showcaseCompletion != nil
      || SortCoordinator.shared.pendingActionWillAutomate(for: algorithm.id)
    _session = State(
      wrappedValue: SortSession(
        algorithm: algorithm, shuffle: shuffle, audio: AudioService.shared,
        startsAutomating: startsAutomating))
  }

  public var body: some View {
    SortView(session: session, showcaseStop: showcaseStop)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle(algorithm.metadata.displayName)
      // See `ScrollingSortView`'s identical modifiers / `runSortViewLifecycle`'s doc comment —
      // tied to this view's own presence, not to the task's return.
      .onAppear {
        SortCoordinator.shared.registerActiveSession(session, for: algorithm.id)
      }
      .onDisappear {
        SortCoordinator.shared.unregisterActiveSession(for: algorithm.id)
      }
      .task {
        await runSortViewLifecycle(
          session: session, algorithm: algorithm, arraySize: arraySize,
          showcaseCompletion: showcaseCompletion, settings: settings)
      }
  }
}
