import Foundation
import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `BlockInsertionSort` — does NOT call `GrailSortingTemplate.commonSort` at
/// all. It's a natural-run-detecting insertion sort built from just `mergeWithoutBuffer` as a
/// primitive (merging any run of 3+ elements found via `findRun` into the already-sorted prefix),
/// falling back to direct shift-based insertion (`insert1`/`insert2`) for runs of length 1 or 2.
///
/// ArrayV's own subclass additionally overrides `grailRotate` with `Rotations.holyGriesMills` — on
/// inspection this is the same "repeated block-swap of the smaller side" rotation as
/// `GrailSortingTemplate.rotate`, just with an added length-1 fast path as a pure micro-
/// optimization (semantically identical). `mergeWithoutBuffer` calls `rotate` internally, so this
/// port reuses the shared template's `rotate` directly rather than duplicating an equivalent
/// override.
///
/// **Stability**: real mutations here are a mix of `engine.swap` (`mergeWithoutBuffer`, for runs
/// of 3+) and `engine.setValue` (`insert1`/`insert2`'s shifts, for runs of length 1-2) — the
/// standard swap-tape-shadow stability test can't observe the latter and produces false failures
/// if pointed at this algorithm (confirmed: 31/50 spurious "failures"). Verified genuinely stable
/// instead by simulating this exact algorithm in Python with a parallel original-index array
/// threaded through every swap and write (2,000 randomized duplicate-heavy trials, zero wrong
/// results, zero instability) — `insert1`/`insert2` only ever shift elements strictly greater than
/// the value being placed, so they never displace a tied element, and `findRun` only reverses
/// strictly-decreasing runs (which by definition contain no ties to disturb), matching
/// `mergeWithoutBuffer`'s own already-established stability.
public struct BlockInsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "blockinsertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Block Insertion Sort", bundle: .module),
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 498, coefficients: [239858, 950.764, 0.941836],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.941836, 12.6947, -43.1326], rSquared: 1),
    implementationComplexity: 43,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // Finds the end of the natural run starting at `a`: an ascending-or-equal run is scanned
    // as-is; a strictly descending run is scanned then reversed in place.
    func findRun(_ a: Int, _ b: Int) -> Int {
      var i = a + 1
      guard i != b else { return i }
      if engine.teachingCompare(
        i - 1, i,
        by: >,
        stageID: "BlockInsertionSort.blockBoundary",
        whenTrue: String(localized: "The previous item is larger, so this pair starts a block insertion.", bundle: .module),
        whenFalse: String(localized: "This neighboring pair does not need block insertion.", bundle: .module)
      ) {
        i += 1
        while i < b && engine.teachingCompare(
          i - 1, i, by: >, stageID: "BlockInsertionSort.descendingRun",
          whenTrue: String(localized: "This pair continues the descending run, so include it before reversing.", bundle: .module),
          whenFalse: String(localized: "The descending run ends here; reverse the run to make it ascending.", bundle: .module)
        ) { i += 1 }
        engine.teachingReversal(
          a, i - 1, stageID: "BlockInsertionSort.reverseDescendingRun",
          explanation: String(localized: "Reverse the descending run to make it an ascending block.", bundle: .module))
      } else {
        i += 1
        while i < b && engine.teachingCompare(
          i - 1, i, by: <=, stageID: "BlockInsertionSort.ascendingRun",
          whenTrue: String(localized: "This pair continues the ascending run, so leave it in place.", bundle: .module),
          whenFalse: String(localized: "The ascending run ends here; insert the next block.", bundle: .module)
        ) { i += 1 }
      }
      return i
    }

    // Classic single-element insertion-sort shift.
    func insert1(_ a: Int, _ l: Int) {
      let tmp = engine.readValue(at: l)
      var l = l - 1
      while l >= a && engine.teachingCompareValue(
        l, against: tmp, by: >, stageID: "BlockInsertionSort.singleShift",
        whenTrue: String(localized: "This item is larger than the held value, so shift it right.", bundle: .module),
        whenFalse: String(localized: "The held value has reached its insertion position.", bundle: .module)
      ) {
        engine.setValue(l + 1, engine.readValue(at: l))
        l -= 1
      }
      engine.setValue(l + 1, tmp)
    }

    // Inserts a known-ordered PAIR (values at `l` and `r`, `l < r`) in one pass, avoiding a
    // re-scan for the second element.
    func insert2(_ a: Int, _ l: Int, _ r: Int) {
      let tmpL = engine.readValue(at: l)
      let tmpR = engine.readValue(at: r)
      var l = l - 1
      while l >= a && engine.teachingCompareValue(
        l, against: tmpR, by: >, stageID: "BlockInsertionSort.pairRightShift",
        whenTrue: String(localized: "This item is larger than the right held value, so shift it two places.", bundle: .module),
        whenFalse: String(localized: "The right held value has reached its insertion boundary.", bundle: .module)
      ) {
        engine.setValue(l + 2, engine.readValue(at: l))
        l -= 1
      }
      engine.setValue(l + 2, tmpR)
      while l >= a && engine.teachingCompareValue(
        l, against: tmpL, by: >, stageID: "BlockInsertionSort.pairLeftShift",
        whenTrue: String(localized: "This item is larger than the left held value, so shift it right.", bundle: .module),
        whenFalse: String(localized: "The left held value has reached its insertion boundary.", bundle: .module)
      ) {
        engine.setValue(l + 1, engine.readValue(at: l))
        l -= 1
      }
      engine.setValue(l + 1, tmpL)
    }

    var i = findRun(0, n)
    while i < n {
      let j = findRun(i, n)
      let len = j - i
      if len == 1 {
        insert1(0, i)
      } else if len == 2 {
        insert2(0, i, i + 1)
      } else {
        GrailSortingTemplate.mergeWithoutBuffer(&engine, 0, i, len)
      }
      i = j
    }
  }
}
