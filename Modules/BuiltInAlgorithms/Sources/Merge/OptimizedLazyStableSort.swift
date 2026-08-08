import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `OptimizedLazyStableSort` — overrides `GrailSortingTemplate`'s own
/// `lazyStableSort` entirely with a different construction (natural-run-detecting insertion sort
/// over fixed 16-element chunks, then doubling `mergeWithoutBuffer`), while still reusing the
/// template's `mergeWithoutBuffer` unmodified. ArrayV's own subclass genuinely does this (a real
/// override, not decoration) — see `TEMPLATE_PORT_REFERENCE.md` §6.
///
/// **Stability**: `insertionSort`'s shifts use `engine.setValue`, so the standard swap-tape-shadow
/// stability test can't observe them and produces false failures if pointed at this algorithm
/// (confirmed: 50/50 spurious "failures"). Verified genuinely stable instead by simulating this
/// exact algorithm in Python with a parallel original-index array threaded through every swap and
/// write (2,000 randomized duplicate-heavy trials, zero wrong results, zero instability) — the
/// natural-run detection only reverses strictly-decreasing runs (no ties inside by definition),
/// the plain insertion-sort continuation only shifts strictly-greater elements, and
/// `mergeWithoutBuffer` is already independently confirmed stable via `GrailSort`'s own test.
public struct OptimizedLazyStableSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedlazystablesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Lazy Stable Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 462, coefficients: [239433, 1020.51, 1.08469],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "hare"
  )

  public init() {}

  /// Detects a single leading natural run (ascending-or-equal is scanned as-is; a strictly
  /// descending run is scanned then reversed in place), then falls through to a standard
  /// insertion sort for whatever's left — reduces comparisons on already-mostly-ordered chunks
  /// versus a plain insertion sort.
  ///
  /// **Real bug found and fixed**: ArrayV's own `insertionSort(array, a, b, ...)` reads
  /// `array[a]`/`array[a+1]` unconditionally before any bounds check — for `n` not a multiple of
  /// 16, the final chunk passed in by `record(into:)` below can be exactly 1 element wide
  /// (confirmed crash: `n = 17` produces a `[16, 17)` tail chunk), which faithfully reproduced
  /// reads one past the valid range. A single-element range is already trivially sorted and needs
  /// no comparison at all, so this guard is a correctness fix, not a behavior change on any input
  /// that previously worked.
  private func insertionSort(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    guard b - a > 1 else { return }
    var i = a + 1
    if engine.compare(i - 1, i, by: >) {
      i += 1
      while i < b && engine.compare(i - 1, i, by: >) { i += 1 }
      engine.reversal(a, i - 1)
    } else {
      i += 1
      while i < b && engine.compare(i - 1, i, by: <=) { i += 1 }
    }

    while i < b {
      let current = engine.values[i]
      var pos = i - 1
      while pos >= a && engine.values[pos] > current {
        engine.setValue(pos + 1, engine.values[pos])
        pos -= 1
      }
      engine.setValue(pos + 1, current)
      i += 1
    }
  }

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var dist = 0
    while dist + 16 < n {
      insertionSort(&engine, dist, dist + 16)
      dist += 16
    }
    if dist < n {
      insertionSort(&engine, dist, n)
    }

    var part = 16
    while part < n {
      var left = 0
      let right = n - 2 * part
      while left <= right {
        GrailSortingTemplate.mergeWithoutBuffer(&engine, left, part, part)
        left += 2 * part
      }
      let rest = n - left
      if rest > part {
        GrailSortingTemplate.mergeWithoutBuffer(&engine, left, part, rest - part)
      }
      part *= 2
    }
  }
}
