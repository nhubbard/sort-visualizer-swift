import AlgorithmKit
import SortEngineKit

/// ArrayV's `HybridCombSort` — identical to plain `CombSort.swift` except once the shrinking gap
/// drops to `<= min(8, length * 0.03125)`, it abandons the comb-gap technique and finishes with one
/// full straight Insertion Sort pass instead of grinding out the remaining tiny-gap passes.
///
/// The Insertion Sort finish runs at most once: the hybrid check fires (if at all) at a pass's
/// `i == 0`, before that pass could set `swapped = true`, so `gap == 0 && swapped == false` always
/// holds right after, ending the outer loop immediately.
public struct HybridCombSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "hybridcombsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Hybrid Comb Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1095, coefficients: [239934, 387.443, 0.153455],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.153455, 51.3758, -318.896], rSquared: 0.999988),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "comb.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let shrink = 1.3
    // ArrayV: `gap <= Math.min(8, length * 0.03125)`. `gap` is constant within a pass, so this
    // check either fires at that pass's first iteration or never fires during that pass at all.
    let hybridThreshold = min(8.0, Double(n) * 0.03125)
    var gap = Double(n)
    var swapped = false

    while gap > 1 || swapped {
      if gap > 1 {
        gap = (gap / shrink).rounded(.down)
      }
      swapped = false
      let gapInt = Int(gap)
      var i = 0
      while gapInt + i < n {
        if gap <= hybridThreshold {
          gap = 0
          finishWithInsertionSort(&engine, count: n)
          break
        }
        // Strict "values[i] > values[i+gap]": engine.compare is always >=, and using it
        // as-is here would swap equal adjacent elements forever once gap settles at 1.
        // a > b  <=>  !(b >= a), i.e. !engine.compare(i + gap, i).
        if !engine.compare(gapInt + i, i) {
          engine.swap(i, gapInt + i)
          swapped = true
        }
        i += 1
      }
    }
  }

  /// ArrayV's `InsertionSort.customInsertSort(array, 0, length, 0.5, false)` finishing pass — a
  /// plain straight insertion sort over the whole array. `InsertionSort.swift` is itself a
  /// distinct `SortAlgorithm`, not a plain function, so this is its own private inline copy
  /// rather than a call into that file.
  private func finishWithInsertionSort(_ engine: inout RecordingEngine, count n: Int) {
    guard n > 1 else { return }
    for i in 1..<n {
      var j = i
      while j > 0 && !engine.compare(j, j - 1) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }
}
