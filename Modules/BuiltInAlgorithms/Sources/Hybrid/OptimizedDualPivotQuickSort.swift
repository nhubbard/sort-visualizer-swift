import AlgorithmKit
import SortEngineKit

/// ArrayV's `OptimizedDualPivotQuickSort` — Vladimir Yaroslavskiy's dual-pivot quicksort (the same
/// family real-world Java's `Arrays.sort` uses for primitives), with two real additions over the
/// already-shipped plain `DualPivotQuickSort`:
/// - The insertion-sort cutoff is raised from 4 to 27 — a much larger base case, tuned for real
///   throughput rather than mainly demonstrating the partition itself.
/// - An "equal elements" pass shrinks the region needing further recursive sorting on
///   duplicate-heavy input: after the main partition and after recursing into the low/high thirds,
///   any element in the remaining middle region that's *exactly* equal to `pivot1`/`pivot2` gets
///   moved out to extend the low/high regions instead — those elements are already correctly
///   placed relative to everything outside the middle, so they need no further comparison. This
///   only runs when the middle region already came out large (`dist > length - 13`) and the two
///   pivots actually differ (skipped entirely on an all-equal range, where it would find nothing).
///   Every other structural piece (the adaptive `divisor`, the `dist < 13` bump) is identical to
///   `DualPivotQuickSort` — see that file's own doc comment for why those exist.
///
/// Recursion order matters here and is preserved exactly: low third, then high third, *then* the
/// equal-elements pass (which further shrinks `less`/`great`), and only then the middle — not
/// because the equal-elements pass depends on the outer two being sorted first (it only ever
/// touches the still-untouched `[less, great]` middle region), but because that's the order
/// ArrayV's own translation of Yaroslavskiy's reference implementation uses.
public struct OptimizedDualPivotQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizeddualpivotquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Dual-Pivot Quick",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1293, coefficients: [239931, 338.964, 0.119008],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.119008, 31.2089, 614.358], rSquared: 0.998653),
    // Confirmed via a direct measurement (not just accepted blindly): the negative R² here isn't
    // a bug — the calibration's sample sizes straddle this algorithm's own insertion-sort cutoff
    // (27) badly, with 4 samples entirely below it (pure O(n) insertion sort) and 4 entirely above
    // (real partitioning), so no single smooth 2-parameter family can fit both regimes at once.
    // Every sampled size still sorted correctly; this is the same kind of threshold-adjacent poor
    // fit already accepted for other shipped algorithms (e.g. `indexsort+halfrotation` at 0.344).
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "divide.circle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    dualPivot(&engine, 0, engine.count - 1, 3)
  }

  /// ArrayV's `insertSorter.customInsertSort(array, left, right + 1, 0.333, false)` base case —
  /// sorts the half-open range `[start, end)`, matching `DualPivotQuickSort.insertionSort`'s own
  /// shape exactly (only the caller's cutoff length differs: 27 here vs. 4 there).
  private func insertionSort(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard start + 1 < end else { return }
    for i in (start + 1)..<end {
      var j = i
      while j > start && !engine.compare(j, j - 1) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }

  private func dualPivot(_ engine: inout RecordingEngine, _ left: Int, _ right: Int, _ divisor: Int) {
    let length = right - left
    // Insertion sort for tiny ranges (also covers empty/inverted ranges produced by the
    // recursive boundary arithmetic below, since `length` is then negative and always < 27).
    if length < 27 {
      insertionSort(&engine, left, right + 1)
      return
    }

    let third = length / divisor
    var med1 = left + third
    var med2 = right - third
    if med1 <= left { med1 = left + 1 }
    if med2 >= right { med2 = right - 1 }

    if engine.compare(med1, med2, by: (<)) {
      engine.swap(med1, left)
      engine.swap(med2, right)
    } else {
      engine.swap(med1, right)
      engine.swap(med2, left)
    }

    // Held pivot values, captured now — right after `left`/`right` were placed by the swaps
    // above — read directly via `engine.values` rather than `engine.compare`, since the
    // partitioning loop below moves other elements through positions `left`/`right` while
    // `pivot1`/`pivot2` must stay fixed at the values captured here. Same held-value pattern as
    // `DualPivotQuickSort.swift`.
    let pivot1 = engine.values[left]
    let pivot2 = engine.values[right]

    var less = left + 1
    var great = right - 1

    var k = less
    while k <= great {
      if engine.compareValue(k, against: pivot1, by: (<)) {
        engine.swap(k, less)
        less += 1
      } else if engine.compareValue(k, against: pivot2, by: (>)) {
        while k < great && engine.compareValue(great, against: pivot2, by: (>)) {
          great -= 1
        }
        engine.swap(k, great)
        great -= 1
        if engine.compareValue(k, against: pivot1, by: (<)) {
          engine.swap(k, less)
          less += 1
        }
      }
      k += 1
    }

    var divisor = divisor
    let dist = great - less
    if dist < 13 { divisor += 1 }

    engine.swap(less - 1, left)
    engine.swap(great + 1, right)

    dualPivot(&engine, left, less - 2, divisor)
    dualPivot(&engine, great + 2, right, divisor)

    // Equal-elements pass: shrink the still-unsorted middle by pulling out anything exactly
    // equal to either pivot. `less`/`great` are live loop bounds being mutated here, so `k`
    // against `pivot1`/`pivot2` goes through `engine.compareValue`; `pivot1`/`pivot2` against
    // each other (both held values, neither a live index) goes through `engine.compareValues`.
    if dist > length - 13 && engine.compareValues(pivot1, pivot2, by: (!=)) {
      var k = less
      while k <= great {
        if engine.compareValue(k, against: pivot1, by: (==)) {
          engine.swap(k, less)
          less += 1
        } else if engine.compareValue(k, against: pivot2, by: (==)) {
          engine.swap(k, great)
          great -= 1
          if engine.compareValue(k, against: pivot1, by: (==)) {
            engine.swap(k, less)
            less += 1
          }
        }
        k += 1
      }
    }

    if engine.compareValues(pivot1, pivot2, by: (<)) {
      dualPivot(&engine, less, great, divisor)
    }
  }
}
