import Testing

@testable import SortEngineKit

@Suite
struct RecordingEngineTests {
  @Test
  func compareEmitsPrimarySecondaryMarksThenCompare() {
    var engine = RecordingEngine(values: [5, 3])
    _ = engine.compare(0, 1)

    let summary = engine.finish()
    #expect(
      summary.tape == [
        .mark(marker: Marker.primary, index: 0),
        .mark(marker: Marker.secondary, index: 1),
        .compare(0, 1)
      ])
    #expect(summary.compareCount == 1)
    #expect(summary.swapCount == 0)
    #expect(summary.mainWriteCount == 0)
    #expect(summary.auxWriteCount == 0)
  }

  @Test
  func swapEmitsMarksThenSwapAndMutatesValues() {
    var engine = RecordingEngine(values: [5, 3])
    engine.swap(0, 1)

    #expect(engine.values == [3, 5])
    let summary = engine.finish()
    #expect(
      summary.tape == [
        .mark(marker: Marker.primary, index: 0),
        .mark(marker: Marker.secondary, index: 1),
        .swap(0, 1)
      ])
    #expect(summary.swapCount == 1)
    // A swap is two array writes (ArrayV's `Writes.updateSwap` convention), not one.
    #expect(summary.mainWriteCount == 2)
  }

  @Test
  func setValueIncrementsMainWriteCount() {
    var engine = RecordingEngine(values: [1, 2])
    engine.setValue(0, 9)
    engine.setValue(1, 8)

    #expect(engine.values == [9, 8])
    let summary = engine.finish()
    #expect(summary.mainWriteCount == 2)
    #expect(summary.swapCount == 0)
  }

  @Test
  func reversalPerformsSwapsAndCountsAsOneOperation() {
    var engine = RecordingEngine(values: [1, 2, 3, 4, 5])
    engine.reversal(0, 4)

    #expect(engine.values == [5, 4, 3, 2, 1])
    let summary = engine.finish()
    #expect(summary.reversalCount == 1)
    // Built from swap() internally — still contributes element-by-element to swapCount/
    // mainWriteCount, matching ArrayV's own reversal()-is-built-from-swap() convention.
    #expect(summary.swapCount == 2)
    #expect(summary.mainWriteCount == 4)
    #expect(summary.tape.first == .reversal)
  }

  @Test
  func reversalOfADegenerateRangePerformsNoSwapsButStillCounts() {
    var engine = RecordingEngine(values: [1, 2, 3])
    engine.reversal(0, 0)

    #expect(engine.values == [1, 2, 3])
    let summary = engine.finish()
    #expect(summary.reversalCount == 1)
    #expect(summary.swapCount == 0)
  }

  @Test
  func auxArrayRoundTripsCreateWriteDelete() {
    var engine = RecordingEngine(values: [1, 2, 3])
    let handle = engine.createAuxArray(length: 2)
    engine.writeAux(handle, at: 0, value: 42)
    engine.writeAux(handle, at: 1, value: 7)
    engine.deleteAuxArray(handle)

    let summary = engine.finish()
    #expect(
      summary.tape == [
        .auxCreate(handle: handle.rawValue, length: 2),
        .auxWrite(handle: handle.rawValue, index: 0, value: 42),
        .auxWrite(handle: handle.rawValue, index: 1, value: 7),
        .auxDelete(handle: handle.rawValue)
      ])
    #expect(summary.auxWriteCount == 2)
    #expect(summary.mainWriteCount == 0)
  }

  @Test
  func secondCompareRetractsThePreviousPairsMarksBeforeMarkingTheNewOne() {
    var engine = RecordingEngine(values: [5, 3, 8])
    _ = engine.compare(0, 1)
    _ = engine.compare(1, 2)

    let summary = engine.finish()
    #expect(
      summary.tape == [
        .mark(marker: Marker.primary, index: 0),
        .mark(marker: Marker.secondary, index: 1),
        .compare(0, 1),
        .unmarkIndex(marker: Marker.primary, index: 0),
        .unmarkIndex(marker: Marker.secondary, index: 1),
        .mark(marker: Marker.primary, index: 1),
        .mark(marker: Marker.secondary, index: 2),
        .compare(1, 2)
      ])
  }

  @Test
  func swapAfterCompareRetractsCompareSMarksToo() {
    var engine = RecordingEngine(values: [5, 3, 8])
    _ = engine.compare(0, 1)
    engine.swap(1, 2)

    let summary = engine.finish()
    #expect(
      summary.tape == [
        .mark(marker: Marker.primary, index: 0),
        .mark(marker: Marker.secondary, index: 1),
        .compare(0, 1),
        .unmarkIndex(marker: Marker.primary, index: 0),
        .unmarkIndex(marker: Marker.secondary, index: 1),
        .mark(marker: Marker.primary, index: 1),
        .mark(marker: Marker.secondary, index: 2),
        .swap(1, 2)
      ])
  }

  @Test
  func finishCountsMatchHandComputedSequence() {
    var engine = RecordingEngine(values: [3, 1, 2])
    _ = engine.compare(0, 1)
    engine.swap(0, 1)
    _ = engine.compare(1, 2)
    engine.swap(1, 2)
    _ = engine.compare(0, 1)

    let summary = engine.finish()
    #expect(summary.compareCount == 3)
    #expect(summary.swapCount == 2)
    #expect(summary.mainWriteCount == 4)
    #expect(engine.values == [1, 2, 3])
  }

  @Test
  func markUnmarkAndUnmarkAllRecordDirectly() {
    var engine = RecordingEngine(values: [1, 2])
    engine.mark(Marker.pivot, at: 0)
    engine.unmark(Marker.pivot)
    engine.unmarkAll()

    let summary = engine.finish()
    #expect(
      summary.tape == [
        .mark(marker: Marker.pivot, index: 0),
        .unmark(marker: Marker.pivot),
        .unmarkAll
      ])
  }

  @Test
  func operationCapFreezesTapeGrowthButRealWorkKeepsHappening() {
    // Each compare() emits 3 ops on the very first call (2 marks + the compare itself), so a
    // cap of 3 is hit exactly at the end of the first compare — the second compare's marks/
    // compare should all be swallowed, but `values`/`compareCount` must still reflect it.
    var engine = RecordingEngine(values: [5, 3, 8], operationCap: 3)
    _ = engine.compare(0, 1)
    #expect(!engine.didExceedCap)
    _ = engine.compare(1, 2)
    #expect(engine.didExceedCap)

    let summary = engine.finish()
    #expect(summary.didExceedCap)
    #expect(summary.tape.count == 3)
    #expect(
      summary.tape == [
        .mark(marker: Marker.primary, index: 0),
        .mark(marker: Marker.secondary, index: 1),
        .compare(0, 1)
      ])
    // Real work past the cap still happened — only the tape stopped growing.
    #expect(summary.compareCount == 2)
  }

  @Test
  func operationCapStillLetsTheAlgorithmFinishCorrectly() {
    var engine = RecordingEngine(values: [3, 1, 2], operationCap: 2)
    _ = engine.compare(0, 1)
    engine.swap(0, 1)
    _ = engine.compare(1, 2)
    engine.swap(1, 2)
    _ = engine.compare(0, 1)

    #expect(engine.didExceedCap)
    #expect(engine.values == [1, 2, 3])
    let summary = engine.finish()
    #expect(summary.compareCount == 3)
    #expect(summary.swapCount == 2)
    #expect(summary.tape.count == 2)
  }
}
