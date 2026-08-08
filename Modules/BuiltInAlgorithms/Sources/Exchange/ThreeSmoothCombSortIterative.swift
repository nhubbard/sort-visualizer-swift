import AlgorithmKit
import Foundation
import SortEngineKit

/// ArrayV's `ThreeSmoothCombSortIterative` — a sibling of `ClassicThreeSmoothCombSort` and
/// `ThreeSmoothCombSortRecursive`; all three run Shellsort over V. Pratt's 3-smooth gap sequence
/// (every gap `2^a * 3^b` below `length`, one compare-and-swap pass each) — a fixed,
/// data-independent sorting network, not an adaptive scheme like `CombSort`.
///
/// This variant generates the gap set via nested exponent loops rather than a smoothness test:
/// `pow2` is the largest `k` with `2^k <= length - 1`; for each `k` descending, `pow3` is the
/// largest `j` with `2^k * 3^j < length` (via log-arithmetic mirroring ArrayV's Java exactly); for
/// each `j` descending, `gap = 2^k * 3^j` gets one pass. This is an outer-`k`/inner-`j`-descending
/// walk, so gaps are NOT visited in strict numeric descending order (e.g. gap 2 before gap 3) —
/// harmless, since Pratt's theorem only requires each 3-smooth gap be touched once, not in a
/// particular order.
///
/// Stability: `false` — a gap > 1 pass can swap two elements past an equal-valued element between
/// them, with no later pass guaranteed to fix the crossing. Confirmed via tagged-value fuzzing.
///
/// Complexity: `Θ(n log^2 n)` in every case — `Θ(log^2 n)` distinct gaps, each an `Θ(n)` pass,
/// fixed by `length` alone. Space is `O(1)`: scalar loop variables only, no recursion.
public struct ThreeSmoothCombSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "threesmoothcombsortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "3-Smooth Comb Sort (Iterative)",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 959, coefficients: [224607, 317.145, 0.0559625],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "3.circle.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // Java's `(int)` cast on a non-negative `Double` truncates toward zero, the same as
    // Swift's `Int(_:)` on a `Double` — so this mirrors `Math.log`/`Math.pow` arithmetic from
    // ArrayV's source line-by-line rather than reaching for an integer-only reformulation.
    let pow2 = Int(log(Double(n - 1)) / log(2.0))

    for k in stride(from: pow2, through: 0, by: -1) {
      let pow3 = Int((log(Double(n)) - Double(k) * log(2.0)) / log(3.0))

      for j in stride(from: pow3, through: 0, by: -1) {
        let gap = Int(pow(2.0, Double(k)) * pow(3.0, Double(j)))

        var i = 0
        while i + gap < n {
          if engine.compare(i, i + gap, by: (>)) {
            engine.swap(i, i + gap)
          }
          i += 1
        }
      }
    }
  }
}
