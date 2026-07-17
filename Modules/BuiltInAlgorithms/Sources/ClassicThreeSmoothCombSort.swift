import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.exchange.ClassicThreeSmoothCombSort` — Shellsort driven by
/// Pratt's 3-smooth increment sequence, run as a fixed, data-independent sorting NETWORK rather
/// than an adaptive comb/shrink-factor heuristic.
///
/// ## What "3-smooth" means, and why the gap sequence is built from it
///
/// A positive integer is 3-smooth iff its only prime factors are 2 and 3 — i.e. it has the form
/// `2^a * 3^b` for some `a, b >= 0` (this includes `1`, the trivial `a = b = 0` case). `is3Smooth`
/// below tests this the same way ArrayV's Java does: repeatedly strip factors of 6, then 3, then
/// 2, and check whether anything other than `1` is left over. `runSort` walks every candidate gap
/// `g` from `length - 1` down to `1` and, for each one that survives `is3Smooth`, performs exactly
/// ONE compare-and-swap pass over the whole array at that gap (comparing `i - g` against `i`,
/// strictly greater, for `i` from `g` up to `length - 1`).
///
/// ## Why a single pass per gap is enough — Pratt's theorem
///
/// Ordinary Comb Sort (`CombSort.swift`) and Shell Sort with most other increment sequences need
/// to repeat passes at (or near) the same gap until nothing moves, because their sequences are
/// only empirically good heuristics. This algorithm is different: V. Pratt, in his 1972 Stanford
/// PhD dissertation *Shellsort and Sorting Networks*, proved that running exactly one
/// comparison-and-swap pass per gap value, for every gap of the form `2^a * 3^b` less than `n`, in
/// strictly decreasing order, down to a final pass at gap `1`, is *provably sufficient* to fully
/// sort any input of length `n` — regardless of what that input is. That is a genuine sorting
/// network result (the sequence of compare-swap operations is fixed ahead of time, independent of
/// the data), not a heuristic that merely tends to work, which is exactly why ArrayV's `runSort`
/// gets away with a single pass per surviving gap and no outer "did anything move" convergence
/// loop the way `CombSort`/`HybridCombSort` need. This port was additionally spot-checked with a
/// standalone reimplementation run across thousands of randomized trials (including heavily
/// duplicated values), all fully sorted, corroborating Pratt's guarantee empirically as well as
/// analytically.
///
/// ## Complexity: `Θ(n log^2 n)` in every case, not data-dependent
///
/// Because the gap sequence and the single-pass-per-gap structure are entirely fixed ahead of
/// time (a sorting network), the number of comparisons this algorithm performs never depends on
/// the input values at all — best, average, and worst case are identical. For each of the
/// `O(log n)` distinct powers of 2 not exceeding `n`, there are `O(log n)` distinct powers of 3
/// that keep the product below `n`, so there are `Θ(log^2 n)` distinct 3-smooth gaps below `n` in
/// total; each selected gap's single pass costs `Θ(n)` comparisons (an `i` from `g` to
/// `length - 1`). Multiplying gives the overall `Θ(n log^2 n)` bound. Space is `O(1)`: just the
/// `g`/`i` loop counters, no recursion and no auxiliary arrays.
///
/// ## Stability: empirically `false`
///
/// A gap-`g` pass for `g > 1` compares and swaps elements that are far apart in the array,
/// without ever directly comparing two elements that sit strictly between them at that gap — so
/// two equal-valued elements can each be moved by different gap passes and cross paths without
/// ever being compared against each other, exactly the same instability every other gap-based
/// exchange sort here (`CombSort`, `HybridCombSort`, `ShellSort`) already has. A tagged-value
/// stability check (each element's original index carried alongside its value, comparing only on
/// the untagged value) confirmed this directly: across thousands of randomized duplicate-heavy
/// trials, the large majority reordered at least one pair of equal-valued elements relative to
/// their original input order.
public struct ClassicThreeSmoothCombSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "classicthreesmoothcombsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Classic 3-Smooth Comb Sort",
    category: .exchange,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "point.3.filled.connected.trianglepath.dotted"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    let length = engine.count

    // `n = 2^a * 3^b` for some `a, b >= 0`, mirroring ArrayV's repeated-division structure
    // exactly: strip factors of 6, then 3, then 2, and check whether `1` is all that remains.
    func is3Smooth(_ n: Int) -> Bool {
      var n = n
      while n % 6 == 0 { n /= 6 }
      while n % 3 == 0 { n /= 3 }
      while n % 2 == 0 { n /= 2 }
      return n == 1
    }

    var g = length - 1
    while g > 0 {
      if is3Smooth(g) {
        var i = g
        while i < length {
          if engine.compare(i - g, i, by: (>)) {
            engine.swap(i - g, i)
          }
          i += 1
        }
      }
      g -= 1
    }
  }
}
