import AlgorithmKit
import SortEngineKit

/// A sorting network whose comparator pattern reads like a sheet of paper being folded (creased)
/// down repeatedly: every pass first compares every adjacent pair (`i`, `i+1`), then a second inner
/// loop compares pairs at a shrinking "crease" distance `j` (starting from the largest power of two
/// under the array length, halving down to some floor `next`), before `next` itself halves and the
/// whole thing repeats. Unlike `WeaveSort*`/`FoldSort`/`PairwiseMergeSort*`, every loop bound here
/// is the real array length directly (`length`) rather than a padded power-of-two size with a
/// bounds-checked comparator — there's no virtual padding to skip past.
///
/// `O(n log^2 n)` comparators — confirmed empirically (the ratio of measured comparisons to
/// `n log^2 n` converges to a near-constant ~0.27–0.31 across sizes 16 through 2048, identical to
/// `WeaveSortIterative`'s own measured counts at every tested size despite the very different loop
/// structure here). Although each comparator swaps only on strict `>`, long-range swaps can
/// reverse equal elements. Identity-tracking duplicate trials confirm the network is unstable.
public struct CreaseSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "creasesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Crease Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 936, coefficients: [224685, 338.638, 0.071557],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [5.74241, 1.26455], rSquared: 0.996774),
    implementationComplexity: 9,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "line.diagonal"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let length = engine.count
    guard length > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      let shouldSwap = engine.compare(a, b, by: >)
      engine.annotateLastOperation(
        stageID: "compareExchange", decisionID: "creasesort.networkComparator",
        outcome: shouldSwap ? "exchange" : "keep",
        roles: ["left": .arrayIndex(a), "right": .arrayIndex(b)],
        explanationKey: "creasesort.compareExchange",
        explanation: shouldSwap
          ? "The left value exceeds the right value, so this comparator exchanges them."
          : "These values satisfy this comparator, so they stay in place.")
      if shouldSwap {
        engine.swap(a, b)
      }
    }

    var maxGap = 1
    while maxGap * 2 < length { maxGap *= 2 }

    var next = maxGap
    while next > 0 {
      var i = 0
      while i + 1 < length {
        compSwap(i, i + 1)
        i += 2
      }

      var j = maxGap
      while j >= next, j > 1 {
        var k = 1
        while k + j - 1 < length {
          compSwap(k, k + j - 1)
          k += 2
        }
        j /= 2
      }

      next /= 2
    }
  }
}
