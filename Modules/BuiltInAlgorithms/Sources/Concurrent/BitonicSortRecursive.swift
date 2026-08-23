import AlgorithmKit
import SortEngineKit

/// ArrayV's `BitonicSortRecursive` — H.W. Lang's generalized recursive Bitonic Sort. Unlike
/// ``BitonicSortIterative``, which pads to the next power of two, ``bitonicMerge`` here splits its
/// range at `m = greatestPowerOfTwoLessThan(n)` (not `n / 2`) and only compares `i` against `i + m`
/// for the first `n - m` positions, which generalizes correctly to any `n`.
///
/// ``compare`` implements `if (dir == (cmp == 1)) swap(...)`: ascending (`dir == true`) swaps only
/// on strict `>`, descending swaps on `<=` including ties. This asymmetry is real ArrayV behavior,
/// not a bug.
public struct BitonicSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bitonicsortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "Bitonic Sort (Recursive)",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 940, coefficients: [239944, 372.102, 0.0905988],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [11.119, 1.45774], rSquared: 0.996688),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(log^2 n)", average: "O(log^2 n)", worst: "O(log^2 n)"),
    // Unlike BitonicSortIterative's stated O(n log^2 n), this recursive formulation allocates
    // no auxiliary array at all — every comparison/swap happens directly on the live array —
    // so the only real memory cost is recursion-stack depth, which is O(log n).
    spaceComplexity: "O(log n)",
    iconName: "arrow.up.and.down.righttriangle.up.righttriangle.down"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    bitonicSort(&engine, 0, n, true)
  }

  private func greatestPowerOfTwoLessThan(_ n: Int) -> Int {
    var k = 1
    while k < n {
      k <<= 1
    }
    return k >> 1
  }

  private func compare(_ engine: inout RecordingEngine, _ i: Int, _ j: Int, _ dir: Bool) {
    let isGreater = engine.compare(i, j, by: (>))
    if dir == isGreater {
      engine.swap(i, j)
    }
  }

  private func bitonicMerge(_ engine: inout RecordingEngine, _ lo: Int, _ n: Int, _ dir: Bool) {
    guard n > 1 else { return }
    let m = greatestPowerOfTwoLessThan(n)
    for i in lo..<(lo + n - m) {
      compare(&engine, i, i + m, dir)
    }
    bitonicMerge(&engine, lo, m, dir)
    bitonicMerge(&engine, lo + m, n - m, dir)
  }

  private func bitonicSort(_ engine: inout RecordingEngine, _ lo: Int, _ n: Int, _ dir: Bool) {
    guard n > 1 else { return }
    let m = n / 2
    bitonicSort(&engine, lo, m, !dir)
    bitonicSort(&engine, lo + m, n - m, dir)
    bitonicMerge(&engine, lo, n, dir)
  }
}
