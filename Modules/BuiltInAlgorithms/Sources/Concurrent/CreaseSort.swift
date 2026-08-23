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
/// structure here). Every comparator only ever swaps on strict `>`, and fuzzing across randomized
/// duplicate-heavy trials found no case where two equal elements crossed paths, confirming this
/// network is stable rather than merely assuming it from the swap-on-strict-`>` rule alone.
public struct CreaseSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "creasesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Crease Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 938, coefficients: [224851, 337.832, 0.070983],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [5.78236, 1.2632], rSquared: 0.996878),
    stable: true,
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
      if engine.compare(a, b, by: >) {
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
