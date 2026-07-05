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
        // NOT audio: AudioService.shared here — constructing a live AudioKit graph crashes in
        // this project's current toolchain/simulator combination at native AudioComponent
        // registration ("Fatal error: node factory not initialized" inside AudioKitEX/
        // SoundpipeAudioKit), a crash Swift cannot catch or recover from (it's a C++ assert ->
        // SIGABRT). AudioService.swift is fully implemented and unit-tested (its pure
        // frequency(forValue:in:noteRange:) math), but wiring it into the one screen every UI test
        // exercises is deferred until this is verified safe on a real device — see PORT_INVENTORY-
        // style tracking in this phase's commit message. SortSession's own default
        // (NoOpAudioService()) keeps this screen — and every test — safe in the meantime.
        _session = State(wrappedValue: SortSession(algorithm: algorithm, shuffle: shuffle))
    }

    public var body: some View {
        SortView(session: session)
            .navigationTitle(algorithm.metadata.displayName)
            .task {
                // SortSession.start(size:) clamps into algorithm.metadata.sizeRange itself, so
                // every caller gets that enforcement, not just this one.
                await session.start(size: arraySize)
            }
    }
}
