import AlgorithmKit
import SortEngineKit

/// ArrayV's `StacklessHybridQuickSort` (aphitorite) — shares its outer shape exactly with the
/// already-shipped `StacklessDualPivotQuickSort` (same max-extraction pass, same `a`/`b1`/`med`
/// segment-walking loop, same `leftBinSearch` duplicate-skip, same borrowed-fixed-boundary trick),
/// but partitions each segment against a single median-of-three pivot with a classic Hoare
/// partition instead of a dual-pivot three-way split, and its insertion-sort cutoff is 16, not 24.
///
/// Two differences from the dual-pivot sibling worth calling out because they look like bugs but
/// are faithful to the source:
///
/// - `medianOfThree` gets called *twice* in a row when `med` is `true`: once explicitly in
///   `quickSort` right before calling `partition`, and again unconditionally as the very first
///   thing `partition` itself does. This isn't simplified away here — `medianOfThree` is not
///   idempotent in general (a second call on an already-processed range can still swap once more
///   in some cases), so calling it twice is a real, intentional part of this algorithm's exact
///   behavior, not redundant dead code to prune.
/// - There's no borrowed-scratch-slot rotation inside `partition` itself. Instead, `quickSort`
///   swaps the just-placed pivot at `p` out to the fixed boundary `b` right after `partition`
///   returns, then continues shrinking towards `p` (now the new `b1`). Same role as the dual-pivot
///   sibling's internal three-way rotation — moving the pivot to a safe fixed resting place outside
///   the region still being sorted — just implemented as a single caller-side swap instead of a
///   rotation inside the partition routine.
///
/// `partition`'s inner scan comparisons (`Reads.compareIndices(array, i, a, 0, false)`) pass
/// `mark=false` in the source — ArrayV suppresses the usual primary/secondary highlight there
/// because it's using its own marker-1/marker-2 position highlighting instead (`Highlights
/// .markArray(1, i)`/`.markArray(2, j)`, decoupled from any specific compared pair). The decoupled
/// position marks and the pivot highlight (marker 3) are omitted here for the same reason as the
/// dual-pivot sibling: no `Visualizer` in this app renders anything but `Marker.primary`/
/// `.secondary`, so recording them would be tape bloat with zero visible effect. The comparisons
/// themselves go through `engine.compareValue` against the held pivot (safe: `a` never moves
/// during the scan) — a real, tracked comparison per scan step, not `compare`'s usual two-index
/// mark pair, but no longer a raw untracked read either.
public struct StacklessHybridQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stacklesshybridquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stackless Hybrid Quick",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 703, coefficients: [239698, 643.587, 0.429216],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.429216, 40.1101, -621.54], rSquared: 0.999815),
    implementationComplexity: 40,
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
    // the source: no highlight, just a running value.
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
    // `true` means the next partition's median-of-three should run once more right before
    // partitioning, on top of the one `partition` always does internally.
    var med = true

    while true {
      while b1 - a > 16 {
        if med {
          medianOfThree(&engine, a, b1)
        }
        let p = partition(&engine, a, b1)
        engine.swap(p, b)
        b1 = p
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

  /// ArrayV's `medianOfThree(array, a, b)`: arranges `array[a]`, `array[m]`, `array[b-1]` (where
  /// `m` is the midpoint of the inclusive range `[a, b-1]`) so the median of the three ends up at
  /// `a`, ready to serve as `partition`'s pivot. Every comparison here is genuinely index-vs-index
  /// (mark=true in the source), so translated with `engine.compare`, unlike `partition`'s own
  /// held-value comparisons below.
  private func medianOfThree(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    let m = a + (b - 1 - a) / 2
    if engine.compare(a, m, by: (>)) {
      engine.swap(a, m)
    }
    if engine.compare(m, b - 1, by: (>)) {
      engine.swap(m, b - 1)
      if engine.compare(a, m, by: (>)) {
        return
      }
    }
    engine.swap(a, m)
  }

  /// ArrayV's `partition(array, a, b)`: a classic Hoare partition against the pivot
  /// `medianOfThree` just placed at `a`. Returns the pivot's final resting index.
  private func partition(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) -> Int {
    medianOfThree(&engine, a, b)

    // Held pivot value: `a` is never written again until the closing swap below (`i` only ever
    // grows past `a`, `j` only ever shrinks below `b`), so it's safe to hold this rather than
    // re-reading `engine.values[a]` on every scan step.
    let pivot = engine.values[a]
    var i = a
    var j = b

    while true {
      repeat {
        i += 1
      } while i < j && engine.compareValue(i, against: pivot, by: (<))
      repeat {
        j -= 1
      } while j >= i && engine.compareValue(j, against: pivot, by: (>=))

      if i < j {
        engine.swap(i, j)
      } else {
        engine.swap(a, j)
        return j
      }
    }
  }

  /// ArrayV's `leftBinSearch`: lower-bound search for where `p`'s value belongs among `[a, b)`,
  /// ties resolving left (`<=`). Identical to `StacklessDualPivotQuickSort`'s helper of the same
  /// name — both indices are live throughout, matching `Reads.compareIndices`.
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
  /// over `[start, end)`, used here as the base case once a range shrinks to 16 elements or fewer.
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
