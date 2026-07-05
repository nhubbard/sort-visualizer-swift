import Testing
@testable import SortEngineKit

@Suite
struct RecordingEngineTests {
    @Test
    func compareEmitsPrimarySecondaryMarksThenCompare() {
        var engine = RecordingEngine(values: [5, 3])
        _ = engine.compare(0, 1)

        let (tape, compareCount, swapCount, auxWriteCount) = engine.finish()
        #expect(tape == [
            .mark(marker: Marker.primary, index: 0),
            .mark(marker: Marker.secondary, index: 1),
            .compare(0, 1),
        ])
        #expect(compareCount == 1)
        #expect(swapCount == 0)
        #expect(auxWriteCount == 0)
    }

    @Test
    func swapEmitsMarksThenSwapAndMutatesValues() {
        var engine = RecordingEngine(values: [5, 3])
        engine.swap(0, 1)

        #expect(engine.values == [3, 5])
        let (tape, _, swapCount, _) = engine.finish()
        #expect(tape == [
            .mark(marker: Marker.primary, index: 0),
            .mark(marker: Marker.secondary, index: 1),
            .swap(0, 1),
        ])
        #expect(swapCount == 1)
    }

    @Test
    func auxArrayRoundTripsCreateWriteDelete() {
        var engine = RecordingEngine(values: [1, 2, 3])
        let handle = engine.createAuxArray(length: 2)
        engine.writeAux(handle, at: 0, value: 42)
        engine.writeAux(handle, at: 1, value: 7)
        engine.deleteAuxArray(handle)

        let (tape, _, _, auxWriteCount) = engine.finish()
        #expect(tape == [
            .auxCreate(handle: handle.rawValue, length: 2),
            .auxWrite(handle: handle.rawValue, index: 0, value: 42),
            .auxWrite(handle: handle.rawValue, index: 1, value: 7),
            .auxDelete(handle: handle.rawValue),
        ])
        #expect(auxWriteCount == 2)
    }

    @Test
    func finishCountsMatchHandComputedSequence() {
        var engine = RecordingEngine(values: [3, 1, 2])
        _ = engine.compare(0, 1)
        engine.swap(0, 1)
        _ = engine.compare(1, 2)
        engine.swap(1, 2)
        _ = engine.compare(0, 1)

        let (_, compareCount, swapCount, _) = engine.finish()
        #expect(compareCount == 3)
        #expect(swapCount == 2)
        #expect(engine.values == [1, 2, 3])
    }

    @Test
    func markUnmarkAndUnmarkAllRecordDirectly() {
        var engine = RecordingEngine(values: [1, 2])
        engine.mark(Marker.pivot, at: 0)
        engine.unmark(Marker.pivot)
        engine.unmarkAll()

        let (tape, _, _, _) = engine.finish()
        #expect(tape == [
            .mark(marker: Marker.pivot, index: 0),
            .unmark(marker: Marker.pivot),
            .unmarkAll,
        ])
    }
}
