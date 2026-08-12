import AlgorithmKit
import DesignSystemKit
import HomeFeature
import SettingsFeature
import SettingsKit
import SortFeature
import SwiftUI
import UniformTypeIdentifiers
import os

/// Brackets an entire Showcase pass (every registered algorithm, in order) for a manual
/// Instruments capture — a full pass can run for many minutes, so a "ShowcaseRun" interval here
/// means a trace can be scrubbed straight to the window that actually matters instead of guessing
/// from wall-clock timestamps against whenever the recording happened to be started/stopped.
private let showcaseSignposter = OSSignposter(subsystem: "com.nhubbard.Sort2.mobile", category: "Showcase")

/// Sidebar/content columns are generated directly from `AlgorithmRegistry.shared.algorithms(in:)`,
/// sectioned by `AlgorithmCategory` — registering a new algorithm requires no changes to this
/// file.
///
/// Two-tier `NavigationSplitView` (category sidebar → algorithm content → detail), not a single
/// collapsible-`Section`-per-category `List`: that toggle-driven collapse was a small touch
/// target, was annoying on Mac, and fought `.searchable` (a match inside a collapsed category had
/// to force it open). A content column gets that behavior for free from stock split-view
/// navigation.
struct ContentView: View {
  // `SortCoordinator.shared`, not local `@State` — App Intents (`RunSortIntent`/
  // `RunAutomationIntent`) need to drive this same selection from outside the view tree, exactly
  // the way Showcase mode (below) already drives it through a manual-tap-equivalent path.
  @Bindable private var coordinator = SortCoordinator.shared
  @Environment(AppSettings.self) private var settings
  // Search text is deliberately not persisted — it's a one-off filter for the current session,
  // not a setting.
  @State private var searchText = ""

  // Showcase mode: `nil` means idle. Running drives `selection` through every registered
  // algorithm in turn via the exact same sidebar-navigation path a manual tap would — see
  // `ScrollingSortView`'s `showcaseCompletion` — rather than a separate `SortSession` bypassing
  // what's actually on screen (the bug this replaced).
  @State private var showcaseIndex: Int?
  @State private var showcaseAlgorithmIDs: [AlgorithmID] = []
  @State private var isShowingShowcaseConfirmation = false
  // Carries `showcaseSignposter`'s begin-interval token from `startShowcase()` across to whichever
  // of `advanceShowcase()`/`stopShowcase()` ends up closing it — `OSSignposter.endInterval`
  // requires the exact token `beginInterval` returned, not just a matching name/id.
  @State private var showcaseSignpostState: OSSignpostIntervalState?

  // Import Tape: `isImportingTape` drives the picker sheet itself; `importErrorMessage` is
  // shown live (not logged silently) since this is a manual, interactive action, not automation
  // — matching this app's existing "automation fails silently + self-logs, interactive flows
  // show the error live" split.
  @State private var isImportingTape = false
  @State private var importErrorMessage: String?

  /// The sidebar's own selection. `.all` is synthetic — `AlgorithmCategory` alone has no way to
  /// say "show every algorithm regardless of category," which the content column needs as its
  /// default so cross-category search (today's behavior, and still expected) isn't lost just
  /// because algorithms are now grouped behind a category pick.
  private enum SidebarCategory: Hashable, Identifiable {
    case all
    case category(AlgorithmCategory)
    var id: Self { self }
  }

  @State private var selectedSidebarCategory: SidebarCategory? = .all

  var body: some View {
    NavigationSplitView {
      categorySidebar
    } content: {
      algorithmContent
    } detail: {
      detailContent
    }
    // Lives on the whole split view, not a specific column — it's just `@State` plus a
    // modifier, so it doesn't need to share a column with whatever button triggers it.
    .confirmationDialog(
      "Start Showcase?", isPresented: $isShowingShowcaseConfirmation, titleVisibility: .visible
    ) {
      Button("Start Showcase") { startShowcase() }
        .accessibilityIdentifier("showcaseConfirmButton")
    } message: {
      Text(
        """
        Runs every algorithm once, in order, with the current visualizer. The visualizer \
        can still be changed with ⌘⇧V, but other controls are locked until it finishes.
        """)
    }
    .sheet(isPresented: $coordinator.isSettingsRequested) {
      NavigationStack {
        SettingsView()
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button {
                coordinator.isSettingsRequested = false
              } label: {
                Text("Done").fixedSize(horizontal: true, vertical: false)
              }
              .frame(width: 48)
              .flexibleButtonSizingIfAvailable()
            }
          }
      }
    }
    // Keeps the content column showing the right category when `selectedAlgorithmID` changes
    // from outside a manual category-then-algorithm tap (Showcase mode, `RunSortIntent`) — the
    // same class of case a manual tap already handles for free just by being inside whichever
    // category is currently selected.
    .onChange(of: coordinator.selectedAlgorithmID) { _, newValue in
      syncSidebarCategory(for: newValue)
    }
  }

  private var categorySidebar: some View {
    List(selection: $selectedSidebarCategory) {
      NavigationLink(value: SidebarCategory.all) {
        Label("All Algorithms", systemImage: "square.grid.2x2")
      }
      .accessibilityIdentifier("sidebarCategory.all")

      Section("Categories") {
        ForEach(AlgorithmCategory.allCases) { category in
          NavigationLink(value: SidebarCategory.category(category)) {
            Label(category.displayName, systemImage: "folder")
          }
          .accessibilityIdentifier("sidebarCategory.\(category.rawValue)")
        }
      }
    }
    .navigationTitle("Sort Symphony v2")
    // Blocks manual category switching while Showcase drives `selection` itself — otherwise a
    // stray tap here would race the automated advance below.
    .disabled(showcaseIndex != nil)
  }

  private var algorithmContent: some View {
    List(selection: $coordinator.selectedAlgorithmID) {
      ForEach(contentAlgorithms, id: \.id) { algorithm in
        NavigationLink(value: algorithm.id) {
          CustomIconLabel(
            text: algorithm.metadata.displayName,
            iconName: algorithm.metadata.iconName)
        }
        .accessibilityIdentifier("algorithmLink.\(algorithm.id.rawValue)")
        .contextMenu {
          Button("Run Size Sweep") {
            Task {
              await SortCoordinator.shared.runAutomation(
                algorithm: algorithm, automationID: .sizeSweep)
            }
          }
          Button("Run Max Size Only") {
            Task {
              await SortCoordinator.shared.runAutomation(
                algorithm: algorithm, automationID: .maxSizeOnly)
            }
          }
        }
      }
    }
    // Lets UI tests target this specific list once there are two on screen (the category
    // sidebar is the other) — see `App/UITests/SidebarNavigation.swift`.
    .accessibilityIdentifier("algorithmContentList")
    .searchable(text: $searchText, prompt: "Search Algorithms")
    .disabled(showcaseIndex != nil)
    .navigationTitle(contentTitle)
  }

  private var contentTitle: String {
    switch selectedSidebarCategory {
    case .none, .some(.all): "All Algorithms"
    case .some(.category(let category)): category.displayName
    }
  }

  private var contentAlgorithms: [any SortAlgorithm] {
    let base: [any SortAlgorithm]
    switch selectedSidebarCategory {
    case .none, .some(.all):
      // Same order Showcase mode itself uses — alphabetical, not registration order.
      base = AlgorithmRegistry.shared.algorithms.sorted {
        $0.metadata.displayName < $1.metadata.displayName
      }
    case .some(.category(let category)):
      base = AlgorithmRegistry.shared.algorithms(in: category)
    }
    guard !searchText.isEmpty else { return base }
    return base.filter { $0.metadata.displayName.localizedCaseInsensitiveContains(searchText) }
  }

  /// Moves the sidebar to whichever category actually contains `algorithmID`, but only when it
  /// isn't already showing it — `.all` always contains it, and re-assigning the same
  /// `.category(_)` back to itself would be a harmless but pointless extra write.
  private func syncSidebarCategory(for algorithmID: AlgorithmID?) {
    guard let algorithmID, let algorithm = AlgorithmRegistry.shared.algorithm(id: algorithmID)
    else { return }
    switch selectedSidebarCategory {
    case .none, .some(.all):
      return
    case .some(.category(let current)) where current == algorithm.metadata.category:
      return
    default:
      selectedSidebarCategory = .category(algorithm.metadata.category)
    }
  }

  // Split out of `body` (along with `detailContent` below) — inlined, these pushed the
  // surrounding `ViewBuilder` expression complex enough that the type checker started timing
  // out and misattributing the resulting error to an unrelated, unchanged line.
  private var showcaseToolbarButton: some View {
    Button {
      if showcaseIndex == nil {
        isShowingShowcaseConfirmation = true
      } else {
        stopShowcase()
      }
    } label: {
      Image(systemName: showcaseIndex == nil ? "sparkles.tv.fill" : "stop.fill")
    }
    .buttonBorderShape(.circle)
    .frame(width: 36, height: 24)
    .accessibilityIdentifier("showcaseButton")
  }

  private var settingsToolbarButton: some View {
    Button {
      coordinator.isSettingsRequested = true
    } label: {
      Image(systemName: "gearshape")
    }
    .buttonBorderShape(.circle)
    .frame(width: 36, height: 24)
    .accessibilityIdentifier("settingsButton")
  }

  private var importTapeToolbarButton: some View {
    Button {
      isImportingTape = true
    } label: {
      Image(systemName: "square.and.arrow.down")
    }
    .buttonBorderShape(.circle)
    .frame(width: 36, height: 24)
    .accessibilityIdentifier("importTapeButton")
    .help("Import a previously exported .tape file")
  }

  /// Reads `url` (a security-scoped URL from `.fileImporter`) and hands its bytes to
  /// `SortCoordinator.importTape(from:)`, which owns everything `Tape`-shaped (decoding,
  /// resolving `algorithmID` against `AlgorithmRegistry`, routing through the same
  /// "select via the same path a manual tap would use" mechanism `RunSortIntent`/Showcase mode
  /// already establish). Every failure surfaces via `importErrorMessage` — this is a manual,
  /// interactive action, so it gets a live error, not a silent skip.
  private func importTape(from url: URL) {
    let didAccess = url.startAccessingSecurityScopedResource()
    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try Data(contentsOf: url)
      switch coordinator.importTape(from: data) {
      case .success:
        break
      case .unrecognizedAlgorithm(let algorithmID):
        importErrorMessage =
          "This tape was recorded with an algorithm (\"\(algorithmID)\") this build doesn't recognize."
      case .decodeFailed(let reason):
        importErrorMessage = "Couldn't import this tape: \(reason)"
      }
    } catch {
      importErrorMessage = "Couldn't read this file: \(error.localizedDescription)"
    }
  }

  private var showcaseCompletionHandler: (() -> Void)? {
    guard showcaseIndex != nil else { return nil }
    return advanceShowcase
  }

  /// Distinct from `showcaseCompletionHandler`: that fires when the current algorithm's pass
  /// finishes on its own; this fires when the user stops early via `SortView`'s automation banner
  /// Stop button. That button calls this rather than `session.stopAutomation()`, which would be a
  /// no-op here since Showcase never goes through `SortSession.automationTask` (see
  /// `runShowcasePass()`).
  private var showcaseStopHandler: (() -> Void)? {
    guard showcaseIndex != nil else { return nil }
    return stopShowcase
  }

  private var detailContent: some View {
    Group {
      if let selection = coordinator.selectedAlgorithmID,
        let algorithm = AlgorithmRegistry.shared.algorithm(id: selection) {
        ScrollingSortView(
          algorithm: algorithm, shuffle: effectiveShuffle(for: selection), arraySize: arraySize,
          showcaseCompletion: showcaseCompletionHandler, showcaseStop: showcaseStopHandler
        )
        // Folds in `coordinator.runToken` (bumped on every intent-triggered run, and by
        // `selectAlgorithmForFreshView` — see `startShowcase`/`advanceShowcase`) alongside
        // `selection` — a `RunSortIntent`/`RunAutomationIntent`/Showcase step re-running or
        // landing on the *same* algorithm still needs a genuinely fresh `ScrollingSortView`/
        // `SortSession`, not a silent no-op against one that already reached `.complete`.
        .id("\(selection.rawValue)-\(coordinator.runToken)")
      } else {
        HomeView()
      }
    }
    .safeAreaInset(edge: .top) {
      if showcaseIndex != nil {
        showcaseBanner
      }
    }
    // On the detail column, not the sidebar: the sidebar is narrow enough that two icon
    // buttons plus its title collapse into an automatic overflow ("…") menu instead of
    // showing directly — confirmed visually. Detail is the widest column and always has room
    // at its trailing edge, which is also where these visually landed before this app had a
    // NavigationSplitView at all.
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        importTapeToolbarButton
      }
      ToolbarItem(placement: .topBarTrailing) {
        showcaseToolbarButton
      }
      ToolbarItem(placement: .topBarTrailing) {
        settingsToolbarButton
      }
    }
    .fileImporter(isPresented: $isImportingTape, allowedContentTypes: [.tapeArchive]) { result in
      switch result {
      case .success(let url): importTape(from: url)
      case .failure(let error): importErrorMessage = error.localizedDescription
      }
    }
    .alert(
      "Import Failed", isPresented: Binding(
        get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })
    ) {
      Button("OK") {}
    } message: {
      Text(importErrorMessage ?? "")
    }
  }

  private var showcaseBanner: some View {
    HStack(spacing: 8) {
      ProgressView()
        .controlSize(.small)
      Text(showcaseProgressText)
        .font(.caption)
        .accessibilityIdentifier("showcaseProgressLabel")
      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 6)
    .background(.bar)
  }

  private var showcaseProgressText: String {
    guard let showcaseIndex,
      let algorithm = AlgorithmRegistry.shared.algorithm(id: showcaseAlgorithmIDs[showcaseIndex])
    else {
      return "Showcase"
    }
    return
      "Showcase: \(algorithm.metadata.displayName) (\(showcaseIndex + 1)/\(showcaseAlgorithmIDs.count))"
  }

  /// Same order the content column itself uses (`AlgorithmRegistry.shared.algorithms` sorted by
  /// `displayName` too) — alphabetical, not registration order.
  private func startShowcase() {
    showcaseAlgorithmIDs = AlgorithmRegistry.shared.algorithms
      .sorted { $0.metadata.displayName < $1.metadata.displayName }
      .map(\.id)
    guard !showcaseAlgorithmIDs.isEmpty else { return }
    showcaseIndex = 0
    showcaseSignpostState = showcaseSignposter.beginInterval(
      "ShowcaseRun", "\(showcaseAlgorithmIDs.count) algorithms")
    // One step per algorithm, not fixed for the whole run — `advanceShowcase()` below repeats
    // this same pair of calls for every algorithm after the first, so a full Showcase pass
    // exercises every shuffle and every visualizer at least once (far more algorithms than either
    // list is long). `effectiveShuffle(for:)`/the renderer's own reactive read of
    // `selectedVisualizerID` pick this up automatically once `selectAlgorithmForFreshView` below
    // tears down and rebuilds the session.
    AppSettings.shared.cycleShuffle()
    AppSettings.shared.cycleVisualizer()
    coordinator.selectAlgorithmForFreshView(showcaseAlgorithmIDs[0])
  }

  /// `ScrollingSortView`'s `showcaseCompletion` callback — called once its current algorithm's
  /// `runShowcasePass()` genuinely finishes. Moves `coordinator.selectedAlgorithmID` to the next
  /// algorithm, which (via `detailContent`'s `.id(...)` above) tears down the finished view and
  /// starts the next one fresh; past the last algorithm, ends the same way `stopShowcase()` does.
  private func advanceShowcase() {
    guard let showcaseIndex else { return }
    let nextIndex = showcaseIndex + 1
    guard nextIndex < showcaseAlgorithmIDs.count else {
      stopShowcase()
      return
    }
    self.showcaseIndex = nextIndex
    AppSettings.shared.cycleShuffle()
    AppSettings.shared.cycleVisualizer()
    coordinator.selectAlgorithmForFreshView(showcaseAlgorithmIDs[nextIndex])
  }

  /// Also the target of a mid-run Stop tap. Clearing the selection (not leaving it on the
  /// last-shown algorithm) is deliberate: it's what actually changes `detailContent`'s `.id(...)`,
  /// which is what tears the view down and cancels its in-flight `runShowcasePass()` — SwiftUI's
  /// `.task` only restarts on identity change, not on a plain property change, so anything short
  /// of this risks a pass that keeps running invisibly after Stop is tapped.
  private func stopShowcase() {
    if let showcaseSignpostState {
      // `showcaseIndex` is still whatever was on screen when this was called — the last valid
      // index (a natural, ran-every-algorithm finish via `advanceShowcase()`) or wherever a
      // mid-run Stop tap landed — so `+ 1` reads as "how far in" either way, not a claim that
      // that specific algorithm's pass itself finished.
      let reached = (showcaseIndex ?? -1) + 1
      showcaseSignposter.endInterval(
        "ShowcaseRun", showcaseSignpostState, "reached \(reached)/\(showcaseAlgorithmIDs.count)")
      self.showcaseSignpostState = nil
    }
    showcaseIndex = nil
    coordinator.selectedAlgorithmID = nil
  }

  /// UI tests override this via the `UI_TEST_ARRAY_SIZE` launch environment variable (read in
  /// `Sort2App.init()`) — `AppSettings.defaultArraySize`'s real default (256) is deliberately
  /// large, and a quadratic/factorial algorithm at that size can take minutes to visually
  /// finish, which is correct, pedagogically-honest behavior in the running app but impractical
  /// for a UI test's timeout. Production launches never set that variable, so this is a no-op
  /// outside of tests.
  private var arraySize: Int {
    AppSettings.shared.defaultArraySize
  }

  /// `AlgorithmRegistry`/`ShuffleRegistry` are populated synchronously in `Sort2App.init()`,
  /// before this view can appear — a missing lookup means bundled resources are broken, so this
  /// fails loudly rather than falling back silently.
  ///
  /// Checks `coordinator.pendingShuffleOverride(for:)` first, for a `RunSortIntent` requesting a
  /// specific shuffle for this run. `shuffle` is a one-shot constructor argument fixed for the
  /// session's lifetime, so it must be resolved here before construction, not inside
  /// `ScrollingSortView.task` like the rest of a pending intent action.
  private func effectiveShuffle(for algorithmID: AlgorithmID) -> any ShuffleAlgorithm {
    let shuffleID =
      coordinator.pendingShuffleOverride(for: algorithmID) ?? AppSettings.shared.defaultShuffleID
    guard let shuffle = ShuffleRegistry.shared.shuffle(id: shuffleID) else {
      fatalError("Shuffles/\(shuffleID.rawValue).js failed to load")
    }
    return shuffle
  }
}

extension View {
  /// `.buttonSizing(.flexible)` is iOS 26+ only — the deployment target is iOS 18 (building
  /// against the iOS 26 SDK, see `Module.deploymentTargets`), so anything older than 26 just
  /// keeps the `.frame(width: 48)` this is paired with and skips this modifier entirely.
  @ViewBuilder
  fileprivate func flexibleButtonSizingIfAvailable() -> some View {
    if #available(iOS 26.0, *) {
      buttonSizing(.flexible)
    } else {
      self
    }
  }
}
