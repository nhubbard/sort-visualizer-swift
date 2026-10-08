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
  func unrelatedAlgorithmsDoNotProduceTeachingEvents() {
    let tape = Tape(
      header: TapeHeader(
        algorithmID: "bubblesort", initialValues: [2, 1], visualSeed: 1,
        compareCount: 1, swapCount: 1, recordingDuration: 0, recordedAt: .distantPast),
      operations: [.compare(0, 1), .swap(0, 1)])
    #expect(TeachingGraphTrace(tape: tape) == nil)
  }

  private func makeTape(_ algorithm: any SortAlgorithm, values: [Int]) -> Tape {
    var engine = RecordingEngine(values: values)
    algorithm.record(into: &engine)
    let result = engine.finish()
    return Tape(
      header: TapeHeader(
        algorithmID: algorithm.id.rawValue, initialValues: values, visualSeed: 1,
        compareCount: result.compareCount, swapCount: result.swapCount,
        mainWriteCount: result.mainWriteCount, auxWriteCount: result.auxWriteCount,
        recordingDuration: 0, recordedAt: .distantPast),
      operations: result.tape)
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
