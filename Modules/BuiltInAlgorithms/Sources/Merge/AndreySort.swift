import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `AndreySort` — Andrey Astrelin's well-known in-place merge sort. Below
/// length 12, `sort` is a plain selection sort (repeatedly swap the minimum of the remaining range
/// to the front). Above that, `msort` splits the range into a portion whose length is a multiple
/// of a computed block size `r` (from `rbnd`) and a remainder, builds up progressively larger
/// sorted blocks within the multiple-of-`r` portion via `backmerge` (merge two runs backward into
/// a trailing buffer region) and `rmerge` (selection-sort the block leaders, then `backmerge` each
/// selected block into place) — genuinely in-place, using part of the range itself as the rotating
/// buffer rather than an external one — and finally recurses on the remainder before merging it
/// back in.
///
/// Every move in this algorithm is a `swap` — no `setValue` anywhere in `sort`/`aswap`/
/// `backmerge`/`rmerge` — translated literally index-for-index from the Java, including the
/// backward-counting pointers (`arr1--`, `arr0--`) in `backmerge`, which Swift expresses as plain
/// `var`s decremented in the same order the post-decrement operators evaluate them (use current
/// value, then decrement).
///
/// **Known real bug, inherited from ArrayV, not a translation artifact**: `rmerge` selects which
/// block to move into place by comparing only each block's *leading* element, then moves the
/// whole block — silently assuming no other pending block holds a value smaller than this block's
/// own trailing values. Heavy duplication can violate that assumption (confirmed by transcribing
/// this exact algorithm to a standalone Java program with no ArrayV dependencies at all and
/// reproducing the same wrong output on the same input — see
/// `andreySortSortsReliablyExceptOnHeavyDuplicates` in `NativeAlgorithmCorrectnessTests.swift`,
/// which deliberately excludes this algorithm from the generic fuzz suite for exactly this
/// reason). Measured failure rate is real but narrow — roughly 1-8% depending on array size, only
/// with heavy duplication, never on already-sorted/reverse-sorted/mostly-distinct input. This is a
/// documented weakness of this specific, simpler member of Andrey Astrelin's merge-sort lineage:
/// his own later `GrailSort` (already shipped separately in this codebase) explicitly added
/// fallback handling for low-key-diversity input that this earlier algorithm never had.
public struct AndreySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "andreysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Andrey Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1378, coefficients: [213948, 189.879, 0.014284],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [11.6503, 1.08463], rSquared: 0.996129),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "list.number"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    // Selection sort — the base case below length 12.
    func sort(_ aIn: Int, _ bIn: Int) {
      var a = aIn
      var b = bIn
      while b > 1 {
        var k = 0
        for i in 1..<b where engine.compare(a + k, a + i, by: (>)) {
          k = i
        }
        engine.swap(a, a + k)
        a += 1
        b -= 1
      }
    }

    // Forward block-swap of `l` elements.
    func aswap(_ arr1In: Int, _ arr2In: Int, _ lIn: Int) {
      var arr1 = arr1In
      var arr2 = arr2In
      var l = lIn
      while l > 0 {
        engine.swap(arr1, arr2)
        arr1 += 1
        arr2 += 1
        l -= 1
      }
    }

    // Merges the two runs ending at `arr1`/`arr2` (lengths `l1`/`l2`), working backward from
    // their high ends into the trailing buffer starting at `arr2 + l1`. Returns the count of
    // left-run elements not yet placed if the right run was exhausted first (0 otherwise).
    func backmerge(_ arr1In: Int, _ l1In: Int, _ arr2In: Int, _ l2In: Int) -> Int {
      var arr1 = arr1In
      var l1 = l1In
      var arr2 = arr2In
      var l2 = l2In
      var arr0 = arr2 + l1
      while true {
        if engine.compare(arr1, arr2, by: (>)) {
          engine.swap(arr1, arr0)
          arr1 -= 1
          arr0 -= 1
          l1 -= 1
          if l1 == 0 { return 0 }
        } else {
          engine.swap(arr2, arr0)
          arr2 -= 1
          arr0 -= 1
          l2 -= 1
          if l2 == 0 { break }
        }
      }
      let res = l1
      repeat {
        engine.swap(arr1, arr0)
        arr1 -= 1
        arr0 -= 1
        l1 -= 1
      } while l1 != 0
      return res
    }

    // Merges `arr[a..<a+l)` (as `l/r` blocks of width `r`) using the buffer `arr[a+l..<a+l+r)`:
    // selection-sorts the block leaders, then `backmerge`s each selected block into place.
    func rmerge(_ a: Int, _ l: Int, _ r: Int) {
      var i = 0
      while i < l {
        var q = i
        var j = i + r
        while j < l {
          if engine.compare(a + q, a + j, by: (>)) { q = j }
          j += r
        }
        if q != i { aswap(a + i, a + q, r) }
        if i != 0 {
          aswap(a + l, a + i, r)
          _ = backmerge(a + (l + r - 1), r, a + (i - 1), r)
        }
        i += r
      }
    }

    func rbnd(_ lenIn: Int) -> Int {
      var len = lenIn / 2
      var k = 0
      var i = 1
      while i < len {
        k += 1
        i *= 2
      }
      len /= k
      k = 1
      while k <= len { k *= 2 }
      return k
    }

    func msort(_ a: Int, _ len: Int) {
      if len < 12 {
        sort(a, len)
        return
      }

      let r = rbnd(len)
      let lr = (len / r - 1) * r

      var p = 2
      while p <= lr {
        if engine.compare(a + (p - 2), a + (p - 1), by: (>)) {
          engine.swap(a + (p - 2), a + (p - 1))
        }
        if (p & 2) != 0 {
          p += 2
          continue
        }

        aswap(a + (p - 2), a + p, 2)

        let m = len - p
        var q = 2
        while true {
          let q0 = 2 * q
          if q0 > m || (p & q0) != 0 { break }
          _ = backmerge(a + (p - q - 1), q, a + (p + q - 1), q)
          q = q0
        }
        _ = backmerge(a + (p + q - 1), q, a + (p - q - 1), q)
        let q1 = q
        q *= 2

        while (q & p) == 0 {
          q *= 2
          rmerge(a + (p - q), q, q1)
        }

        p += 2
      }

      var q1 = 0
      var q = r
      while q < lr {
        if (lr & q) != 0 {
          q1 += q
          if q1 != q {
            rmerge(a + (lr - q1), q1, r)
          }
        }
        q *= 2
      }

      let s0 = len - lr
      msort(a + lr, s0)
      aswap(a, a + lr, s0)
      let s = s0 + backmerge(a + (s0 - 1), s0, a + (lr - 1), lr - s0)
      msort(a, s)
    }

    msort(0, n)
  }
}
