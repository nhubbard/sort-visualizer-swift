import AlgorithmKit
import BuiltInAlgorithms
import SettingsFeature
import SortFeature
import SwiftUI

// Placeholder — replaced with the real, AlgorithmRegistry-driven navigation in Phase 9. The debug
// link below is Phase 4's explicit "wire exactly one entry point" checkpoint: it proves
// record -> replay -> draw end-to-end in the actual running app, not a scratch preview.
struct ContentView: View {
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Debug: Quick Sort") {
                    ScrollingSortView(algorithm: QuickSort(), shuffle: debugShuffle, arraySize: 24)
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
                        // A sheet, not a navigation push — pushing to Settings and back would tear
                        // down and recreate ScrollingSortView's @State session, losing whatever the
                        // sort was in the middle of doing. This is Phase 5's actual checkpoint:
                        // switching visualizers mid-sort without disturbing SortSession/ReplayEngine.
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
                .accessibilityIdentifier("debugQuickSortLink")
            }
            .navigationTitle("Sort Symphony v2")
        }
    }

    /// `ShuffleRegistry` is populated synchronously in `Sort2App.init()`, before this view can ever
    /// appear — a missing "random" shuffle here means the bundled `Shuffles/` resources are broken,
    /// which should fail loudly in development rather than silently falling back to something else.
    private var debugShuffle: any ShuffleAlgorithm {
        guard let shuffle = ShuffleRegistry.shared.shuffle(id: ShuffleID(rawValue: "random")) else {
            fatalError("Shuffles/random.js failed to load — check App/Resources/Shuffles bundling")
        }
        return shuffle
    }
}
