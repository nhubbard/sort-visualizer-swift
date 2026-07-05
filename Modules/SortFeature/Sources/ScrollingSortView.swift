import AlgorithmKit
import SwiftUI

public struct ScrollingSortView: View {
    let algorithm: any SortAlgorithm
    let arraySize: Int
    @State private var session: SortSession

    @MainActor
    public init(algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, arraySize: Int = 48) {
        self.algorithm = algorithm
        self.arraySize = arraySize
        _session = State(wrappedValue: SortSession(algorithm: algorithm, shuffle: shuffle))
    }

    public var body: some View {
        SortView(session: session)
            .navigationTitle(algorithm.metadata.displayName)
            .task {
                let size = min(max(arraySize, algorithm.metadata.sizeRange.lowerBound), algorithm.metadata.sizeRange.upperBound)
                await session.start(size: size)
            }
    }
}
