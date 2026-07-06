import AlgorithmKit
import SwiftUI

public struct BenchmarkView: View {
    @State private var selectedAlgorithmID: AlgorithmID?

    public init() {}

    // NOT wrapped in its own NavigationStack — matches SettingsView's pattern of leaving that to
    // the caller (ContentView's .sheet already wraps this in one), since a .toolbar attached
    // outside a view's own internal NavigationStack doesn't render (learned the hard way wiring
    // ContentView's own toolbar in Phase 9).
    public var body: some View {
        Form {
            Section("Algorithm") {
                Picker("Algorithm", selection: $selectedAlgorithmID) {
                    Text("Select an algorithm").tag(AlgorithmID?.none)
                    ForEach(sortedAlgorithms, id: \.id) { algorithm in
                        Text(algorithm.metadata.displayName).tag(Optional(algorithm.id))
                    }
                }
                .accessibilityIdentifier("benchmarkAlgorithmPicker")
            }

            if let algorithm = selectedAlgorithm {
                Section("Complexity") {
                    ComplexityChart(algorithm: algorithm)
                }
                Section("Across Your Devices") {
                    DeviceComparisonView(algorithm: algorithm)
                }
            }
        }
        .navigationTitle("Benchmark")
    }

    private var sortedAlgorithms: [any SortAlgorithm] {
        AlgorithmRegistry.shared.algorithms.sorted { $0.metadata.displayName < $1.metadata.displayName }
    }

    private var selectedAlgorithm: (any SortAlgorithm)? {
        selectedAlgorithmID.flatMap(AlgorithmRegistry.shared.algorithm(id:))
    }
}
