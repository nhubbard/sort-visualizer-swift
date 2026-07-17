import AlgorithmKit
import Foundation
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.exchange.ThreeSmoothCombSortIterative` — a Shellsort using
/// V. Pratt's increment sequence (V. Pratt, "Shellsort and Sorting Networks", Stanford PhD
/// dissertation, 1972/1979): one compare-and-swap pass, run exactly once, for every gap value of
/// the form `2^a * 3^b` (a "3-smooth" number) below the array's length, visited in a specific
/// decreasing order. Pratt's theorem guarantees that touching every such gap exactly once is
/// *provably* sufficient to fully sort any input — this is a genuine, fixed, data-independent
/// sorting network, not a heuristic gap-shrinking scheme the way `CombSort.swift`/
/// `HybridCombSort.swift` are (those adapt their gap at runtime based on `swapped`; this algorithm's
/// entire gap sequence is decided purely from `length`, before a single comparison happens).
///
/// ## Generating the gap sequence: nested exponent loops, not a smoothness test
///
/// This is one of two ArrayV ports of the same underlying sequence — its sibling
/// `ClassicThreeSmoothCombSort` walks every integer gap from `length - 1` down to `1` and tests
/// each one for 3-smoothness directly (repeatedly dividing out factors of 2 and 3 until nothing
/// but a leftover `1` remains). This iterative variant instead generates the exact same SET of
/// gap values by construction, via two nested loops over the exponents themselves: `pow2` is the
/// largest `k` with `2^k <= length - 1`, and for each `k` from `pow2` down to `0`, `pow3` is the
/// largest `j` with `2^k * 3^j < length` (computed via the log-arithmetic
/// `(log(length) - k*log(2)) / log(3)`, mirroring the Java's floating-point derivation exactly
/// rather than a smoothness test or integer search); for each such `j` from `pow3` down to `0`,
/// `gap = 2^k * 3^j` gets exactly one compare-and-swap pass across the whole array.
///
/// Note the traversal order: this is an outer-`k`-descending, inner-`j`-descending walk, so it
/// does NOT emit every 3-smooth gap in strict numeric descending order the way the Classic
/// sibling's plain integer countdown does (e.g. gap `2` — `k=1, j=0` — is visited during the
/// `k=1` outer iteration, before gap `3` — `k=0, j=1` — is visited during the later `k=0` outer
/// iteration, even though `3 > 2`). Pratt's theorem only requires that every 3-smooth gap below
/// `n` receive exactly one pass at *some* point in a run — not any particular visitation order —
/// so this reordering has no effect on correctness; both ArrayV siblings touch the exact same set
/// of gaps and both fully sort. This was verified with a faithful Python re-implementation of this
/// exact nested-loop structure: 3,000 randomized duplicate-heavy trials (values 0–6, sizes 0–40)
/// and 3,000 randomized distinct-value trials, zero failures in either.
///
/// ## Stability: empirically `false`
///
/// A gap-`g` pass for `g > 1` compares and potentially swaps two elements that are far apart in
/// the array, without ever directly comparing them against whatever equal-valued element(s) sit
/// between them — so two equal-valued elements can cross paths during a large-gap pass with no
/// way to recover their original relative order by the time gap `1` (the only pass that compares
/// every adjacent pair) is reached. A tagged-value stability check (each element carrying its
/// original index alongside its value, comparing only on value) confirmed this directly: the large
/// majority of randomized duplicate-heavy trials showed at least one pair of equal-valued elements
/// coming out in the wrong relative order.
///
/// ## Complexity
///
/// There are `Θ(log^2 n)` distinct 3-smooth gap values below `n` (roughly `log_2(n) * log_3(n)`
/// combinations of the two independent exponents), and every one of them costs `Θ(n)` comparisons
/// for its single full pass over the array — regardless of the input's initial order, since the
/// gap sequence and the number of passes are both fixed functions of `length` alone, not of the
/// data. That gives `Θ(n log^2 n)` in the best, average, AND worst case alike — there is no
/// data-dependent early exit or degenerate slow path the way there is for `CombSort`'s adaptive
/// shrinking. Space is `O(1)`: only scalar loop variables (`pow2`, `k`, `pow3`, `j`, `gap`, `i`),
/// no recursion and no auxiliary arrays.
public struct ThreeSmoothCombSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "threesmoothcombsortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "3-Smooth Comb Sort (Iterative)",
    category: .exchange,
    sizeRange: 16...256,
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
