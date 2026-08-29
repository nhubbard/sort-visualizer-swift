import AlgorithmKit
import SortEngineKit

/// ArrayV's pairwise sorting network — like `BoseNelsonSortIterative`/`BitonicSortIterative`, the
/// sequence of compared index pairs is fixed by `length` alone, not the data. Unlike those two, it
/// works directly on any `length`: no next-power-of-two padding, since every index the loop bounds
/// touch is already `< length` by construction.
///
/// Two back-to-back phases: phase 1 doubles a block size `a` (1, 2, 4, ...), comparing each block
/// against the next (the network's merge phase); phase 2 shrinks `a` back down while a growing
/// offset count `e` runs the extra fixup comparisons a pairwise network needs beyond a simple
/// doubling merge to finish sorting.
///
/// Stable: `false` — elements never directly compared can still be transposed indirectly through a
/// shared swap partner. Complexity is `O(n log^2 n)` for best/average/worst alike, since the
/// comparator sequence is fixed regardless of input values.
public struct PairwiseSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pairwisesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Iterative Pairwise Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1018, coefficients: [222310, 294.667, 0.0483229],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [7.62654, 1.20495], rSquared: 0.999518),
    implementationComplexity: 11,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "square.grid.3x3.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let length = engine.count
    guard length > 1 else { return }

    // Phase 1: `a` (the "gap"/block size) doubles from 1 while it stays below `length`.
    var a = 1
    while a < length {
      var b = a
      var c = 0
      while b < length {
        if engine.compare(b - a, b, by: (>)) {
          engine.swap(b - a, b)
        }
        c = (c + 1) % a
        b += 1
        if c == 0 {
          b += a
        }
      }
      a *= 2
    }

    // Phase 2: cleanup passes with `a` halving down from the phase-1 exit value divided by 4,
    // and a nested `d` (starting at `e`, halving down to 0 each round) selecting the stride
    // `d * a` compared against. `e` grows as `e = e*2 + 1` every outer round.
    a /= 4
    var e = 1
    while a > 0 {
      var d = e
      while d > 0 {
        var b = (d + 1) * a
        var c = 0
        while b < length {
          if engine.compare(b - (d * a), b, by: (>)) {
            engine.swap(b - (d * a), b)
          }
          c = (c + 1) % a
          b += 1
          if c == 0 {
            b += a
          }
        }
        d /= 2
      }
      a /= 2
      e = (e * 2) + 1
    }
  }
}
