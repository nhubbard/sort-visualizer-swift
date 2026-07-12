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
    @State private var selection: AlgorithmID?
    @State private var isShowingSettings = false
    // Session-only (not AppSettings-backed): every category starts expanded on each launch, so
    // the existing `algorithmLink.<id>` UI tests (which tap straight into the sidebar with no
    // "expand first" step) keep working unmodified.
    @State private var collapsedCategories: Set<AlgorithmCategory> = []

    // Showcase mode: `nil` means idle. Running drives `selection` through every registered
    // algorithm in turn via the exact same sidebar-navigation path a manual tap would — see
    // `ScrollingSortView`'s `showcaseCompletion` — rather than a separate `SortSession` bypassing
    // what's actually on screen (the bug this replaced).
    @State private var showcaseIndex: Int?
    @State private var showcaseAlgorithmIDs: [AlgorithmID] = []
    @State private var isShowingShowcaseConfirmation = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(AlgorithmCategory.allCases) { category in
                    let algorithms = AlgorithmRegistry.shared.algorithms(in: category)
                    if !algorithms.isEmpty {
                        Section {
                            if !collapsedCategories.contains(category) {
                                ForEach(algorithms, id: \.id) { algorithm in
                                    NavigationLink(value: algorithm.id) {
                                        CustomIconLabel(
                                            text: algorithm.metadata.displayName,
                                            iconName: algorithm.metadata.iconName)
                                    }
                                    .accessibilityIdentifier("algorithmLink.\(algorithm.id.rawValue)")
                                }
                            }
                        } header: {
                            CategorySectionHeader(
                                category: category,
                                isCollapsed: collapsedCategories.contains(category)
                            ) {
                                toggleCollapsed(category)
                            }
                        }
                    }
                }
            }
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
                        isShowingSettings = true
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
            .background {
                // Zero-size, fully transparent — same invisible-button-in-`.background` pattern
                // `SortFeature`'s own shortcuts use. Lives here (not scoped to a running sort)
                // since Settings should be reachable from anywhere in the app.
                Button("") { isShowingSettings = true }
                    .keyboardShortcut(",", modifiers: [.command])
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        } detail: {
            detailContent
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { isShowingSettings = false }
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

    private var detailContent: some View {
        Group {
            if let selection, let algorithm = AlgorithmRegistry.shared.algorithm(id: selection) {
                ScrollingSortView(
                    algorithm: algorithm, shuffle: defaultShuffle, arraySize: arraySize,
                    showcaseCompletion: showcaseCompletionHandler
                )
                .id(selection)
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
        selection = showcaseAlgorithmIDs[0]
    }

    /// `ScrollingSortView`'s `showcaseCompletion` callback — called once its current algorithm's
    /// `runShowcasePass()` genuinely finishes. Moves `selection` to the next algorithm, which (via
    /// `.id(selection)` above) tears down the finished view and starts the next one fresh; past the
    /// last algorithm, ends the same way `stopShowcase()` does.
    private func advanceShowcase() {
        guard let showcaseIndex else { return }
        let nextIndex = showcaseIndex + 1
        guard nextIndex < showcaseAlgorithmIDs.count else {
            stopShowcase()
            return
        }
        self.showcaseIndex = nextIndex
        selection = showcaseAlgorithmIDs[nextIndex]
    }

    /// Also the target of a mid-run Stop tap. Clearing `selection` (not leaving it on the
    /// last-shown algorithm) is deliberate: it's what actually changes `ScrollingSortView`'s
    /// `.id(selection)`, which is what tears the view down and cancels its in-flight
    /// `runShowcasePass()` — SwiftUI's `.task` only restarts on identity change, not on a plain
    /// property change, so anything short of this risks a pass that keeps running invisibly after
    /// Stop is tapped.
    private func stopShowcase() {
        showcaseIndex = nil
        selection = nil
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
    private var defaultShuffle: any ShuffleAlgorithm {
        guard let shuffle = ShuffleRegistry.shared.shuffle(id: AppSettings.shared.defaultShuffleID) else {
            fatalError(
                "Shuffles/\(AppSettings.shared.defaultShuffleID.rawValue).js failed to load"
            )
        }
        return shuffle
    }

    private func toggleCollapsed(_ category: AlgorithmCategory) {
        withAnimation(.snappy) {
            if collapsedCategories.contains(category) {
                collapsedCategories.remove(category)
            } else {
                collapsedCategories.insert(category)
            }
        }
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
