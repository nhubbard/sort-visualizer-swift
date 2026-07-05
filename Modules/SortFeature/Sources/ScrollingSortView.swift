import AlgorithmKit
import SwiftUI

public struct ScrollingSortView: View {
    let algorithm: any SortAlgorithm
    let arraySize: Int
    @State private var session: SortSession

    @MainActor
    public init(algorithm: any SortAlgorithm, arraySize: Int = 48) {
        self.algorithm = algorithm
        self.arraySize = arraySize
        _session = State(wrappedValue: SortSession(algorithm: algorithm))
    }

    public var body: some View {
        SortView(session: session)
            .navigationTitle(algorithm.metadata.displayName)
            .task {
                let size = min(max(arraySize, algorithm.metadata.sizeRange.lowerBound), algorithm.metadata.sizeRange.upperBound)
                await session.start(values: Array(1...size).shuffled())
            }
    }
}
