import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.hybrid.IntroCircleSortIterative` — the same
/// `IterativeCircleSorting.circleSortRoutine` core `CircleSortIterative.swift` already ports
/// (reused verbatim below as a nested function), but driven by an "introspective" outer loop that
/// caps how many full circle-sort passes it is willing to attempt before giving up and finishing
/// with one full binary insertion sort pass instead.
///
/// The pass budget (`threshold`) is derived exactly like ArrayV's `runSort`: starting from `n = 1`,
/// double `n` and count the doubling (`threshold`) until `n` reaches or exceeds `end` (the real
/// array length), then halve `threshold` (integer division). ArrayV's driver is a `do { ... }
/// while (...)` loop — Swift's `repeat { ... } while` is the exact same construct, so the
/// translation below keeps its shape 1:1: each iteration increments `iterations` first and checks
/// it against `threshold` *before* attempting another circle-sort pass; only if that check doesn't
/// trip does the loop actually call `circleSortRoutine` and use its return value (zero swaps vs.
/// not) as the `while` condition. Concretely, for this app's `sizeRange` (16...256) `threshold` is
/// always >= 2, so at least one real circle-sort pass always runs before the fallback can trigger;
/// an already-sorted array converges in that first pass with zero swaps and the fallback never
/// fires at all (matching `CircleSortIterative`'s own one-pass best case).
///
/// **Why this exists / what "introspective" buys you:** plain `CircleSortIterative` just keeps
/// calling `circleSortRoutine` "however many times it takes" until a pass reports zero swaps, with
/// no cap. That repeat-until-stable behavior is *conjectured* to converge within roughly `O(log n)`
/// passes for ordinary inputs (hence `CircleSortIterative`'s declared `O(n log^2 n)` worst case),
/// but nothing about the routine itself guarantees that bound for every possible permutation —
/// there's no proof it can't occasionally need far more passes on some adversarial input. This
/// variant refuses to gamble on that: it budgets only `threshold` passes (a fixed, cheap-to-compute
/// function of `n` alone, independent of how the data actually behaves) and, the moment that budget
/// is exhausted without the array reporting fully sorted, abandons circle-sort passes entirely in
/// favor of one whole binary-insertion-sort pass — an algorithm with a rock-solid, well-understood
/// `O(n^2)` worst case. That fallback is the actual worst-case *guarantee* this port makes: however
/// badly a pathological input might behave under circle-sort's folding comparisons, the total work
/// is still bounded by `threshold` capped-cost passes plus one `O(n^2)` insertion pass — it can
/// never spiral past that the way an unbounded repeat-until-stable loop theoretically could.
///
/// **Stability: `false` — same verdict as plain `CircleSortIterative`, and the fallback does not
/// rescue it.** `CircleSortIterative` is unstable because `circleSortRoutine`'s fold-inward
/// compare-and-swap can reorder two equal-valued elements relative to each other purely as a side
/// effect of each one separately being swapped against some third, unequal element in a different
/// window/gap — no swap ever needs to directly compare the two equal elements for their relative
/// order to end up flipped. That same routine is reused here unchanged, so it carries the same risk
/// on every real pass this driver runs, whether or not the fallback ends up firing afterward:
///   - If the very first pass already returns zero swaps (the best case — nothing to fix), no
///     reordering ever happened and no fallback runs.
///   - Otherwise, every pass actually executed before the budget runs out is a *real*, fully
///     applied circle-sort pass — its swaps are not speculative or rolled back if the driver later
///     decides to abandon further circle-sort passes. Any duplicate-value reordering a pass caused
///     is already permanently baked into the array by the time the driver gives up on more passes.
///   - The binary-insertion fallback (inlined below, matching `BinaryInsertionSort.swift`'s own
///     `record(into:)` with `start` fixed at `0`) is, on its own, stable: its binary search never
///     moves an already-placed element past an equal one (ties resolve toward "insert to the
///     right"), and its shift-by-adjacent-swap loop only displaces elements strictly greater than
///     the one being inserted. But a stable *second* stage cannot retroactively undo disordering a
///     non-stable *first* stage already committed — the composition of "possibly-unstable passes,
///     then a stable pass" is only as stable as its least stable stage. Verified empirically in
///     `NativeAlgorithmCorrectnessTests` with tagged-duplicate input (an original-index tag tracked
///     independently of each element's compared value, via replaying the recorded swap tape onto a
///     parallel identity array): equal-valued tags come out reordered relative to their original
///     input order, so this is NOT a stable sort.
public struct IntroCircleSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "introcirclesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Intro Circle (Iterative)",
    category: .hybrid,
    sizeRange: 16...256,
    stable: false,
    // Best/average mirror `CircleSortIterative`: a single full pass is always `O(n log n)`
    // work regardless of whether it ends up finding any swaps, and typical inputs still tend to
    // converge (or hit the fallback) within a small number of such passes, so the average case
    // stays in the same `O(n log^2 n)` family plain circle sort documents. The worst case is
    // where this variant actually differs from `CircleSortIterative`: rather than an unbounded
    // (if conjectured-log-n) number of `O(n log n)` passes, it is hard-capped at `threshold`
    // passes and then falls back to a full binary insertion sort — whose own `O(n^2)` shift
    // step dominates the bounded `O(n log^2 n)` circle-sort budget for large `n`. That `O(n^2)`
    // is a strictly *guaranteed* ceiling this variant introduces on top of (not instead of)
    // circle sort's own typical behavior — see the doc comment above.
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log^2 n)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.down.right.and.arrow.up.left"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    // Same padded-power-of-two `n` as `CircleSortIterative` — every real array access below
    // stays separately guarded against `end`, so `n` only ever controls how many gap/start
    // window combinations get iterated over, never an actual out-of-range read or write.
    var n = 1
    var threshold = 0
    while n < end {
      n <<= 1
      threshold += 1
    }
    threshold /= 2

    // Verbatim `IterativeCircleSorting.circleSortRoutine` translation (see
    // `CircleSortIterative.swift`): for each shrinking `gap`, slide a window of size `2 * gap`
    // across the padded conceptual array, and within each window walk `low`/`high` inward from
    // its ends toward its center.
    func circleSortRoutine(_ length: Int) -> Int {
      var swapCount = 0
      var gap = length / 2
      while gap > 0 {
        var start = 0
        while start + gap < end {
          var low = start
          var high = start + 2 * gap - 1
          while low < high {
            if high < end {
              if engine.compare(low, high, by: (>)) {
                engine.swap(low, high)
                swapCount += 1
              }
            }
            low += 1
            high -= 1
          }
          start += 2 * gap
        }
        gap /= 2
      }
      return swapCount
    }

    // The "introspective" driver: ArrayV's `do { iterations++; if (iterations >= threshold) {
    // ...; break; } } while (circleSortRoutine(...) != 0)`, translated 1:1 via Swift's
    // `repeat`/`while` (the same do-while shape) rather than reordered into some equivalent
    // `while`/`for` loop — keeping the exact iteration-count-checked-before-next-pass ordering
    // matters for getting the off-by-one behavior right (see the doc comment above for the
    // hand-traced threshold values this produces).
    var iterations = 0
    repeat {
      iterations += 1
      if iterations >= threshold {
        // Fallback: one full binary insertion sort pass over the whole array, exactly
        // `BinaryInsertionSort.swift`'s own `record(into:)` with `start` fixed at `0`
        // (ArrayV calls `customBinaryInsert(array, 0, length, sleep)` here) — inlined rather
        // than calling into another algorithm's `SortAlgorithm` conformance, matching how
        // e.g. `WeavedMergeSort.swift` inlines its own merge/shift logic instead of
        // cross-importing a sibling algorithm struct (no precedent in this codebase for one
        // algorithm invoking another).
        for i in 1..<end {
          var lo = 0
          var hi = i
          while lo < hi {
            let mid = lo + (hi - lo) / 2
            if engine.compare(i, mid, by: <) {
              hi = mid
            } else {
              lo = mid + 1
            }
          }
          var j = i
          while j > lo {
            engine.swap(j, j - 1)
            j -= 1
          }
        }
        break
      }
    } while circleSortRoutine(n) != 0
  }
}
