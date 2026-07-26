import AlgorithmKit
import SortEngineKit

/// ArrayV's `CircloidSort` — a purely recursive member of the "circle sort" family, alongside
/// ``CircleSortIterative`` and ``CircleSortRecursive``. Unlike those two, it works directly on the
/// real `[left, right]` range with no next-power-of-two padding and no asymmetric bounds guards.
///
/// `circlePass` recurses into both halves of `[left, right]` unconditionally, then runs `circle` on
/// the full range — a genuinely complete binary recursion, unlike ``CircleSortRecursive``'s
/// power-of-two-padded, asymmetrically-truncated tree. `runSort` repeats a full sweep until one
/// reports zero swaps.
///
/// Complexity: `O(n log n)` per sweep, and empirically `O(log n)` sweeps until convergence, giving
/// `O(n log^2 n)` average/worst (same as ``CircleSortRecursive``); best case is a single confirming
/// sweep, `O(n log n)`. Space: `O(log n)` recursion depth, no auxiliary array.
///
/// Stability: `false` — `circle` compares and swaps positions that can be arbitrarily far apart, so
/// two equal elements can each independently swap against a third element and end up reordered
/// relative to each other despite no single swap ever being triggered by a tie.
public struct CircloidSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "circloidsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Circloid Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 564, coefficients: [236497, 638.268, 0.28619],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(log n)",
    iconName: "smallcircle.circle.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }

    // Ports `circle(array, left, right)`: converges `a` up from `left` and `b` down from
    // `right`, swapping any out-of-order pair, and nudges `b` past the shared middle index
    // once `a == b` so an odd-length range's middle element is never compared against itself.
    func circle(_ left: Int, _ right: Int) -> Bool {
      var a = left
      var b = right
      var swapped = false
      while a < b {
        if engine.compare(a, b, by: (>)) {
          engine.swap(a, b)
          swapped = true
        }
        a += 1
        b -= 1
        if a == b {
          b += 1
        }
      }
      return swapped
    }

    // Ports `circlePass(array, left, right)`: recurse into both halves first, then run this
    // level's own `circle` pass, reporting whether anything swapped anywhere in the recursion.
    func circlePass(_ left: Int, _ right: Int) -> Bool {
      guard left < right else { return false }
      let mid = (left + right) / 2
      let l = circlePass(left, mid)
      let r = circlePass(mid + 1, right)
      return circle(left, right) || l || r
    }

    let lastIndex = engine.count - 1
    while circlePass(0, lastIndex) {}
  }
}
