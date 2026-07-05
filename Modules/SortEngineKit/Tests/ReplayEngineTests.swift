import Foundation
import Testing
@testable import SortEngineKit

@MainActor
@Suite
struct ReplayEngineTests {
    private func makeTape(initialValues: [Int], operations: [SortOperation]) -> Tape {
        Tape(
            header: TapeHeader(
                algorithmID: "test",
                initialValues: initialValues,
                visualSeed: 0,
                compareCount: 0,
                swapCount: 0,
                recordingDuration: 0,
                recordedAt: Date(timeIntervalSince1970: 0)
            ),
            operations: operations
        )
    }

    @Test
    func stepForwardAppliesOperationsInOrder() {
        let tape = makeTape(initialValues: [3, 1, 2], operations: [
            .mark(marker: Marker.primary, index: 0),
            .mark(marker: Marker.secondary, index: 1),
            .compare(0, 1),
            .swap(0, 1),
            .markSorted(0),
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(engine.frame.map(\.value) == [1, 3, 2])
        #expect(engine.frame[0].isSorted)
        #expect(engine.compareCount == 1)
        #expect(engine.stepIndex == tape.operations.count)
    }

    @Test
    func auxArraysCreateWriteAndDeleteAcrossReplay() {
        let tape = makeTape(initialValues: [1, 2], operations: [
            .auxCreate(handle: 0, length: 2),
            .auxWrite(handle: 0, index: 0, value: 9),
            .auxWrite(handle: 0, index: 1, value: 4),
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(engine.auxArrays[0] == [9, 4])

        let deleteTape = makeTape(initialValues: [1], operations: tape.operations + [.auxDelete(handle: 0)])
        let deleteEngine = ReplayEngine(tape: deleteTape)
        for _ in 0..<deleteTape.operations.count { deleteEngine.stepForward() }
        #expect(deleteEngine.auxArrays[0] == nil)
    }

    @Test
    func seekToNonCheckpointIndexThenContinueMatchesUninterruptedStepping() {
        // 1,200 operations spans more than two ~500-op checkpoint boundaries.
        let operations: [SortOperation] = (0..<1200).map { i in
            i.isMultiple(of: 2) ? .compare(0, 1) : .swap(0, 1)
        }
        let tape = makeTape(initialValues: [1, 2], operations: operations)

        let reference = ReplayEngine(tape: tape)
        for _ in 0..<900 { reference.stepForward() }

        let seeking = ReplayEngine(tape: tape)
        seeking.seek(to: 733) // deliberately not a checkpoint boundary
        for _ in 733..<900 { seeking.stepForward() }

        #expect(seeking.frame.map(\.value) == reference.frame.map(\.value))
        #expect(seeking.compareCount == reference.compareCount)
        #expect(seeking.stepIndex == reference.stepIndex)
    }

    @Test
    func stepBackwardMatchesReDerivingFromScratch() {
        let operations: [SortOperation] = [
            .compare(0, 1), .swap(0, 1),
            .compare(1, 2), .swap(1, 2),
            .markSorted(2),
        ]
        let tape = makeTape(initialValues: [3, 1, 2], operations: operations)

        let engine = ReplayEngine(tape: tape)
        for _ in 0..<4 { engine.stepForward() }
        engine.stepBackward()

        let fresh = ReplayEngine(tape: tape)
        for _ in 0..<3 { fresh.stepForward() }

        #expect(engine.frame.map(\.value) == fresh.frame.map(\.value))
        #expect(engine.frame.map(\.isSorted) == fresh.frame.map(\.isSorted))
        #expect(engine.stepIndex == fresh.stepIndex)
    }

    @Test
    func unmarkClearsMarkerFromEveryIndexNotJustOne() {
        let tape = makeTape(initialValues: [1, 2, 3], operations: [
            .mark(marker: Marker.pivot, index: 0),
            .mark(marker: Marker.pivot, index: 2),
            .unmark(marker: Marker.pivot),
        ])
        let engine = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { engine.stepForward() }

        #expect(engine.frame.allSatisfy { !$0.markers.contains(Marker.pivot) })
    }
}
