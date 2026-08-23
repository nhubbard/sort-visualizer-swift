import AlgorithmKit
import SortEngineKit

/// ArrayV's `InPlaceMergeSort` (not `ImprovedInPlaceMergeSort`, a different algorithm) — Merge
/// Sort's divide-and-conquer shape, but the merge never allocates an O(n) buffer: whenever a
/// left-run element exceeds the right run's leading element, the two are swapped and the displaced
/// element is bubbled rightward through the remainder of the right run via `push` until it lands
/// correctly. This trades `MergeSort`'s O(n) space for an asymptotically worse merge: `push` can
/// rescan up to the entire right run per out-of-order element.
public struct InPlaceMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "inplacemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "In-Place Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [238710, 2185, 5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [5, -5, -1.35917e-10], rSquared: 1),
    // Not stable, despite resembling a textbook (stable) merge: `merge`'s swaps are positional
    // (driven by the fixed index `mid + 1`), so `push` can walk a duplicate past another
    // occurrence of the same value at a different recursion level without the two ever being
    // compared directly.
    stable: false,
    // Best case (already-sorted): merge never swaps, push never runs, O(n log n). Average/worst:
    // push turns each merge into an insertion-sort-style shift across the two runs, so summed
    // across the recursion this is O(n^2), not O(n log n).
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n^2)", worst: "O(n^2)"),
    // No aux array — the merge swaps and bubbles within the array itself.
    spaceComplexity: "O(log n)",
    iconName: "rectangle.compress.vertical"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    // Single left-to-right adjacent-swap pass over [low, high]: bubbles the element that was
    // just dropped at `low` rightward through the (still otherwise sorted) run until it's back
    // in order. Mirrors ArrayV's `push(array, low, high)`.
    func push(_ low: Int, _ high: Int) {
      var i = low
      while i < high {
        if engine.compare(i, i + 1, by: >) {
          engine.swap(i, i + 1)
        }
        i += 1
      }
    }

    // Merges the two adjacent sorted runs [min, mid] and [mid + 1, max] in place. For each
    // left-run element still greater than the right run's current leading element, swap them
    // (moving the smaller value into the left run) and then bubble the displaced larger value
    // into its correct place within the right run via `push`. Mirrors ArrayV's
    // `merge(array, min, max, mid)`.
    func merge(_ min: Int, _ max: Int, _ mid: Int) {
      var i = min
      while i <= mid {
        if engine.compare(i, mid + 1, by: >) {
          engine.swap(i, mid + 1)
          push(mid + 1, max)
        }
        i += 1
      }
    }

    // Mirrors ArrayV's `mergeSort(array, min, max)`, operating on the inclusive range
    // [min, max] rather than the app's usual half-open convention.
    func mergeSort(_ min: Int, _ max: Int) {
      if max - min == 0 {
        return
      } else if max - min == 1 {
        if engine.compare(min, max, by: >) {
          engine.swap(min, max)
        }
      } else {
        let mid = (min + max) / 2
        mergeSort(min, mid)
        mergeSort(mid + 1, max)
        merge(min, max, mid)
      }
    }

    mergeSort(0, n - 1)
  }
}
