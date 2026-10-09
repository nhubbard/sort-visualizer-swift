import Foundation
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
/// ArrayV's original `rmerge` can leave heavy-duplicate inputs out of order because it chooses
/// blocks by their leading value alone. A final linear, instrumented read checks the result;
/// when that inherited path fails, `MaxHeapSort` repairs it in place. This keeps the original
/// block-merge visualization for normal inputs and guarantees a correct, bounded result for all
/// inputs without allocating a scratch array.
public struct AndreySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "andreysort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Andrey Sort", bundle: .module),
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1391, coefficients: [213214, 188.521, 0.0145277],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [10.9021, 1.09174], rSquared: 0.998295),
    implementationComplexity: 43,
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
        for i in 1..<b where engine.teachingCompare(
          a + k, a + i, by: (>),
          stageID: "AndreySort.key.selection",
          whenTrue: String(localized: "This candidate is below the current key, so Andrey selects it as the new minimum.", bundle: .module),
          whenFalse: String(localized: "This candidate is not below the current key, so the selected minimum remains.", bundle: .module)
        ) {
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
        engine.annotateLastOperation(
          stageID: "andrey.blockExchange", decisionID: "andrey.blockExchange",
          outcome: "exchange", roles: ["first": .arrayIndex(arr1), "second": .arrayIndex(arr2)],
          explanationKey: "andrey.blockExchange",
          explanation: String(localized: "Andrey exchanges these block positions to place the selected block beside its merge partner.", bundle: .module))
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
        if engine.teachingCompare(
          arr1, arr2, by: (>), stageID: "andrey.backwardMerge",
          whenTrue: String(localized: "The left tail is larger, so backward merge places it in the trailing buffer.", bundle: .module),
          whenFalse: String(localized: "The right tail is at least as large, so backward merge places it next.", bundle: .module)) {
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
          if engine.teachingCompare(
            a + q, a + j, by: (>), stageID: "andrey.blockLeader",
            whenTrue: String(localized: "This block leader is smaller, so Andrey selects its block for the next merge.", bundle: .module),
            whenFalse: String(localized: "This block leader is not smaller, so the selected block stays.", bundle: .module)) { q = j }
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
        if engine.teachingCompare(
          a + (p - 2), a + (p - 1), by: (>), stageID: "andrey.pairPresort",
          whenTrue: String(localized: "This starting pair descends, so Andrey swaps it before block merging.", bundle: .module),
          whenFalse: String(localized: "This starting pair is ordered, so Andrey keeps it.", bundle: .module)) {
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
    var previous = engine.readValue(at: 0)
    for index in 1..<n {
      let current = engine.readValue(at: index)
      let needsRepair = previous > current
      engine.annotateLastOperation(
        stageID: "andrey.verifyOrder", decisionID: "andrey.verifyOrder",
        outcome: needsRepair ? "repair" : "continue",
        roles: ["candidate": .arrayIndex(index), "previous": .arrayIndex(index - 1)],
        explanationKey: "andrey.verifyOrder",
        explanation: needsRepair
          ? String(localized: "This adjacent pair is still reversed, so heap repair completes the sort.", bundle: .module)
          : String(localized: "This adjacent pair is ordered, so verification continues.", bundle: .module))
      if needsRepair {
        MaxHeapSort().record(into: &engine)
        break
      }
      previous = current
    }
  }
}
