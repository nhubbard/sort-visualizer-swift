import AlgorithmKit
import SortEngineKit

/// ArrayV's `BinaryDoubleInsertionSort` — a binary-search-accelerated sibling of
/// `DoubleInsertionSort` (see that file for the shared middle-outward-growth shape: `i`/`j` start
/// straddling the midpoint and step outward, absorbing one new element from each side per pass).
/// The difference: instead of a linear scan-while-shifting insertion, each new element's exact
/// destination is found first via binary search (`leftBinarySearch`/`rightBinarySearch`), then
/// placed with a single shift-and-drop pass (`insertToLeft`/`insertToRight`). This cuts comparisons
/// per insertion from O(n) to O(log n), but the shift is still a linear walk, so the overall time
/// bound is unchanged from the sibling.
///
/// Stable: the element from `j` (larger original index) uses `rightBinarySearch`'s strict `<`
/// (upper-bound, lands after resident equals); the element from `i` (smaller original index) uses
/// `leftBinarySearch`'s non-strict `<=` (lower-bound, lands before resident equals). That asymmetry
/// keeps equal elements in original order.
public struct BinaryDoubleInsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binarydoubleinsertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Binary Double Insertion Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 910, coefficients: [239899, 507.559, 0.267874],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.267874, 20.0294, -153.637], rSquared: 0.999996),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "square.split.2x1"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    // ArrayV's `leftBinarySearch`: held-value lower-bound search (non-strict `<=`), so ties
    // resolve left — `val` lands before any resident equal elements.
    func leftBinarySearch(_ a: Int, _ b: Int, _ val: Int) -> Int {
      var lo = a
      var hi = b
      while lo < hi {
        let mid = lo + (hi - lo) / 2
        if engine.compareValue(mid, against: val, by: (>=)) {
          hi = mid
        } else {
          lo = mid + 1
        }
      }
      return lo
    }

    // ArrayV's `rightBinarySearch`: strict upper-bound search, so ties resolve right — `val`
    // lands after any resident equal elements.
    func rightBinarySearch(_ a: Int, _ b: Int, _ val: Int) -> Int {
      var lo = a
      var hi = b
      while lo < hi {
        let mid = lo + (hi - lo) / 2
        if engine.compareValue(mid, against: val, by: (>)) {
          hi = mid
        } else {
          lo = mid + 1
        }
      }
      return lo
    }

    // ArrayV's `insertToLeft(array, a, b, temp, sleep)`: the destination `b` was already
    // pinned down by an exact binary search above, so there's nothing left to compare here —
    // just shift the block `(b, a]` one slot toward `a`, then drop `temp` at `b`.
    func insertToLeft(_ a: Int, _ b: Int, _ temp: Int) {
      var a = a
      while a > b {
        engine.setValue(a, engine.values[a - 1])
        a -= 1
      }
      engine.setValue(b, temp)
    }

    // ArrayV's `insertToRight(array, a, b, temp, sleep)`: mirror image of the above, shifting
    // the block `[a, b)` one slot toward `b`.
    func insertToRight(_ a: Int, _ b: Int, _ temp: Int) {
      var a = a
      while a < b {
        engine.setValue(a, engine.values[a + 1])
        a += 1
      }
      engine.setValue(a, temp)
    }

    // ArrayV's `doubleInsertion(array, a, b, compSleep, sleep)`.
    func doubleInsertion(_ a: Int, _ b: Int) {
      guard b - a >= 2 else { return }

      // Same seed-index arithmetic as `DoubleInsertionSort.insertionSort`'s `left`/`right`. For
      // odd-length ranges `i` and `j` coincide on the middle element; the `j > i` guard below
      // skips the swap check then.
      let j0 = a + (b - a - 2) / 2 + 1
      let i0 = a + (b - a - 1) / 2
      var i = i0
      var j = j0

      // Reads.compareIndices(array, i, j, ..., true) == 1 — STRICT greater-than, both
      // indices live.
      if j > i && engine.compare(i, j, by: (>)) {
        engine.swap(i, j)
      }
      i -= 1
      j += 1

      while j < b {
        // Reads.compareIndices(array, i, j, ..., true) == 1 — STRICT greater-than, both
        // indices live.
        if engine.compare(i, j, by: (>)) {
          // `l`/`r` are captured *before* either insertion below writes anything,
          // matching ArrayV's `int l = array[j]; int r = array[i];` ordering exactly.
          let l = engine.values[j]
          let r = engine.values[i]

          // `l` (from `j`) uses `rightBinarySearch`; `r` (from `i`) uses `leftBinarySearch` —
          // see the type-level stability note for why.
          let m = rightBinarySearch(i + 1, j, l)
          insertToRight(i, m - 1, l)
          let dest = leftBinarySearch(m, j, r)
          insertToLeft(j, dest, r)
        } else {
          let l = engine.values[i]
          let r = engine.values[j]

          // Branches swapped relative to the `if` above: `l` (from `i`) now uses
          // `leftBinarySearch`, `r` (from `j`) uses `rightBinarySearch`.
          let m = leftBinarySearch(i + 1, j, l)
          insertToRight(i, m - 1, l)
          let dest = rightBinarySearch(m, j, r)
          insertToLeft(j, dest, r)
        }

        i -= 1
        j += 1
      }
    }

    doubleInsertion(0, n)
  }
}
