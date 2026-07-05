import Foundation
import Testing
@testable import BuiltInAlgorithms
import SortEngineKit

@Suite
struct QuickSortTests {
    @Test(arguments: [1, 2, 10, 200])
    func sortsRandomInputCorrectly(size: Int) {
        let input = (0..<size).map { _ in Int.random(in: 0...1000) }
        var engine = RecordingEngine(values: input)
        QuickSort().record(into: &engine)
        #expect(engine.values == input.sorted())
    }

    @Test
    func handlesEmptyInput() {
        var engine = RecordingEngine(values: [])
        QuickSort().record(into: &engine)
        #expect(engine.values.isEmpty)
    }

    @Test
    func handlesAlreadySortedInput() {
        let input = Array(0..<100)
        var engine = RecordingEngine(values: input)
        QuickSort().record(into: &engine)
        #expect(engine.values == input)
    }

    @Test
    func handlesReverseSortedInput() {
        let input = Array((0..<100).reversed())
        var engine = RecordingEngine(values: input)
        QuickSort().record(into: &engine)
        #expect(engine.values == input.sorted())
    }

    @Test
    func handlesManyDuplicateValues() {
        let input = (0..<100).map { _ in Int.random(in: 0...3) }
        var engine = RecordingEngine(values: input)
        QuickSort().record(into: &engine)
        #expect(engine.values == input.sorted())
    }

    @MainActor
    @Test
    func recordedTapeReplaysToSortedFrame() {
        let input = [5, 3, 8, 1, 9, 2, 7, 4, 6]
        var engine = RecordingEngine(values: input)
        let algorithm = QuickSort()
        algorithm.record(into: &engine)
        let (operations, compareCount, swapCount, _) = engine.finish()
        let tape = Tape(
            header: TapeHeader(
                algorithmID: algorithm.id.rawValue,
                initialValues: input,
                visualSeed: 0,
                compareCount: compareCount,
                swapCount: swapCount,
                recordingDuration: 0,
                recordedAt: Date(timeIntervalSince1970: 0)
            ),
            operations: operations
        )

        let replay = ReplayEngine(tape: tape)
        for _ in 0..<operations.count { replay.stepForward() }

        #expect(replay.frame.map(\.value) == input.sorted())
    }
}
