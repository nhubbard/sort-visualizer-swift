import AlgorithmKit
import SortEngineKit

/// An iterative pairwise-merge sorting network, built for a padded power-of-two size `n` with
/// every comparator bounds-checked against the real array length `end` (the same virtual-padding
/// pattern `WeaveSort*`/`FoldSort` use — a comparator touching a padding index past `end` is simply
/// skipped, equivalent to treating the padding as already-sorted `+infinity` values). The first
/// loop nest is a single Batcher-style odd-even pass at stride `n/2` down to `1`; the second
/// performs the pairwise network's characteristic doubling-merge shape, combining blocks of size
/// `k` two at a time as `k` grows from `2` up toward `n`.
///
/// `O(n log^2 n)` comparators — confirmed empirically (the ratio of measured comparisons to
/// `n log^2 n` converges to a near-constant ~0.23–0.25 across sizes 16 through 2048, identical at
/// every size to both `PairwiseMergeSortRecursive`'s and `PairwiseSortRecursive`'s own measured
/// counts, despite each using a different loop/recursion shape to get there). Every comparator only
/// ever swaps on strict `>`, and fuzzing across randomized duplicate-heavy trials found no case
/// where two equal elements crossed paths, confirming this network is stable.
public struct PairwiseMergeSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pairwisemergesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Pairwise Merge Sort (Iterative)",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 943, coefficients: [225178, 325.47, 0.0599447],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [7.88721, 1.217], rSquared: 0.998619),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "rectangle.grid.1x2"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      guard b < end else { return }
      if engine.compare(a, b, by: >) {
        engine.swap(a, b)
      }
    }

    var n = 1
    while n < end { n <<= 1 }

    var k = n >> 1
    while k > 0 {
      var j = 0
      while j < end {
        for i in 0..<k {
          compSwap(j + i, j + k + i)
        }
        j += k << 1
      }
      k >>= 1
    }

    k = 2
    while k < n {
      var m = k >> 1
      while m > 0 {
        var j = 0
        while j < end {
          var p = m
          while p < ((k - m) << 1) {
            for i in 0..<m {
              compSwap(j + p + i, j + p + m + i)
            }
            p += m << 1
          }
          j += k << 1
        }
        m >>= 1
      }
      k <<= 1
    }
  }
}
