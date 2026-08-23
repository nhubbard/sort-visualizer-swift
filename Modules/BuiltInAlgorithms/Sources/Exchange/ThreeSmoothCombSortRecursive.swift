import AlgorithmKit
import SortEngineKit

/// ArrayV's `ThreeSmoothCombSortRecursive` — a sibling of `ClassicThreeSmoothCombSort` and
/// `ThreeSmoothCombSortIterative`; all three run Shellsort over V. Pratt's 3-smooth gap sequence
/// (every gap `2^a * 3^b`, decreasing, one pass each) — a fixed, data-independent sorting network.
///
/// This variant reaches the gap set through mutual recursion rather than computing it directly:
/// `recursiveComb` recurses twice with `gap` doubled before calling `powerOfThree` at its own gap;
/// `powerOfThree` recurses three ways with `gap` tripled before performing the actual
/// compare-and-swap pass. Because each level's doubling/tripling runs before its own pass,
/// larger-gap passes still fire before smaller ones, matching Pratt's required order.
///
/// Stability: `false` — a gap > 1 pass can swap elements past equal-valued elements between them
/// without ever comparing them directly. Confirmed via tagged-value fuzzing.
///
/// Complexity: `Θ(n log^2 n)` in every case, matching both siblings. Space is `O(log n)` — unlike
/// the siblings' flat-loop `O(1)`, this recursion's call-stack depth is `O(log n)` doubling levels
/// each nested with `O(log n)` tripling levels.
public struct ThreeSmoothCombSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "threesmoothcombsortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "3-Smooth Comb Sort (Recursive)",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 959, coefficients: [224607, 317.145, 0.0559625],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [8.15281, 1.20846], rSquared: 0.9996),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(log n)",
    iconName: "arrow.up.arrow.down"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }

    // Ports `powerOfThree(array, pos, gap, end)`: recurse three ways with `gap` tripled (at
    // `pos`, `pos + gap`, `pos + 2*gap`), covering every power-of-3 multiple of `gap` first, then
    // — only once all three return — perform the single compare-and-swap pass at `gap` itself.
    func powerOfThree(pos: Int, gap: Int, end: Int) {
      guard pos + gap <= end else { return }

      powerOfThree(pos: pos, gap: gap * 3, end: end)
      powerOfThree(pos: pos + gap, gap: gap * 3, end: end)
      powerOfThree(pos: pos + 2 * gap, gap: gap * 3, end: end)

      var i = pos
      while i + gap < end {
        if engine.compare(i, i + gap, by: (>)) {
          engine.swap(i, i + gap)
        }
        i += gap
      }
    }

    // Ports `recursiveComb(array, pos, gap, end)`: recurse twice with `gap` doubled (at `pos`,
    // `pos + gap`), covering every power-of-2 multiple of `gap` first, then — only once both
    // return — fire `powerOfThree` at `gap` itself.
    func recursiveComb(pos: Int, gap: Int, end: Int) {
      guard pos + gap <= end else { return }

      recursiveComb(pos: pos, gap: gap * 2, end: end)
      recursiveComb(pos: pos + gap, gap: gap * 2, end: end)

      powerOfThree(pos: pos, gap: gap, end: end)
    }

    recursiveComb(pos: 0, gap: 1, end: engine.count)
  }
}
