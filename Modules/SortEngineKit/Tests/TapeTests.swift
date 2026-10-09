import Foundation
import Testing

@testable import SortEngineKit

@Suite
struct TapeTests {
  @Test
  func annotationAnchorsSurviveCosmeticCompaction() {
    var engine = RecordingEngine(values: [2, 1])
    _ = engine.compare(0, 1)
    engine.annotateLastOperation(
      stageID: "test.compare", outcome: "left", roles: ["left": .arrayIndex(0)],
      explanationKey: "test.choice")
    engine.swap(0, 1)
    let summary = engine.finish()
    #expect(summary.teachingAnnotations.count == 1)
    let annotation = summary.teachingAnnotations[0]
    #expect(summary.tape[annotation.operationIndex] == .compare(0, 1))
    let tape = Tape(
      header: TapeHeader(
        algorithmID: "test", initialValues: [2, 1], visualSeed: 1,
        compareCount: 1, swapCount: 1, recordingDuration: 0,
        recordedAt: .distantPast),
      operations: summary.tape, teachingAnnotations: summary.teachingAnnotations)
    let compacted = tape.compactedForFastPlayback()
    #expect(compacted.teachingAnnotations.count == 1)
    #expect(compacted.operations[compacted.teachingAnnotations[0].operationIndex] == .compare(0, 1))
    #expect(compacted.teachingAnnotations[0].operationIndex < annotation.operationIndex)
  }

  @Test
  func authoredExplanationSurvivesCodableAndOffset() throws {
    let annotation = TeachingAnnotation(operationIndex: 2,
      stageID: "test.choose", outcome: "smaller",
      roles: ["candidate": .arrayIndex(1)],
      explanationKey: "test.choose",
      explanation: "Choose position 2 because it is smaller.")
    let decoded = try JSONDecoder().decode(TeachingAnnotation.self,
      from: JSONEncoder().encode(annotation))
    #expect(decoded == annotation)
    #expect(annotation.shifted(by: 3).explanation == annotation.explanation)

    // Annotations written before explanations were added must remain readable.
    let legacy = """
      {"operationIndex":2,"definitionVersion":1,"stageID":"test.choose",
       "decisionID":null,"outcome":"smaller","roles":{},"explanationKey":"test.choose"}
      """.data(using: .utf8)!
    #expect(try JSONDecoder().decode(TeachingAnnotation.self, from: legacy).explanation == nil)
  }

  @Test
  func teachingAnnotationsStayBoundedAndCoverLongRecordings() {
    var engine = RecordingEngine(values: [1], operationCap: 20_000)
    for index in 0..<10_000 {
      _ = engine.compareValues(index, index + 1)
      if engine.shouldAnnotateCurrentOperation {
        engine.annotateLastOperation(stageID: "test.sequence", outcome: "next",
          roles: ["value": .value(index)], explanationKey: "test.sequence",
          explanation: "Advance to the next comparison.")
      }
    }
    let summary = engine.finish()
    #expect(summary.teachingAnnotations.count <= 2_048)
    #expect(summary.teachingAnnotations.first?.operationIndex == 0)
    #expect((summary.teachingAnnotations.last?.operationIndex ?? 0) >= 9_900)
    #expect(summary.tape.count == 10_000)
  }

  @Test
  func teachingSamplingKeepsARepeatingOddOperationPosition() {
    var engine = RecordingEngine(values: [1], operationCap: 25_000)
    _ = engine.readValue(at: 0)
    for index in 0..<10_000 {
      _ = engine.compareValues(index, index + 1)
      if engine.shouldAnnotateCurrentOperation {
        engine.annotateLastOperation(stageID: "test.odd", outcome: "next",
          roles: ["value": .value(index)], explanationKey: "test.odd",
          explanation: "Compare the next held value.")
      }
      _ = engine.readValue(at: 0)
    }
    let annotations = engine.finish().teachingAnnotations
    #expect(!annotations.isEmpty)
    #expect(annotations.count <= 2_048)
    #expect((annotations.last?.operationIndex ?? 0) >= 19_800)
  }

  @Test
  func cappedRecordingDoesNotRetainPartialAnnotations() {
    var engine = RecordingEngine(values: [2, 1], operationCap: 1)
    _ = engine.compare(0, 1)
    engine.annotateLastOperation(
      stageID: "test.compare", outcome: "left", roles: [:],
      explanationKey: "test.choice")
    let summary = engine.finish()
    #expect(summary.didExceedCap)
    #expect(summary.teachingAnnotations.isEmpty)
  }

  @Test
  func annotationsDoNotChangeOperationsOrCounters() {
    var plain = RecordingEngine(values: [2, 1])
    var annotated = RecordingEngine(values: [2, 1])
    _ = plain.compare(0, 1)
    plain.swap(0, 1)
    _ = annotated.compare(0, 1)
    annotated.annotateLastOperation(
      stageID: "test.compare", outcome: "right", roles: [:],
      explanationKey: "test.choice")
    annotated.swap(0, 1)
    let plainSummary = plain.finish()
    let annotatedSummary = annotated.finish()
    #expect(annotatedSummary.tape == plainSummary.tape)
    #expect(annotatedSummary.compareCount == plainSummary.compareCount)
    #expect(annotatedSummary.swapCount == plainSummary.swapCount)
    #expect(annotated.values == plain.values)
  }

  @Test
  func teachingReversalExplainsInternalSwapsWithoutChangingTheTape() {
    var plain = RecordingEngine(values: [4, 3, 2, 1])
    var taught = RecordingEngine(values: [4, 3, 2, 1])
    plain.reversal(0, 3)
    taught.teachingReversal(0, 3, stageID: "test.reverse",
      explanation: "Reverse the descending run.")
    let plainResult = plain.finish()
    let taughtResult = taught.finish()
    #expect(taughtResult.tape == plainResult.tape)
    #expect(taughtResult.reversalCount == plainResult.reversalCount)
    #expect(taughtResult.swapCount == plainResult.swapCount)
    #expect(taughtResult.teachingAnnotations.count == 2)
    #expect(taughtResult.teachingAnnotations.allSatisfy {
      if case .swap = taughtResult.tape[$0.operationIndex] { return true }
      return false
    })
  }

  private func makeTape(
    operations: [SortOperation], sortStartIndex: Int = 0,
    compareCount: Int = 3, swapCount: Int = 2
  ) -> Tape {
    Tape(
      header: TapeHeader(
        algorithmID: "test",
        initialValues: [3, 1, 2],
        visualSeed: 0,
        compareCount: compareCount,
        swapCount: swapCount,
        mainWriteCount: 4,
        auxWriteCount: 1,
        reversalCount: 0,
        recordingDuration: 0,
        recordedAt: Date(timeIntervalSince1970: 0),
        sortStartIndex: sortStartIndex
      ),
      operations: operations
    )
  }

  @Test
  func significantOperationCountCountsOnlyRealAlgorithmicWork() {
    let tape = makeTape(operations: [
      .mark(marker: 0, index: 0),
      .mark(marker: 1, index: 1),
      .compare(0, 1),
      .unmarkIndex(marker: 0, index: 0),
      .unmarkIndex(marker: 1, index: 1),
      .swap(0, 1),
      .unmarkAll,
      .markSorted(0)
    ])
    // .compare, .swap, .markSorted are significant; the four mark/unmark entries are not.
    #expect(tape.significantOperationCount == 3)
  }

  @Test
  func compactedForFastPlaybackDropsOnlyCosmeticMarkerOps() {
    let tape = makeTape(operations: [
      .mark(marker: 0, index: 0),
      .mark(marker: 1, index: 1),
      .compare(0, 1),
      .unmarkIndex(marker: 0, index: 0),
      .unmarkIndex(marker: 1, index: 1),
      .swap(0, 1),
      .unmark(marker: 0),
      .unmarkAll,
      .auxCreate(handle: 0, length: 2),
      .auxWrite(handle: 0, index: 0, value: 9),
      .auxDelete(handle: 0),
      .markSorted(0)
    ])
    let compacted = tape.compactedForFastPlayback()

    #expect(
      compacted.operations == [
        .compare(0, 1),
        .swap(0, 1),
        .auxCreate(handle: 0, length: 2),
        .auxWrite(handle: 0, index: 0, value: 9),
        .auxDelete(handle: 0),
        .markSorted(0)
      ])
  }

  @Test
  func compactedForFastPlaybackPreservesHeaderStatsVerbatim() {
    let tape = makeTape(
      operations: [.mark(marker: 0, index: 0), .compare(0, 1)],
      compareCount: 123, swapCount: 45
    )
    let compacted = tape.compactedForFastPlayback()

    #expect(compacted.header.compareCount == 123)
    #expect(compacted.header.swapCount == 45)
    #expect(compacted.header.mainWriteCount == tape.header.mainWriteCount)
    #expect(compacted.header.auxWriteCount == tape.header.auxWriteCount)
    #expect(compacted.header.algorithmID == tape.header.algorithmID)
  }

  /// The real correctness detail: `sortStartIndex` is an absolute index into `operations`, so
  /// dropping entries before it must shift it by exactly how many of those dropped entries
  /// preceded it — copying it verbatim would desync `ReplayEngine`'s shuffle/sort stat gate from
  /// the actual boundary in the compacted stream.
  @Test
  func compactedForFastPlaybackRemapsSortStartIndex() {
    let tape = makeTape(
      operations: [
        // "Shuffle" phase (indices 0...3): two significant swaps, two cosmetic marks.
        .swap(0, 1),
        .mark(marker: 0, index: 0),
        .swap(1, 2),
        .unmarkAll,
        // "Sort" phase begins at original index 4.
        .compare(0, 1),
        .markSorted(0)
      ],
      sortStartIndex: 4
    )
    let compacted = tape.compactedForFastPlayback()

    // Only the two swaps survive from the shuffle phase, so the boundary shifts from 4 to 2.
    #expect(compacted.header.sortStartIndex == 2)
    #expect(compacted.operations == [.swap(0, 1), .swap(1, 2), .compare(0, 1), .markSorted(0)])
  }
}
