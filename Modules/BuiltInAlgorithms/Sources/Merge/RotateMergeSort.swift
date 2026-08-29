import AlgorithmKit
import SortEngineKit

/// ArrayV's `RotateMergeSort` — a genuine in-place merge (unlike `InPlaceMergeSort`'s
/// insertion-shifting), bottom-up like `BottomUpMergeSort` but with no O(n) temp buffer per merge.
/// Each merge finds the larger of the two runs, binary-searches its midpoint value into the other
/// run, then `rotate` (built from block-swaps) swaps the block between the two found midpoints
/// into correct order, recursing into the two sub-merges that rotation produces.
///
/// Stable because `binarySearch`'s left/right-biased comparison picks the leftmost or
/// leftmost-after-equal insertion point depending on which run the search value came from, so
/// equal elements never cross. Rotation is linear in the merged range, so the overall bound stays
/// `O(n log n)` despite being in-place — no quadratic degradation like `InPlaceMergeSort`.
public struct RotateMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "rotatemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Rotate Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1335, coefficients: [211292, 209.839, 0.0244619],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [5.73099, 1.18686], rSquared: 0.999043),
    implementationComplexity: 21,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    // No aux array is ever created; the only extra memory is the recursion stack.
    spaceComplexity: "O(1)",
    iconName: "arrow.clockwise"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    // Block-swaps the two equal-length adjacent ranges `[a, a+len)` and `[b, b+len)`, one
    // position at a time. Mirrors ArrayV's `multiSwap(array, a, b, len)`.
    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len {
        engine.swap(a + i, b + i)
      }
    }

    // Rotates the two adjacent blocks `[a, m)` and `[m, b)` so their relative order swaps,
    // without any auxiliary storage — repeatedly block-swapping the smaller of the two
    // remaining sides against an equal-length slice of the other, shrinking whichever side
    // was just fully consumed. Mirrors ArrayV's `rotate(array, a, m, b)`.
    func rotate(_ a: Int, _ m: Int, _ b: Int) {
      var a = a
      var m = m
      var b = b
      var l = m - a
      var r = b - m
      while l > 0 && r > 0 {
        if r < l {
          multiSwap(m - r, m, r)
          b -= r
          m -= r
          l -= r
        } else {
          multiSwap(a, m, l)
          a += l
          m += l
          r -= l
        }
      }
    }

    // Finds where the held `value` (read once, from outside `[a, b)`) inserts into sorted
    // `[a, b)`. `left` picks the bias: leftmost position (`<=`) vs leftmost-after-equal (`<`) —
    // which one `rotateMerge` uses depends on which run `value` came from, and is what keeps
    // the merge stable.
    func binarySearch(_ a: Int, _ b: Int, _ value: Int, _ left: Bool) -> Int {
      var a = a
      var b = b
      while a < b {
        let mid = a + (b - a) / 2
        let comp =
          left
          ? engine.compareValue(mid, against: value, by: (>=))
          : engine.compareValue(mid, against: value, by: (>))
        if comp {
          b = mid
        } else {
          a = mid + 1
        }
      }
      return a
    }

    // Merges the two adjacent sorted runs `[a, m)` and `[m, b)` in place via a single rotation,
    // then recurses into the two sub-merges that rotation produces. Mirrors ArrayV's
    // `rotateMerge(array, a, m, b)`.
    func rotateMerge(_ a: Int, _ m: Int, _ b: Int) {
      let m1: Int
      let m3: Int
      var m2: Int
      if m - a >= b - m {
        m1 = a + (m - a) / 2
        let value = engine.values[m1]
        m2 = binarySearch(m, b, value, true)
        m3 = m1 + (m2 - m)
      } else {
        m2 = m + (b - m) / 2
        let value = engine.values[m2]
        m1 = binarySearch(a, m, value, false)
        // Java's `m3 = (m2++)-(m-m1)` post-increment: `m3` is computed from `m2`'s value
        // *before* the increment, and only then does `m2` advance by one for use below.
        m3 = m2 - (m - m1)
        m2 += 1
      }
      rotate(m1, m, m2)

      if m2 - (m3 + 1) > 0 && b - m2 > 0 {
        rotateMerge(m3 + 1, m2, b)
      }
      if m1 - a > 0 && m3 - m1 > 0 {
        rotateMerge(a, m1, m3)
      }
    }

    // Bottom-up doubling pass over merge-width `j`, merging every adjacent pair of runs of that
    // width, with one trailing partial merge per pass if `b - a` isn't a multiple of `2*j`.
    // Mirrors ArrayV's `rotateMergeSort(array, a, b)`.
    func rotateMergeSort(_ a: Int, _ b: Int) {
      let len = b - a
      var j = 1
      while j < len {
        var i = a
        while i + 2 * j <= b {
          rotateMerge(i, i + j, i + 2 * j)
          i += 2 * j
        }
        if i + j < b {
          rotateMerge(i, i + j, b)
        }
        j *= 2
      }
    }

    rotateMergeSort(0, n)
  }
}
