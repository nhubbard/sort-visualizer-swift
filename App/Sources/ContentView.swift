import BuiltInAlgorithms
import SortFeature
import SwiftUI

// Placeholder — replaced with the real, AlgorithmRegistry-driven navigation in Phase 9. The debug
// link below is Phase 4's explicit "wire exactly one entry point" checkpoint: it proves
// record -> replay -> draw end-to-end in the actual running app, not a scratch preview.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Debug: Quick Sort") {
                    ScrollingSortView(algorithm: QuickSort(), arraySize: 24)
                }
                .accessibilityIdentifier("debugQuickSortLink")
            }
            .navigationTitle("Sort Symphony v2")
        }
    }
}
