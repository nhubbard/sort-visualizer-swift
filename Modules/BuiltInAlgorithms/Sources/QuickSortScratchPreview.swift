import SortEngineKit
import SwiftUI

/// Throwaway scaffolding for Phase 2's "does record-then-replay actually look like sorting"
/// checkpoint — plain `Rectangle()`s, not the real `Visualizer`/`VisualizationCanvas` (Phase 4).
/// Deleted alongside `QuickSort.swift` in Phase 3.
struct QuickSortScratchPreview: View {
    private let replay: ReplayEngine

    init(size: Int = 40) {
        let initialValues = Array(1...size).shuffled()
        var engine = RecordingEngine(values: initialValues)
        let algorithm = QuickSort()
        algorithm.record(into: &engine)
        let (operations, compareCount, swapCount, _) = engine.finish()
        let tape = Tape(
            header: TapeHeader(
                algorithmID: algorithm.id.rawValue,
                initialValues: initialValues,
                visualSeed: 0,
                compareCount: compareCount,
                swapCount: swapCount,
                recordingDuration: 0,
                recordedAt: Date()
            ),
            operations: operations
        )
        replay = ReplayEngine(tape: tape)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(replay.frame) { bar in
                Rectangle()
                    .fill(bar.isSorted ? Color.green : (bar.markers.isEmpty ? Color.gray : Color.orange))
                    .frame(width: 6, height: CGFloat(bar.value) * 4)
            }
        }
        .padding()
        .task { replay.play(operationsPerSecond: 60) }
    }
}

#Preview {
    QuickSortScratchPreview()
}
