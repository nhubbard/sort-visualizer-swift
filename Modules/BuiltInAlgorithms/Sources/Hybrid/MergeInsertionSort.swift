import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `MergeInsertionSort` — the classic Ford-Johnson merge-insertion sort (this
/// implementation by `aphitorite`), entirely iterative and in-place: no aux array, no real
/// recursion (the algorithm's usual recursive formulation is unwound into a doubling
/// (`k *= 2`)/halving (`k /= 2`) loop pair). Self-contained — extends ArrayV's bare `Sort` base
/// class, not a shared template.
///
/// Every index throughout (`a`, `b`, `i`, `j`, `m`) names the *last* position of a size-`s` block,
/// not its first — a block of size `s` "ending at `p`" occupies `[p - s + 1, p]`. The first
/// doubling pass keeps each block internally sorted ascending by construction, so a block's own
/// maximum always sits at its end index — which is exactly why every later comparison only ever
/// looks at one representative index per block instead of the whole block.
///
/// `blockSwap` is the only primitive that writes (`blockInsert`/`blockReversal`/the doubling
/// pre-pass are all built purely from `blockSwap` calls), so every mutation in this whole
/// algorithm is a swap. It swaps the same *set* of index pairs ArrayV's own backward `while(s-- >
/// 0) swap(a--, b--)` loop does, just addressed forward from each block's start — a cosmetic
/// swap-order difference only, matching the same trade `QuadSortingTemplate` already accepted
/// for `engine.reversal` in place of a manual decrementing loop.
///
/// Two systematic translation decisions, both confirmed against precedent already in this
/// codebase rather than assumed: the doubling pre-pass's `Reads.compareValues(array[i-k],
/// array[i])` is a direct pairwise compare between two live, non-shifting positions, so it becomes
/// real `engine.compare(_:_:by:)` (matches `OptimizedStoogeSort`/`DualPivotQuickSort`/
/// `BottomUpMergeSort`'s identical shape). `blockSearch`'s `Reads.compareValues(val, array[m])` is
/// a binary-search-loop compare where `val` is captured once outside the loop while `m` moves —
/// this becomes a bare, uncounted `engine.values[...]` comparison, matching
/// `BlockSwapMergeSort.binarySearchMid`'s own identically-shaped search loop.
public struct MergeInsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "mergeinsertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Merge-Insertion",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 396, coefficients: [239715, 1171.01, 1.3603],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [1.02808, 1.76728], rSquared: 0.9987),
    // Confirmed empirically unstable (`mergeInsertionSortIsNotStable`), despite every individual
    // comparison using a strict inequality: the doubling pre-pass and `order`'s block-insert step
    // only ever compare two blocks' *representative* (end) elements, then swap the two blocks'
    // positions wholesale when out of order — it never merges their contents element-by-element.
    // Two equal values that end up in different blocks by the time their blocks are first compared
    // can have their whole blocks' relative order flipped by that single representative-only
    // comparison, carrying every other element of both blocks (including any tied values buried
    // inside them) along for the ride — this is also why the array isn't actually sorted at every
    // intermediate doubling level, only once both phases finish.
    stable: false,
    // No data-dependent short-circuit anywhere in the structure (every pass/index walk is fixed by
    // `length` alone, never skipped based on existing order), so best case doesn't drop below
    // O(n log n) the way e.g. an already-sorted fast path would.
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    // In-place: every mutation is a `blockSwap`, no aux array or recursion stack anywhere.
    spaceComplexity: "O(1)",
    iconName: "rectangle.stack.badge.plus"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let length = engine.count
    guard length > 1 else { return }

    // Swaps the two non-overlapping size-`s` blocks ending at `a` and `b` — `[a-s+1, a]` and
    // `[b-s+1, b]` — elementwise.
    func blockSwap(_ a: Int, _ b: Int, _ s: Int) {
      for i in 0..<s {
        engine.swap(a - s + 1 + i, b - s + 1 + i)
      }
    }

    // Walks the size-`s` block ending at `a` leftward one block-swap at a time until it reaches
    // `b` — repeated adjacent-block transposition, the block-granularity analogue of a single
    // insertion-sort shift.
    func blockInsert(_ a: Int, _ b: Int, _ s: Int) {
      var a = a
      while a - s >= b {
        blockSwap(a - s, a, s)
        a -= s
      }
    }

    // Reverses the sequence of size-`s` blocks in `[a, b)` via outside-in `blockSwap` calls.
    func blockReversal(_ a: Int, _ b: Int, _ s: Int) {
      var a = a
      var b = b - s
      while b > a {
        blockSwap(a, b, s)
        a += s
        b -= s
      }
    }

    // Block-aligned binary search for where `val` belongs among the size-`s` blocks in `[a, b)`,
    // comparing against each candidate block's representative (end) index.
    func blockSearch(_ a: Int, _ b: Int, _ s: Int, _ val: Int) -> Int {
      var a = a
      var b = b
      while a < b {
        let m = a + (((b - a) / s) / 2) * s
        if val < engine.values[m] {
          b = m
        } else {
          a = m + s
        }
      }
      return a
    }

    // Pairs up adjacent size-`s` blocks across `[a, b)` via `blockInsert`, then `blockReversal`s
    // the back half.
    func order(_ a: Int, _ b: Int, _ s: Int) {
      var i = a
      var j = i + s
      while j < b {
        blockInsert(j, i, s)
        i += s
        j += 2 * s
      }

      let m = a + (((b - a) / s) / 2) * s
      blockReversal(m, b, s)
    }

    // Phase 1: doubling pairwise compare-and-swap pre-pass, building the sorted "main chain"
    // bottom-up — after this, every size-`k` block (for whatever `k` the loop reaches) is
    // internally sorted ascending.
    var k = 1
    while 2 * k <= length {
      var i = 2 * k - 1
      while i < length {
        if engine.compare(i - k, i, by: >) {
          blockSwap(i - k, i, k)
        }
        i += 2 * k
      }
      k *= 2
    }

    // Phase 2: halving Jacobsthal-ordered insertion — `g`/`p` generate the classic Jacobsthal
    // difference sequence (1, 1, 2, 3, 5, 11, 21, ...) that orders how "pending" blocks are
    // merged into the main chain, which is what makes Ford-Johnson comparison-optimal.
    while k > 0 {
      let a = k - 1
      var i = a + 2 * k
      var g = 2
      var p = 4

      while i + 2 * k * g - k <= length {
        order(i, i + 2 * k * g - k, k)
        let b = a + k * (p - 1)

        i += k * g - k
        var j = i
        while j < i + k * g {
          blockInsert(j, blockSearch(a, b, k, engine.values[j]), k)
          j += k
        }

        i += k * g + k
        g = p - g
        p *= 2
      }
      while i < length {
        blockInsert(i, blockSearch(a, i, k, engine.values[i]), k)
        i += 2 * k
      }

      k /= 2
    }
  }
}
