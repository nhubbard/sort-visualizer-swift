import AlgorithmKit
import DesignSystemKit
import HomeFeature
import SettingsFeature
import SettingsKit
import SortFeature
import SwiftUI

/// Phase 9's data-driven navigation (§4.4 of ARCHITECTURE_V2.md) — the sidebar is generated
/// directly from `AlgorithmRegistry.shared.algorithms(in:)`, sectioned by `AlgorithmCategory`.
/// Adding a new algorithm from here on is "drop a `.js` + manifest pair in `Algorithms/`," with
/// zero changes to this file — `Page.swift`'s five parallel hand-maintained switches are gone.
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

    var body: some View {
        NavigationSplitView {
            List(selection: $coordinator.selectedAlgorithmID) {
                ForEach(AlgorithmCategory.allCases) { category in
                    let algorithms = filteredAlgorithms(in: category)
                    if !algorithms.isEmpty {
                        // A search match must stay visible even inside a category the user
                        // collapsed earlier — collapse only applies while not searching.
                        let isCollapsed = searchText.isEmpty && settings.collapsedCategoryIDs.contains(category)
                        Section {
                            if !isCollapsed {
                                ForEach(algorithms, id: \.id) { algorithm in
                                    NavigationLink(value: algorithm.id) {
                                        CustomIconLabel(
                                            text: algorithm.metadata.displayName,
                                            iconName: algorithm.metadata.iconName)
                                    }
                                    .accessibilityIdentifier("algorithmLink.\(algorithm.id.rawValue)")
                                    .contextMenu {
                                        Button("Run Size Sweep") {
                                            Task { await SortCoordinator.shared.runAutomation(algorithm: algorithm, automationID: .sizeSweep) }
                                        }
                                        Button("Run Max Size Only") {
                                            Task { await SortCoordinator.shared.runAutomation(algorithm: algorithm, automationID: .maxSizeOnly) }
                                        }
                                    }
                                }
                            }
                        } header: {
                            CategorySectionHeader(category: category, isCollapsed: isCollapsed) {
                                toggleCollapsed(category)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Algorithms")
            // Blocks manual navigation while Showcase drives `selection` itself — otherwise a
            // stray tap here would race the automated advance below.
            .disabled(showcaseIndex != nil)
            .navigationTitle("Sort Symphony v2")
            // Attached to the sidebar column specifically — a `.toolbar` on the NavigationSplitView
            // itself never actually renders a button in this SwiftUI version, so Settings needs a
            // home on whichever column has a real navigation bar. The sheet lives at this level too
            // (not per-detail-view) so it's reachable from Home as well as from a running sort.
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    showcaseToolbarButton
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        coordinator.isSettingsRequested = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .confirmationDialog(
                "Start Showcase?", isPresented: $isShowingShowcaseConfirmation, titleVisibility: .visible
            ) {
                Button("Start Showcase") { startShowcase() }
                    .accessibilityIdentifier("showcaseConfirmButton")
            } message: {
                Text("""
                Runs every algorithm once, in order, with the current visualizer. The visualizer \
                can still be changed with ⌘⇧V, but other controls are locked until it finishes.
                """)
            }
        } detail: {
            detailContent
        }
        .sheet(isPresented: $coordinator.isSettingsRequested) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { coordinator.isSettingsRequested = false }
                          label: {
                            Text("Done").fixedSize(horizontal: true, vertical: false)
                          }
                            .frame(width: 48)
                            .buttonSizing(.flexible)
                        }
                    }
            }
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
        .accessibilityIdentifier("showcaseButton")
    }

    private var showcaseCompletionHandler: (() -> Void)? {
        guard showcaseIndex != nil else { return nil }
        return advanceShowcase
    }

    /// Distinct from `showcaseCompletionHandler` above: that one fires when the current
    /// algorithm's pass finishes *on its own* (advance to the next one); this fires when the user
    /// asks to stop early, from the "Stop" button embedded in `SortView`'s automation banner —
    /// which `session.isAutomating` also shows during a Showcase pass (it's driven by the same
    /// `SortSession.runAutomation(sizes:runsPerSize:)` machinery under the hood), but whose button
    /// used to call `session.stopAutomation()`, a complete no-op here since Showcase never goes
    /// through `SortSession.automationTask` (see `runShowcasePass()`'s own doc comment).
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
                // Folds in `coordinator.runToken` (bumped on every intent-triggered run) alongside
                // `selection` — a `RunSortIntent`/`RunAutomationIntent` re-running the *same*
                // algorithm still needs a genuinely fresh `ScrollingSortView`/`SortSession`, not a
                // silent no-op against one that already reached `.complete`.
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
        return "Showcase: \(algorithm.metadata.displayName) (\(showcaseIndex + 1)/\(showcaseAlgorithmIDs.count))"
    }

    /// Same order the sidebar itself uses (`AlgorithmRegistry.shared.algorithms(in:)` sorts by
    /// `displayName` too) — alphabetical, not registration order.
    private func startShowcase() {
        showcaseAlgorithmIDs = AlgorithmRegistry.shared.algorithms
            .sorted { $0.metadata.displayName < $1.metadata.displayName }
            .map(\.id)
        guard !showcaseAlgorithmIDs.isEmpty else { return }
        showcaseIndex = 0
        coordinator.selectedAlgorithmID = showcaseAlgorithmIDs[0]
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
        coordinator.selectedAlgorithmID = showcaseAlgorithmIDs[nextIndex]
    }

    /// Also the target of a mid-run Stop tap. Clearing the selection (not leaving it on the
    /// last-shown algorithm) is deliberate: it's what actually changes `detailContent`'s `.id(...)`,
    /// which is what tears the view down and cancels its in-flight `runShowcasePass()` — SwiftUI's
    /// `.task` only restarts on identity change, not on a plain property change, so anything short
    /// of this risks a pass that keeps running invisibly after Stop is tapped.
    private func stopShowcase() {
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
    /// before this view can ever appear — a missing lookup here means the bundled resources are
    /// broken, which should fail loudly in development rather than silently falling back.
    ///
    /// Checks `coordinator.pendingShuffleOverride(for:)` first — a `RunSortIntent` requesting a
    /// specific shuffle for this one run. `shuffle` is a one-shot `SortSession`/`ScrollingSortView`
    /// constructor argument, fixed for that session's whole lifetime, so this has to be resolved
    /// here, before construction, rather than inside `ScrollingSortView.task` like the rest of a
    /// pending intent action.
    private func effectiveShuffle(for algorithmID: AlgorithmID) -> any ShuffleAlgorithm {
        let shuffleID = coordinator.pendingShuffleOverride(for: algorithmID) ?? AppSettings.shared.defaultShuffleID
        guard let shuffle = ShuffleRegistry.shared.shuffle(id: shuffleID) else {
            fatalError("Shuffles/\(shuffleID.rawValue).js failed to load")
        }
        return shuffle
    }

    private func toggleCollapsed(_ category: AlgorithmCategory) {
        withAnimation(.snappy) {
            if settings.collapsedCategoryIDs.contains(category) {
                settings.collapsedCategoryIDs.remove(category)
            } else {
                settings.collapsedCategoryIDs.insert(category)
            }
        }
    }

    private func filteredAlgorithms(in category: AlgorithmCategory) -> [any SortAlgorithm] {
        let algorithms = AlgorithmRegistry.shared.algorithms(in: category)
        guard !searchText.isEmpty else { return algorithms }
        return algorithms.filter { $0.metadata.displayName.localizedCaseInsensitiveContains(searchText) }
    }
}

/// A `Section` header for `ContentView`'s sidebar with an explicit collapse/expand button next to
/// the category name — rather than relying on `Section(isExpanded:)`'s built-in disclosure
/// triangle, which only actually renders as a collapsible control under `.listStyle(.sidebar)` and
/// ties the tap target to the whole header row. A dedicated `Button` works the same regardless of
/// list style and keeps the tap target scoped to the chevron itself.
private struct CategorySectionHeader: View {
    let category: AlgorithmCategory
    let isCollapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Text(category.displayName)
            Spacer()
            Button(action: onToggle) {
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                    .imageScale(.small)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("categoryToggle.\(category.rawValue)")
            .accessibilityLabel(
                isCollapsed ? "Expand \(category.displayName)" : "Collapse \(category.displayName)")
        }
    }
}
