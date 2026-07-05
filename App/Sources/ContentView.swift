import AlgorithmKit
import SettingsFeature
import SortFeature
import SwiftUI

// Placeholder — replaced with the real, AlgorithmRegistry-driven navigation in Phase 9. The debug
// links below are Phase 4's explicit "wire exactly one entry point" checkpoint, extended in this
// Phase 7 batch with a second link so a newly-ported algorithm gets the same live, in-app proof
// quicksort got — not just a unit test.
struct ContentView: View {
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                // NavigationLink(_:destination:)'s closure-based initializer builds its
                // destination *eagerly*, as soon as the List renders — not lazily on tap. With two
                // links that would construct both ScrollingSortViews (and hit debugAlgorithm's
                // fatalError for anything not yet bundled) at launch. NavigationLink(_:value:) +
                // .navigationDestination(for:) defers construction until actually navigated to.
                NavigationLink("Debug: Quick Sort", value: "quicksort")
                    .accessibilityIdentifier("debugQuickSortLink")
                NavigationLink("Debug: Gnome Sort", value: "gnomesort")
                    .accessibilityIdentifier("debugGnomeSortLink")
            }
            .navigationDestination(for: String.self) { algorithmID in
                debugDestination(algorithmID: algorithmID)
            }
            .navigationTitle("Sort Symphony v2")
        }
    }

    @ViewBuilder
    private func debugDestination(algorithmID: String) -> some View {
        ScrollingSortView(algorithm: debugAlgorithm(id: algorithmID), shuffle: debugShuffle, arraySize: 24)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            // A sheet, not a navigation push — pushing to Settings and back would tear down and
            // recreate ScrollingSortView's @State session, losing whatever the sort was in the
            // middle of doing. This is Phase 5's actual checkpoint: switching visualizers mid-sort
            // without disturbing SortSession/ReplayEngine.
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { isShowingSettings = false }
                            }
                        }
                }
            }
    }

    /// `AlgorithmRegistry`/`ShuffleRegistry` are populated synchronously in `Sort2App.init()`,
    /// before this view can ever appear — a missing lookup here means the bundled resources are
    /// broken, which should fail loudly in development rather than silently falling back.
    private func debugAlgorithm(id: String) -> any SortAlgorithm {
        guard let algorithm = AlgorithmRegistry.shared.algorithm(id: AlgorithmID(rawValue: id)) else {
            fatalError("Algorithms/\(id).js failed to load — check App/Resources/Algorithms bundling")
        }
        return algorithm
    }

    private var debugShuffle: any ShuffleAlgorithm {
        guard let shuffle = ShuffleRegistry.shared.shuffle(id: ShuffleID(rawValue: "random")) else {
            fatalError("Shuffles/random.js failed to load — check App/Resources/Shuffles bundling")
        }
        return shuffle
    }
}
