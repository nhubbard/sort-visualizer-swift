import AlgorithmKit
import BuiltInAlgorithms
import Foundation
import SortEngineKit
import Testing

@testable import SortFeature

@Suite
struct TeachingGraphTraceTests {
  @Test
  func quickSortShowsPivotDecisionsAndPlacementsAcrossTheCompleteRun() throws {
    let tape = makeTape(QuickSort(), values: [6, 3, 2, 5, 1, 4])
    let trace = try #require(TeachingGraphTrace(tape: tape))
    #expect(trace.variant == .quickSort)
    #expect(trace.events.contains { $0.kind == .decision })
    #expect(tape.teachingAnnotations.contains { $0.stageID == "quick.partition.scanLeft" })
    #expect(trace.events.contains { $0.explanation.contains("pivot's left side") })
    #expect(trace.events.contains { $0.kind == .pivotPlacement })
    #expect(trace.events.filter { $0.kind == .decision }.allSatisfy { $0.source != $0.target })
    #expect((trace.events.last?.step ?? 0) <= tape.operations.count)
    #expect(trace.events.allSatisfy { $0.step > tape.header.sortStartIndex })
    assertAllReplayPositions(trace, tape: tape)
  }

  @Test
  func mergeSortLinksEveryMainArrayWriteToTheTemporaryBuffer() throws {
    let tape = makeTape(MergeSort(), values: [6, 3, 2, 5, 1, 4])
    let trace = try #require(TeachingGraphTrace(tape: tape))
    let mainWrites = tape.operations.filter {
      if case .setValue = $0 { return true }
      return false
    }.count
    #expect(trace.variant == .mergeSort)
    #expect(trace.events.filter { $0.kind == .bufferWrite }.count == mainWrites)
    #expect(trace.events.filter { $0.kind == .mergeWrite }.count == mainWrites)
    #expect(trace.events.contains { $0.kind == .decision })
    #expect(tape.teachingAnnotations.contains { $0.stageID == "merge.chooseNext" })
    #expect(trace.events.contains { $0.explanation.contains("left run") })
    #expect(trace.events.filter { $0.kind == .mergeWrite }.allSatisfy {
      $0.source.location == .buffer && $0.target.location == .array
    })
    assertAllReplayPositions(trace, tape: tape)
  }

  @Test
  func fastPlaybackCompactionRemapsGraphPositionsWithoutDroppingMeaningfulEvents() throws {
    for tape in [
      makeTape(QuickSort(), values: [4, 1, 3, 2]),
      makeTape(MergeSort(), values: [4, 1, 3, 2]),
    ] {
      let original = try #require(TeachingGraphTrace(tape: tape))
      let compactedTape = tape.compactedForFastPlayback()
      let compacted = try #require(TeachingGraphTrace(tape: compactedTape))
      #expect(compactedTape.operations.count < tape.operations.count)
      #expect(compacted.events.map(\.kind) == original.events.map(\.kind))
      #expect(compacted.events.map(\.explanation) == original.events.map(\.explanation))
      #expect((compacted.events.last?.step ?? 0) <= compactedTape.operations.count)
      assertAllReplayPositions(compacted, tape: compactedTape)
    }
  }

  @Test
  func graphStartsAfterShuffleAndBoundsVisibleDensity() throws {
    let tape = makeTape(QuickSort(), values: Array((1...32).reversed()))
    let shuffled = Tape(
      header: TapeHeader(
        algorithmID: "quicksort", initialValues: tape.header.initialValues, visualSeed: 1,
        compareCount: tape.header.compareCount, swapCount: tape.header.swapCount,
        recordingDuration: 0, recordedAt: .distantPast, sortStartIndex: 1),
      operations: [.swap(0, 1)] + tape.operations)
    let trace = try #require(TeachingGraphTrace(tape: shuffled))
    #expect(trace.snapshot(at: 1).current == nil)
    #expect((trace.events.first?.step ?? 0) > 1)
    let last = trace.snapshot(at: shuffled.operations.count)
    #expect(last.events.count <= TeachingGraphTrace.maximumVisibleEvents)
    #expect(last.nodeCount <= TeachingGraphTrace.maximumVisibleNodes)
    #expect(trace.previousStep(before: 0) == nil)
    #expect(trace.nextStep(after: shuffled.operations.count) == nil)
  }

  @Test
  func navigationAndEventMappingHoldForDifferentInputShapes() throws {
    let inputs = [
      [1, 2, 3, 4, 5, 6],
      [6, 5, 4, 3, 2, 1],
      [3, 1, 3, 2, 1, 2],
    ]
    for values in inputs {
      for algorithm in [QuickSort() as any SortAlgorithm, MergeSort() as any SortAlgorithm] {
        let tape = makeTape(algorithm, values: values)
        let trace = try #require(TeachingGraphTrace(tape: tape))
        var current = 0
        var visited: [Int] = []
        while let next = trace.nextStep(after: current) {
          #expect(next > current)
          #expect(trace.snapshot(at: next).current?.step == next)
          visited.append(next)
          current = next
        }
        #expect(visited == trace.events.map(\.step))
        for expected in visited.reversed().dropFirst() {
          let previous = try #require(trace.previousStep(before: current))
          #expect(previous == expected)
          current = previous
        }
        assertAllReplayPositions(trace, tape: tape)
      }
    }
  }

  @Test
  func unannotatedAlgorithmsDoNotProduceTeachingEvents() {
    let tape = Tape(
      header: TapeHeader(
        algorithmID: "bubblesort", initialValues: [2, 1], visualSeed: 1,
        compareCount: 1, swapCount: 1, recordingDuration: 0, recordedAt: .distantPast),
      operations: [.compare(0, 1), .swap(0, 1)])
    #expect(TeachingGraphTrace(tape: tape) == nil)
  }

  @Test
  func annotationsProduceGraphEventsForAnyAlgorithmAndPreserveHeldValues() throws {
    let annotations = [
      TeachingAnnotation(operationIndex: 0, stageID: "patience.choosePile",
        outcome: "left", roles: ["held": .value(7), "target": .arrayIndex(1)],
        explanationKey: "patience.choosePile",
        explanation: "Place held value 7 in the first pile whose top is at least 7."),
      TeachingAnnotation(operationIndex: 1, stageID: "patience.place",
        outcome: "placed", roles: ["source": .value(7), "destination": .arrayIndex(1)],
        explanationKey: "patience.place", explanation: "Write the chosen value to position 2."),
    ]
    let tape = Tape(
      header: TapeHeader(algorithmID: "patiencesort", initialValues: [2, 7],
        visualSeed: 1, compareCount: 1, swapCount: 0,
        recordingDuration: 0, recordedAt: .distantPast),
      operations: [.compareValue(1, 7), .setValue(1, 7)],
      teachingAnnotations: annotations)
    let trace = try #require(TeachingGraphTrace(tape: tape))
    #expect(trace.variant == .annotated)
    #expect(trace.events.count == 2)
    #expect(trace.events[0].kind == .decision)
    #expect(trace.events[0].explanation == annotations[0].explanation)
    #expect(trace.events[0].source.location == .value
      || trace.events[0].target.location == .value)
    #expect(trace.events[1].kind == .movement)
    assertAllReplayPositions(trace, tape: tape)
  }

  @Test
  func knownAnnotationKeyUsesLocalizableTemplateInsteadOfRecordedEnglish() throws {
    let annotation = TeachingAnnotation(
      operationIndex: 0, stageID: "quick.partition.scanLeft", outcome: "advance",
      roles: ["pivot": .arrayIndex(0), "candidate": .arrayIndex(1)],
      explanationKey: "quick.pivotSide", explanation: "Recorded English text")
    let tape = Tape(
      header: TapeHeader(
        algorithmID: "quicksort", initialValues: [2, 1], visualSeed: 1,
        compareCount: 1, swapCount: 0, recordingDuration: 0, recordedAt: .distantPast),
      operations: [.compare(0, 1)], teachingAnnotations: [annotation])

    let trace = try #require(TeachingGraphTrace(tape: tape))
    #expect(trace.events[0].explanation ==
      "Position 2 is on the pivot's left side; advance the scan from pivot 1.")
  }

  @Test
  func realExchangeAndDistributionSortsUseTheUniversalGraph() throws {
    for algorithm in [BubbleSort() as any SortAlgorithm, LSDRadixSort()] {
      let tape = makeTape(algorithm, values: [4, 1, 3, 2])
      let trace = try #require(TeachingGraphTrace(tape: tape))
      #expect(trace.variant == .annotated)
      #expect(!trace.events.isEmpty)
      #expect(trace.events.allSatisfy { !$0.explanation.isEmpty })
      #expect(trace.events.count <= tape.teachingAnnotations.count)
      assertAllReplayPositions(trace, tape: tape)
    }
  }

  @Test
  func bingoSortGraphKeepsEventsAcrossTheReplay() throws {
    let tape = makeTape(BingoSort(), values: Array((0..<128).reversed()))
    let trace = try #require(TeachingGraphTrace(tape: tape))
    #expect(trace.variant == .annotated)
    var quartiles = [0, 0, 0, 0]
    for event in trace.events {
      quartiles[min(3, (event.step - 1) * 4 / tape.operations.count)] += 1
    }
    #expect(quartiles.allSatisfy { $0 > 0 },
      "The visible Bingo Sort graph misses a replay quartile: \(quartiles)")
  }

  @Test
  func teachingExplanationsPinDuringFastPlaybackAndCatchUpOnPause() {
    let now = Date(timeIntervalSince1970: 100)
    #expect(TeachingGraphPlaybackPolicy.shouldPin(isPlaying: true, pacingRate: 30))
    #expect(!TeachingGraphPlaybackPolicy.shouldPin(isPlaying: true, pacingRate: 1))
    #expect(!TeachingGraphPlaybackPolicy.shouldPin(isPlaying: false, pacingRate: 30))
    #expect(!TeachingGraphPlaybackPolicy.shouldUpdate(
      isPlaying: true, isPinned: true, now: now, lastUpdate: .distantPast))
    #expect(!TeachingGraphPlaybackPolicy.shouldUpdate(
      isPlaying: true, isPinned: false, now: now,
      lastUpdate: now.addingTimeInterval(-2)))
    #expect(TeachingGraphPlaybackPolicy.shouldUpdate(
      isPlaying: true, isPinned: false, now: now,
      lastUpdate: now.addingTimeInterval(-3)))
    #expect(TeachingGraphPlaybackPolicy.shouldUpdate(
      isPlaying: false, isPinned: false, now: now, lastUpdate: now))
  }

  @Test
  func annotatedAlgorithmsSortRandomAndDuplicateHeavyInputs() {
    var seed: UInt64 = 0xA11C_E123
    func nextValue() -> Int {
      seed = seed &* 2_862_933_555_777_941_757 &+ 3_037_000_493
      return Int((seed >> 32) % 9)
    }
    for size in [2, 8, 16, 32] {
      for _ in 0..<20 {
        let values = (0..<size).map { _ in nextValue() }
        for algorithm in [QuickSort() as any SortAlgorithm, MergeSort()] {
          var engine = RecordingEngine(values: values)
          algorithm.record(into: &engine)
          #expect(engine.values == values.sorted())
          let summary = engine.finish()
          #expect(summary.teachingAnnotations.allSatisfy {
            $0.operationIndex >= 0 && $0.operationIndex < summary.tape.count
          })
        }
      }
    }
  }

  @Test
  func mergeSortKeepsEqualKeysInTheirOriginalOrderWithAnnotations() {
    let keys = [2, 1, 2, 1, 2, 1, 2, 1]
    let encoded = keys.enumerated().map { $0.element * 100 + $0.offset }
    var engine = RecordingEngine(values: encoded, comparisonKeyForTesting: { $0 / 100 })
    MergeSort().record(into: &engine)
    #expect(engine.values.map { $0 / 100 } == keys.sorted())
    for key in [1, 2] {
      let originalIDs = encoded.filter { $0 / 100 == key }.map { $0 % 100 }
      let sortedIDs = engine.values.filter { $0 / 100 == key }.map { $0 % 100 }
      #expect(sortedIDs == originalIDs)
    }
    #expect(!engine.finish().teachingAnnotations.isEmpty)
  }

  private func makeTape(_ algorithm: any SortAlgorithm, values: [Int]) -> Tape {
    var engine = RecordingEngine(values: values)
    algorithm.record(into: &engine)
    let result = engine.finish()
    #expect(engine.values == values.sorted())
    return Tape(
      header: TapeHeader(
        algorithmID: algorithm.id.rawValue, initialValues: values, visualSeed: 1,
        compareCount: result.compareCount, swapCount: result.swapCount,
        mainWriteCount: result.mainWriteCount, auxWriteCount: result.auxWriteCount,
        recordingDuration: 0, recordedAt: .distantPast),
      operations: result.tape,
      teachingAnnotations: result.teachingAnnotations)
  }

  private func assertAllReplayPositions(_ trace: TeachingGraphTrace, tape: Tape) {
    for step in 0...tape.operations.count {
      let expected = trace.events.last { $0.step <= step }
      let snapshot = trace.snapshot(at: step)
      #expect(snapshot.current == expected)
      #expect(snapshot.nodeCount <= TeachingGraphTrace.maximumVisibleNodes)
      #expect(snapshot.events.count <= TeachingGraphTrace.maximumVisibleEvents)
      if let next = trace.nextStep(after: step) { #expect(next > step) }
      if let previous = trace.previousStep(before: step) { #expect(previous < step) }
    }
  }
}
