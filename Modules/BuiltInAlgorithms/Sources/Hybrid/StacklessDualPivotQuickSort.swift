import AlgorithmKit
import SortEngineKit

/// ArrayV's `StacklessDualPivotQuickSort` (aphitorite) — a dual-pivot quicksort with no recursion
/// at all, hence the name: `record(into:)` makes exactly one top-level call into `quickSort`, which
/// drives the whole sort with a single `while true` loop instead of a call stack.
///
/// The shape: first, every element equal to the range's maximum gets shuffled to the end (the
/// `max`-extraction pass below) — those are already in final position relative to everything else,
/// so the rest of the algorithm never has to look at them again. Then a loop repeatedly shrinks and
/// processes the range `[a, b1)` immediately to its left: `partition` (median-of-three, three-way)
/// runs until the range is small enough (`<= 24`) for `binaryInsert`'s base case, then `a` jumps
/// past the just-finished segment via `leftBinSearch` locating how many elements starting at the new
/// `a` are duplicates of the pivot value just placed at `a - 1` (already correctly positioned,
/// skipped without re-comparing). This walks left-to-right across the whole array once, each
/// iteration handling the next unsorted segment — recursion's job, done with a loop and two cursors
/// (`a`, `b1`) instead of a stack.
///
/// `partition`'s own pivot arrangement is the reverse of the usual dual-pivot convention: after its
/// opening swaps, position `a` (not `b`) ends up holding the *larger* of the two median candidates,
/// and position `b` the *smaller* — not a bug, just how this source lays out its low/high regions.
/// Its closing three-way rotation borrows `p` — the fixed boundary between the currently-unsorted
/// region and the max-block carved out at the top of `quickSort` (or the true array end, on the very
/// first partition) — as scratch space for one element for the duration of a single `partition`
/// call, then restores it. `p` is passed down unchanged from `quickSort`'s outer `b` on every call,
/// across every segment processed by the surrounding loop.
///
/// ArrayV's source also calls `Highlights.markArray(3, j)`/`clearMark(3)` during `partition`'s
/// backward scan — a custom, algorithm-managed highlight distinct from the auto-applied
/// primary/secondary pair `compare`/`swap` already provide. Omitted here: every `Visualizer` in this
/// app colors strictly by `Marker.primary`/`.secondary` and ignores every other marker
/// (`MetalShapeColor.markerKind`), so recording it would add tape entries with no visible effect —
/// the same reasoning that already got `Marker.write`'s equally-dead `setValue` mark deleted
/// (`RecordingEngine.setValue` doesn't record one either).
public struct StacklessDualPivotQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stacklessdualpivotquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stackless Dual-Pivot Quick",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1348, coefficients: [239739, 337.138, 0.118075],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.118075, 18.8081, -168.367], rSquared: 0.999151),
    // Sample sizes straddle this algorithm's own insertion-sort cutoff (24) the same way
    // `OptimizedDualPivotQuickSort`'s calibration did: 4 samples (16-19) fall entirely below it,
    // where the whole range goes through one binary-insertion pass whose O(n) shift-per-insert
    // makes total operations scale closer to O(n^2); 4 samples (38-304) fall entirely above it,
    // where `partition` dominates and the shrinking-chunk insertion work stays O(n) overall.
    // Measured directly (not just accepted blindly): instrumented the validated reference
    // algorithm and confirmed ops/n peaks right at the cutoff (n=24-25) then falls as n grows
    // into the real partitioning regime — no single smooth 2-parameter curve fits both regimes
    // at once. Every sampled size still sorted correctly.
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    // No recursion at all — the whole point of this port's shape — so no call-stack space to
    // account for, unlike a typical quicksort's `O(log n)`.
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.up.slash"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    quickSort(&engine, 0, engine.count)
  }

  private func quickSort(_ engine: inout RecordingEngine, _ a0: Int, _ bIn: Int) {
    var b = bIn

    // Held-value scan for this range's maximum — `Reads.compareValues`, not `compareIndices`, in
    // the source: no highlight, just a running value, matching this codebase's convention of
    // reading `engine.values` directly (no `engine.compare` call) whenever the source compares a
    // held value rather than two live indices.
    var max = engine.values[a0]
    if a0 + 1 < b {
      for i in (a0 + 1)..<b where engine.values[i] > max {
        max = engine.values[i]
      }
    }

    // Move every copy of `max` within `[0, b)` to the end, shrinking `b` past them. Scans down to
    // 0, not `a0`, matching the source exactly — harmless here since `quickSort` is only ever
    // called once, with `a0 == 0`.
    var i = b - 1
    while i >= 0 {
      if engine.values[i] == max {
        b -= 1
        engine.swap(i, b)
      }
      i -= 1
    }

    var a = a0
    var b1 = b
    // "Flag to improve pivot selection in the case of many similar elements" (source comment):
    // `false` right after a duplicate run got skipped means the next partition's median-of-three
    // should first swap in a fresh third candidate, since the two elements it would otherwise reuse
    // (from the just-finished segment's boundary) are already known duplicates of each other.
    var med = true

    while true {
      while b1 - a > 24 {
        if !med {
          engine.swap(a, (a + a + b1) / 3)
        }
        b1 = partition(&engine, a, b1, b)
      }
      binaryInsert(&engine, a, b1)

      a = b1 + 1
      if a >= b {
        if a - 1 < b {
          engine.swap(a - 1, b)
        }
        return
      }

      b1 = leftBinSearch(&engine, a, b, a - 1)
      engine.swap(a - 1, b)

      med = true
      while a < b1 && engine.compare(a - 1, a, by: (==)) {
        med = false
        a += 1
      }
      if a == b1 { med = true }
    }
  }

  /// ArrayV's `partition(array, a, b, p)`: median-of-three dual-pivot partitioning of `[a, b)`
  /// against the two chosen medians, plus a closing three-way rotation that plants the correct
  /// pivot at the returned boundary while borrowing `p` as scratch (see the type-level doc comment).
  private func partition(_ engine: inout RecordingEngine, _ a: Int, _ bIn: Int, _ p: Int) -> Int {
    var b = bIn
    let m1 = (a + a + b) / 3
    let m2 = (a + b + b) / 3

    if engine.compare(m1, m2, by: (>)) {
      engine.swap(m1, a)
      b -= 1
      engine.swap(m2, b)
    } else {
      engine.swap(m2, a)
      b -= 1
      engine.swap(m1, b)
    }

    var i = a
    var j = b

    // Held pivot values: `a`/`b` never move again until the closing rotation below, so it's safe
    // to snapshot them now rather than re-reading `engine.values[a]`/`[b]` on every loop iteration.
    // Reversed from the usual low/high naming — see the type-level doc comment — `pivotHigh` (at
    // `a`) is the *larger* of the two medians, `pivotLow` (at `b`) the *smaller*.
    let pivotHigh = engine.values[a]
    let pivotLow = engine.values[b]

    var k = i + 1
    while k < j {
      if engine.compareValue(k, against: pivotLow, by: (<)) {
        i += 1
        engine.swap(k, i)
      } else if engine.compareValue(k, against: pivotHigh, by: (>=)) {
        repeat {
          j -= 1
        } while j > k && engine.compareValue(j, against: pivotHigh, by: (>=))
        engine.swap(k, j)

        if engine.compareValue(k, against: pivotLow, by: (<)) {
          i += 1
          engine.swap(k, i)
        }
      }
      k += 1
    }

    engine.swap(a, i)
    // Three-way rotation `b <- j <- p <- b`, held-value order matching the source exactly: `t`
    // captures `b`'s value before anything else writes, and every subsequent read's source index
    // hasn't been touched yet by an earlier write in this same sequence.
    let t = engine.values[b]
    engine.setValue(b, engine.values[j])
    engine.setValue(j, engine.values[p])
    engine.setValue(p, t)

    return i
  }

  /// ArrayV's `leftBinSearch`: lower-bound search for where `p`'s value belongs among `[a, b)`,
  /// ties resolving left (`<=`). Both arguments are live indices throughout, matching
  /// `Reads.compareIndices` — unlike `partition`'s held-value comparisons above.
  private func leftBinSearch(_ engine: inout RecordingEngine, _ aIn: Int, _ bIn: Int, _ p: Int) -> Int {
    var a = aIn
    var b = bIn
    while a < b {
      let m = a + (b - a) / 2
      if engine.compare(p, m, by: (<=)) {
        b = m
      } else {
        a = m + 1
      }
    }
    return a
  }

  /// ArrayV's `BinaryInsertionSort.customBinaryInsert`: a held-value binary-search insertion sort
  /// over `[start, end)`, used here as the base case once a range shrinks to 24 elements or fewer.
  /// Strict `<` in the search (not `<=`) keeps ties resolving right, preserving stability within
  /// this base case — moot for the algorithm's overall stability claim, since the surrounding
  /// partition already isn't stable, but faithful to the source regardless.
  private func binaryInsert(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard start < end else { return }
    for i in start..<end {
      let num = engine.values[i]
      var lo = start
      var hi = i
      while lo < hi {
        let mid = lo + (hi - lo) / 2
        if engine.compareValue(mid, against: num, by: (>)) {
          hi = mid
        } else {
          lo = mid + 1
        }
      }
      var j = i - 1
      while j >= lo {
        engine.setValue(j + 1, engine.values[j])
        j -= 1
      }
      engine.setValue(lo, num)
    }
  }
}
