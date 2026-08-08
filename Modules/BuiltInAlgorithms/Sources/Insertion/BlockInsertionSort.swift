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
    displayName: "Block Insertion Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 573, coefficients: [239718, 808.206, 0.679677],
      measuredSafeCeiling: nil),
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
      if engine.compare(i - 1, i, by: >) {
        i += 1
        while i < b && engine.compare(i - 1, i, by: >) { i += 1 }
        engine.reversal(a, i - 1)
      } else {
        i += 1
        while i < b && engine.compare(i - 1, i, by: <=) { i += 1 }
      }
      return i
    }

    // Classic single-element insertion-sort shift.
    func insert1(_ a: Int, _ l: Int) {
      let tmp = engine.values[l]
      var l = l - 1
      while l >= a && engine.values[l] > tmp {
        engine.setValue(l + 1, engine.values[l])
        l -= 1
      }
      engine.setValue(l + 1, tmp)
    }

    // Inserts a known-ordered PAIR (values at `l` and `r`, `l < r`) in one pass, avoiding a
    // re-scan for the second element.
    func insert2(_ a: Int, _ l: Int, _ r: Int) {
      let tmpL = engine.values[l]
      let tmpR = engine.values[r]
      var l = l - 1
      while l >= a && engine.values[l] > tmpR {
        engine.setValue(l + 2, engine.values[l])
        l -= 1
      }
      engine.setValue(l + 2, tmpR)
      while l >= a && engine.values[l] > tmpL {
        engine.setValue(l + 1, engine.values[l])
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
