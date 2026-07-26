import AlgorithmKit
import SortEngineKit

/// ArrayV's `UnoptimizedCocktailShakerSort` — the same bidirectional bubble-sweep shape as
/// `CocktailShakerSort` and `OptimizedCocktailShakerSort`, but with both siblings' adaptive
/// optimizations removed: no swap-tracking flag, no early `break`, no shrinking no-swap counters.
/// The outer loop always runs `n / 2` times, each pass scanning the fixed range `[i, n - i - 1)`
/// forward and `(i, n - i - 1]` backward.
///
/// Complexity: `Θ(n^2)` in every case, including best — unlike its siblings, which detect an
/// already-sorted input on the first pass for an `O(n)` best case, this variant has no mechanism
/// to short-circuit. Space is `O(1)`.
///
/// Stability: `true` — both sweeps use strict comparisons (`>` forward, `<` backward), so ties
/// never swap, matching both siblings.
public struct UnoptimizedCocktailShakerSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "unoptimizedcocktailshakersort")
  public let metadata = AlgorithmMetadata(
    displayName: "Unoptimized Cocktail Shaker Sort",
    category: .exchange,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.left.arrow.right.square"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // Fixed `n / 2` outer passes, no swap-tracking flag — nothing can ever break out early.
    var i = 0
    while i < n / 2 {
      // Forward sweep over the fixed range [i, n - i - 1), carrying larger values rightward.
      // Strict `>` (not the default `>=`) is what keeps this stable: a tie never swaps, so
      // equal-valued elements never cross past each other.
      var j = i
      while j < n - i - 1 {
        if engine.compare(j, j + 1, by: (>)) {
          engine.swap(j, j + 1)
        }
        j += 1
      }

      // Backward sweep over the fixed range (i, n - i - 1], carrying smaller values leftward.
      // Strict `<` mirrors the forward sweep's strict `>` for the same stability reason.
      j = n - i - 1
      while j > i {
        if engine.compare(j, j - 1, by: (<)) {
          engine.swap(j, j - 1)
        }
        j -= 1
      }

      i += 1
    }
  }
}
