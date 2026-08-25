import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `LaziestSort` (`aphitorite`'s "Laziest Stable Sort") — a genuinely
/// in-place stable merge: `sqrt(n)`-sized blocks are binary-insertion-sorted first, then merged
/// one block at a time into the growing already-merged suffix via rotations instead of an
/// auxiliary buffer, using exponential (galloping) search to find each rotation's boundary in
/// `O(log(run length))` rather than a linear scan.
///
/// `rotate` is not re-derived here — it's exactly `GrailSortingTemplate.rotate(pos:lenA:lenB:)`'s
/// own multi-swap block rotation (`rotate(array, a, m, b)`'s `l`/`r`-shrinking loop is the
/// identical algorithm to `rotate(pos, lenA, lenB)`'s, just parameterized by endpoints instead of
/// lengths: `pos = a`, `lenA = m - a`, `lenB = b - m`), already fuzzed via 4 real algorithms in
/// this codebase's Grail cluster.
///
/// Two systematic translation decisions: `insertTo`/`binaryInsertion`'s comparisons are all
/// against a value captured once per outer iteration (bare, uncounted — same convention as every
/// other held-value binary search in this codebase, e.g. `MergeInsertionSort.blockSearch`);
/// `inPlaceMerge`'s own `array[i]` vs. `array[j]` comparison is between two live, independently-
/// marching positions, so it becomes a real `engine.compare`.
///
/// `stable: true` — matches ArrayV's own "Laziest **Stable** Sort" name, and both tie-breaking
/// rules confirm it: `binaryInsertion` uses `rightBinSearch` (`<`, never `<=`), which places a
/// new element after every existing equal one; `inPlaceMerge` only rotates elements out of the
/// left run when the left element is *strictly* greater than the right one, so a tie always just
/// advances `i`, leaving both elements exactly where a stable merge would. Every write is a mix
/// of `setValue` (`insertTo`'s shifts) and real swaps (`rotate`'s `multiSwap`), so — like the
/// other mixed-primitive hybrids in this codebase — the swap-tape-shadow-replay empirical check
/// doesn't apply; this is a by-construction argument instead.
///
/// Time/space bounds mirror the Grail cluster's own rotation-based in-place merges (same
/// amortized-rotation-cost argument, not independently re-derived): `O(n log n)` in every case,
/// `O(1)` space — genuinely in-place, no aux array anywhere.
public struct LaziestSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "laziestsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Laziest Stable",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1038, coefficients: [225199, 374.24, 0.128523],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [0.552509, 1.58098], rSquared: 0.990328),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "moon.zzz.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // Moves the element at `a` down to `b` (`b <= a`), shifting `[b, a)` right by one — ArrayV's
    // `insertTo`.
    func insertTo(_ a: Int, _ b: Int) {
      let temp = engine.values[a]
      var a = a
      while a > b {
        engine.setValue(a, engine.values[a - 1])
        a -= 1
      }
      engine.setValue(b, temp)
    }

    // Rightmost insertion point for `val` in the sorted range `[a, b)` — ties go right, which is
    // what keeps `binaryInsertion` stable.
    func rightBinSearch(_ aIn: Int, _ bIn: Int, _ val: Int) -> Int {
      var a = aIn
      var b = bIn
      while a < b {
        let mid = a + (b - a) / 2
        if val < engine.values[mid] {
          b = mid
        } else {
          a = mid + 1
        }
      }
      return a
    }

    // Leftmost insertion point for `val` in the sorted range `[a, b)`.
    func leftBinSearch(_ aIn: Int, _ bIn: Int, _ val: Int) -> Int {
      var a = aIn
      var b = bIn
      while a < b {
        let mid = a + (b - a) / 2
        if val <= engine.values[mid] {
          b = mid
        } else {
          a = mid + 1
        }
      }
      return a
    }

    // Exponential (galloping) search: doubles outward from `a` until it overshoots `val`'s
    // insertion point or runs off the end of `[a, b)`, then binary-searches within that bracket.
    // Finds the point in `O(log(distance))` instead of `leftBinSearch`'s `O(log(b - a))` when the
    // real answer is close to `a` — which it usually is here, since `inPlaceMerge` only ever
    // calls this to find where one element from the left run belongs among the right run.
    func leftExpSearch(_ a: Int, _ b: Int, _ val: Int) -> Int {
      var i = 1
      while a - 1 + i < b && val > engine.values[a - 1 + i] {
        i *= 2
      }
      return leftBinSearch(a + i / 2, min(b, a - 1 + i), val)
    }

    // Binary insertion sort over `[a, b)`.
    func binaryInsertion(_ a: Int, _ b: Int) {
      guard a + 1 < b else { return }
      for i in (a + 1)..<b {
        insertTo(i, rightBinSearch(a, i, engine.values[i]))
      }
    }

    // Stably merges the already-sorted `[a, m)` into the already-sorted `[m, b)`, in place: `i`
    // walks the left run, `j` the right. On a tie or `array[i] <= array[j]`, `i` just advances —
    // already in order. When `array[i]` is strictly greater, everything in the right run up to
    // (but not including) where `array[i]` belongs is strictly smaller than it, so rotating
    // `[i, j)` with `[j, k)` moves that whole already-scanned left-run block past them in one
    // shot, instead of inserting one element at a time.
    func inPlaceMerge(_ a: Int, _ m: Int, _ b: Int) {
      var i = a
      var j = m
      while i < j && j < b {
        if engine.compare(i, j, by: >) {
          let value = engine.values[i]
          let k = leftExpSearch(j + 1, b, value)
          GrailSortingTemplate.rotate(&engine, i, j - i, k - j)
          i += k - j
          j = k
        } else {
          i += 1
        }
      }
    }

    if n <= 16 {
      binaryInsertion(0, n)
      return
    }

    let blockLen = max(16, Int(Double(n).squareRoot()))
    var i = 0
    while i + 2 * blockLen < n {
      binaryInsertion(i, i + blockLen)
      i += blockLen
    }
    binaryInsertion(i, n)

    while i - blockLen >= 0 {
      inPlaceMerge(i - blockLen, i, n)
      i -= blockLen
    }
  }
}
