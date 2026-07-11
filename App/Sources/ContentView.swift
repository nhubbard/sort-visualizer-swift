import AlgorithmKit
import BenchmarkFeature
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
    @State private var isShowingBenchmark = false
    // Session-only (not AppSettings-backed): every category starts expanded on each launch, so
    // the existing `algorithmLink.<id>` UI tests (which tap straight into the sidebar with no
    // "expand first" step) keep working unmodified.
    @State private var collapsedCategories: Set<AlgorithmCategory> = []

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
            .navigationTitle("Sort Symphony v2")
            // Attached to the sidebar column specifically — a `.toolbar` on the NavigationSplitView
            // itself never actually renders a button in this SwiftUI version, so Settings needs a
            // home on whichever column has a real navigation bar. The sheet lives at this level too
            // (not per-detail-view) so it's reachable from Home as well as from a running sort.
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingBenchmark = true
                    } label: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                    .accessibilityIdentifier("benchmarkButton")
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
        } detail: {
            if let selection, let algorithm = AlgorithmRegistry.shared.algorithm(id: selection) {
                ScrollingSortView(algorithm: algorithm, shuffle: defaultShuffle, arraySize: arraySize)
                    .id(selection)
            } else {
                HomeView()
            }
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
        .sheet(isPresented: $isShowingBenchmark) {
            NavigationStack {
                BenchmarkView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                isShowingBenchmark = false
                            } label: {
                                Text("Done").fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(width: 48)
                            .buttonSizing(.flexible)
                        }
                    }
            }
        }
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
