import AlgorithmKit
import SortEngineKit

/// ArrayV's `OptimizedWeaveMergeSort` (aphitorite, 2020) — a bottom-up, in-place merge sort with
/// no auxiliary buffer. Each pass carves the array into adjacent run pairs via a Bresenham-style
/// fractional stepper (`dec`, in `record(into:)`'s own loop), so pairs stay evenly sized even when
/// the length isn't a power of two, then merges each pair with `weaveMerge`. `weaveMerge` does not
/// compare values while merging: a shrinking sequence of `rotate` calls and `bitReversal`
/// permutations interleaves the two runs' *positions* only (a perfect shuffle), and a single
/// `weaveInsert` pass afterward is the only place this algorithm ever compares two elements — one
/// pass over the whole merged range fixes up whatever the shuffle left out of order.
///
/// ArrayV computes the top-level `d` (smallest power of two >= n) via `Math.log`, leaning on
/// Java-specific `NaN`/shift-masking behavior to stay a no-op at `n <= 1`. Swift traps on
/// `Int(Double.nan)` and does not mask out-of-range shift amounts the same way, so this port
/// special-cases `n <= 1` explicitly up front and computes `d` by plain integer doubling instead —
/// same result, no floating-point involved.
///
/// Stable: `true` — despite superficially resembling `WeaveMergeSort` (which is unstable),
/// `weaveInsert`'s `right` flag alternates its shift condition between non-strict (`<=`) and
/// strict (`<`) depending on which side of the interleave a run of ties currently sits on. That
/// alternation is exactly what keeps equal elements from crossing, unlike `WeaveMergeSort`'s
/// single always-`<=` shift condition. Verified empirically via
/// `optimizedWeaveMergeSortIsStable` (2200+ duplicate-heavy trials across 11 sizes, zero
/// reorderings found) — not assumed from the superficial resemblance to its unstable sibling.
public struct OptimizedWeaveMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedweavemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Weave Merge Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 951, coefficients: [223834, 345.149, 0.0820103],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [3.8085, 1.32061], rSquared: 0.999046),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "shuffle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `insertTo(array, a, b)`: shift the block `(b, a]` up by one, then drop the
    // element originally at `a` into `b`.
    func insertTo(_ a: Int, _ b: Int) {
      let temp = engine.values[a]
      var a = a
      while a > b {
        a -= 1
        engine.setValue(a + 1, engine.values[a])
      }
      engine.setValue(b, temp)
    }

    // ArrayV's `multiSwap(array, a, b, len)`: `len` chained swaps, `array[a+i] <-> array[b+i]`.
    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len {
        engine.swap(a + i, b + i)
      }
    }

    // ArrayV's `rotate(array, a, m, b)`: block-swap rotation of `[a,m)`/`[m,b)`, repeatedly
    // `multiSwap`-ing the smaller side into place. Pure writes — no comparisons.
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

    // ArrayV's `bitReversal(array, a, b)` — power-of-two length only, O(n). Swaps each index
    // `a+i` with its bit-reversal-permutation partner `a+m`, skipping when `m <= i` to avoid
    // swapping each pair twice. Pure index arithmetic; no comparisons. Written with `while`
    // loops throughout (not `Range`s) since `len` can legitimately be as small as 1, which would
    // make a `1..<(len - 1)` range crash rather than simply not iterate.
    func bitReversal(_ a: Int, _ b: Int) {
      let len = b - a
      var m = 0
      let d1 = len >> 1
      let d2 = d1 + (d1 >> 1)
      var i = 1
      while i < len - 1 {
        var j = d1
        var k = i
        var nn = d2
        while k & 1 == 0 {
          j -= nn
          k >>= 1
          nn >>= 1
        }
        m += j
        if m > i {
          engine.swap(a + i, a + m)
        }
        i += 1
      }
    }

    // ArrayV's `weaveInsert(array, a, b, right)`: the only comparisons in this whole algorithm.
    // `right` toggles between a non-strict (`<=`) and strict (`<`) shift condition depending on
    // which side `weaveMerge` borrowed its odd-length sentinel element from.
    func weaveInsert(_ a: Int, _ b: Int, _ rightInit: Bool) {
      var right = rightInit
      var i = a
      var j = a + 1
      while j < b {
        if right {
          while i < j && engine.compare(i, j, by: (<=)) { i += 1 }
        } else {
          while i < j && engine.compare(i, j, by: (<)) { i += 1 }
        }
        if i == j {
          right.toggle()
          j += 1
        } else {
          insertTo(j, i)
          i += 1
          j += 2
        }
      }
    }

    // ArrayV's `weaveMerge(array, a, m, b)`: merges sorted runs `[a,m)`/`[m,b)` with no scratch
    // buffer. For odd total length, borrows one sentinel element from whichever run is shorter,
    // then repeatedly rotates and bit-reverses a shrinking window to interleave the two runs'
    // positions before `weaveInsert` untangles the result.
    func weaveMerge(_ a: Int, _ mInit: Int, _ b: Int) {
      guard b - a >= 2 else { return }

      var a1 = a
      var b1 = b
      var right = true
      if (b - a) % 2 == 1 {
        if mInit - a < b - mInit {
          a1 -= 1
          right = false
        } else {
          b1 += 1
        }
      }

      var e = b1
      while e - a1 > 2 {
        var m = (a1 + e) / 2
        // Largest power of two <= (m - a1). ArrayV computes this via `Math.log`; the loop
        // invariant above (`e - a1 > 2`) keeps `m - a1 >= 1`, so plain integer doubling is exact
        // and avoids `Math.log`'s floating-point surface entirely.
        var p = 1
        while p * 2 <= m - a1 {
          p *= 2
        }
        rotate(m - p, m, e - p)
        m = e - p
        let f = m - p
        bitReversal(f, m)
        bitReversal(m, e)
        bitReversal(f, e)
        e = f
      }
      weaveInsert(a, b, right)
    }

    // ArrayV's `runSort`: halves a power-of-two `d` from the smallest power of two >= n down to
    // 1. Each pass's `dec` accumulator is a Bresenham-style fractional stepper that carves `[0,
    // n)` into adjacent run pairs of nearly-equal size even when `n` isn't a power of two.
    var d = 1
    while d < n { d <<= 1 }

    while d > 1 {
      var i = 0
      var dec = 0
      while i < n {
        var j = i
        dec += n
        while dec >= d {
          dec -= d
          j += 1
        }
        var k = j
        dec += n
        while dec >= d {
          dec -= d
          k += 1
        }
        weaveMerge(i, j, k)
        i = k
      }
      d /= 2
    }
  }
}
