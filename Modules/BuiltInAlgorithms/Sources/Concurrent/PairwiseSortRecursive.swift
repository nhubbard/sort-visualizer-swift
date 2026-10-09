import Foundation
import AlgorithmKit
import SortEngineKit

/// The recursive counterpart to `PairwiseSortIterative`, ported from a different (but
/// network-equivalent) construction than `PairwiseMergeSortRecursive` above — no power-of-two
/// padding here; `pairwiserecursive` instead threads an explicit `gap` through its own recursion,
/// operating directly on `[start, end)` at the real array's own length. Each call does one
/// comparator pass at stride `2*gap` starting from `start+gap`, then recurses twice at double the
/// gap — routing to one of two different `(start, end)` offset pairs depending on whether the
/// current span's element count is even or odd — before a closing pass of comparisons at
/// decreasing power-of-two multiples of `gap` (`c`, halved each iteration) reconciles elements
/// left out of alignment by the recursive splits.
///
/// `O(n log^2 n)` comparators — confirmed empirically (the ratio of measured comparisons to
/// `n log^2 n` converges to a near-constant ~0.23–0.25 across sizes 16 through 2048, identical at
/// every tested size to both `PairwiseMergeSortIterative`'s and `PairwiseMergeSortRecursive`'s own
/// measured counts, despite this being a structurally distinct construction from either). Every
/// comparator swaps only on strict `>`, but identity-tracking duplicate trials show that equal
/// elements can cross indirectly. This recursive network is unstable.
public struct PairwiseSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pairwisesortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Recursive Pairwise Sort", bundle: .module),
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1017, coefficients: [222465, 295.422, 0.0486679],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [7.58061, 1.20611], rSquared: 0.999485),
    implementationComplexity: 12,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(log n)",
    iconName: "square.grid.3x3"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      let shouldSwap = engine.compare(a, b, by: >)
      engine.annotateLastOperation(
        stageID: "compareExchange", decisionID: "pairwisesortrecursive.networkComparator",
        outcome: shouldSwap ? "exchange" : "keep",
        roles: ["left": .arrayIndex(a), "right": .arrayIndex(b)],
        explanationKey: "pairwisesortrecursive.compareExchange",
        explanation: shouldSwap
          ? String(localized: "The left value exceeds the right value, so this comparator exchanges them.", bundle: .module)
          : String(localized: "These values satisfy this comparator, so they stay in place.", bundle: .module))
      if shouldSwap {
        engine.swap(a, b)
      }
    }

    func pairwiserecursive(_ start: Int, _ end: Int, _ gap: Int) {
      guard start != end - gap else { return }

      var b = start + gap
      while b < end {
        compSwap(b - gap, b)
        b += 2 * gap
      }

      if ((end - start) / gap) % 2 == 0 {
        pairwiserecursive(start, end, gap * 2)
        pairwiserecursive(start + gap, end + gap, gap * 2)
      } else {
        pairwiserecursive(start, end + gap, gap * 2)
        pairwiserecursive(start + gap, end, gap * 2)
      }

      var a = 1
      while a < (end - start) / gap {
        a = a * 2 + 1
      }

      b = start + gap
      while b + gap < end {
        var c = a
        while c > 1 {
          c /= 2
          if b + c * gap < end {
            compSwap(b, b + c * gap)
          }
        }
        b += 2 * gap
      }
    }

    pairwiserecursive(0, n, 1)
  }
}
