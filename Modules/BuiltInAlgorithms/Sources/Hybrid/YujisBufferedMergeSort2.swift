import AlgorithmKit
import SortEngineKit

/// ArrayV's `YujisBufferedMergeSort2` (yuji, implemented by aphitorite, edited by dani_dlg) — a
/// recursive, in-place buffered merge sort in the same family as `AndreySort`/`GrailSort`: it
/// carves its own working buffer out of the array being sorted rather than allocating one.
/// `bufferedMerge` builds a sorted "buffer" region in the upper half of its range via `mergeSort`/
/// `mergeWithBufStatic` (an iterative bottom-up merge that ping-pongs its active region between two
/// fixed offsets via the `next ^= a ^ p` XOR toggle), recursively sorts the lower half, swaps the
/// buffer back down, and merges it in via a swap-based merge whose destination cursor never outruns
/// its sources — the same "swap instead of overwrite" trick `AndreySort`'s `backmerge`/`rmerge`
/// already use, which is what lets this whole family merge in place with no auxiliary buffer.
///
/// Every move is `engine.swap` except `insertTo`'s shift-and-place, used only by `binaryInsertion`
/// (runs of 16 or fewer, including the `b - a <= 16` base case) — that one goes through
/// `engine.setValue`, same shift-loop shape as `OptimizedWeaveMergeSort`'s `insertTo`.
///
/// Stable: `false` — see `yujisBufferedMergeSort2TiedElementsCanLoseTheirOriginalRelativeOrder`.
/// `mergeWithBufStatic`'s galloping-merge tie-break (`array[j] < array[p+i]`, strict) moves the
/// buffer-side element first on a tie, and that buffer was itself assembled by an earlier merge
/// pass over elements that started on both sides of the original split — confirmed empirically
/// rather than assumed, after both stability guesses in the previous batch turned out backwards.
public struct YujisBufferedMergeSort2: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "yujisbufferedmergesort2")
  public let metadata = AlgorithmMetadata(
    displayName: "Yuji's Buffered Merge Sort 2",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1369, coefficients: [239787, 307.425, 0.0963836],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0963836, 43.5268, -440.105], rSquared: 0.998975),
    implementationComplexity: 62,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "tray.2"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `ceilLog(n)`: smallest `i` with `1 << i >= n`. Pure loop-bound arithmetic, not an
    // algorithmic comparison -- no engine call.
    func ceilLog(_ value: Int) -> Int {
      var i = 0
      while (1 << i) < value {
        i += 1
      }
      return i
    }

    // ArrayV's `multiSwap(array, a, b, len)`: `len` chained swaps, `array[a+i] <-> array[b+i]`.
    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len {
        engine.swap(a + i, b + i)
      }
    }

    // ArrayV's `insertTo(array, a, b)`: shift the block `(b, a]` up by one, then drop the
    // element originally at `a` into `b`. Written with a `while` loop, not a `for`/`Range`, since
    // callers can pass `a == b` (a no-op) and a `Range` literal would need extra guarding.
    func insertTo(_ a: Int, _ b: Int) {
      let temp = engine.values[a]
      var a = a
      while a > b {
        a -= 1
        engine.setValue(a + 1, engine.values[a])
      }
      engine.setValue(b, temp)
    }

    // ArrayV's `binarySearch(array, start, end, value, left)`. `value` is always a snapshotted
    // local, never a live index, so this is `engine.compareValue`. ArrayV's
    // `Reads.compareValues(value, array[m])` has its operands in `(held, live)` order -- opposite
    // of `compareValue`'s `(live, held)` order -- so the comparator is flipped accordingly:
    // `left`'s non-strict `value <= array[m]` becomes `array[m] >= value`, and the strict
    // `value < array[m]` becomes `array[m] > value`.
    func binarySearch(_ start: Int, _ end: Int, _ value: Int, left: Bool) -> Int {
      var a = start
      var b = end
      while a < b {
        let m = a + (b - a) / 2
        let comp: Bool
        if left {
          comp = engine.compareValue(m, against: value, by: (>=))
        } else {
          comp = engine.compareValue(m, against: value, by: (>))
        }
        if comp {
          b = m
        } else {
          a = m + 1
        }
      }
      return a
    }

    // ArrayV's `binaryInsertion(array, a, b)`: a plain binary-insertion sort, used both as the
    // base case for ranges of 16 or fewer and to pre-sort each run of 16 before `mergeSort`'s
    // doubling passes.
    func binaryInsertion(_ a: Int, _ b: Int) {
      var i = a + 1
      while i < b {
        let value = engine.values[i]
        insertTo(i, binarySearch(a, i, value, left: false))
        i += 1
      }
    }

    // ArrayV's `merge(array, a, m, b, p)`: merges `[a,m)`/`[m,b)` into the output region starting
    // at `p`, entirely via swaps. Returns the count of right-run elements copied after the left
    // run was exhausted -- `bufferedMerge` needs this to know how much of the tail is genuinely
    // unsorted after the final merge-back.
    func merge(_ a: Int, _ m: Int, _ b: Int, _ pIn: Int) -> Int {
      var i = a
      var j = m
      var p = pIn
      while i < m && j < b {
        if engine.compare(i, j, by: (<=)) {
          engine.swap(p, i)
          p += 1
          i += 1
        } else {
          engine.swap(p, j)
          p += 1
          j += 1
        }
      }
      var leftover = 0
      while i < m {
        engine.swap(p, i)
        p += 1
        i += 1
      }
      while j < b {
        engine.swap(p, j)
        p += 1
        j += 1
        leftover += 1
      }
      return leftover
    }

    // ArrayV's `mergeWithBufStatic(array, a, m, b, p, useBinarySearch)`: merges the buffer
    // `[p, p+(m-a))` with `[m,b)` back into `[a,...)`. Both branches compare two live indices
    // (`array[j]` vs `array[p+i]`), never a held value, so both go through `engine.compare`.
    // Deliberately has no "copy remaining `[j,b)` elements" cleanup loop at the end, matching
    // ArrayV exactly: `k` never runs ahead of `j`, so once `i` (the buffer side) is exhausted, `k`
    // has already caught up to `j` and the remaining range is already in its final position.
    func mergeWithBufStatic(_ a: Int, _ m: Int, _ b: Int, _ p: Int, _ useBinarySearch: Bool) {
      var i = 0
      var j = m
      var k = a

      if useBinarySearch {
        while i < m - a && j < b {
          if engine.compare(j, p + i, by: (<)) {
            let value = engine.values[p + i]
            let q = binarySearch(j, b, value, left: true)
            while j < q {
              engine.swap(k, j)
              k += 1
              j += 1
            }
          }
          engine.swap(k, p + i)
          k += 1
          i += 1
        }
        while i < m - a {
          engine.swap(k, p + i)
          k += 1
          i += 1
        }
      } else {
        while i < m - a && j < b {
          if engine.compare(p + i, j, by: (<=)) {
            engine.swap(k, p + i)
            k += 1
            i += 1
          } else {
            engine.swap(k, j)
            k += 1
            j += 1
          }
        }
        while i < m - a {
          engine.swap(k, p + i)
          k += 1
          i += 1
        }
      }
    }

    // ArrayV's `mergeSort(array, a, p, length)`: an iterative bottom-up merge over `[a, a+length)`
    // seeded with binary-insertion-sorted runs of 16, doubling the run size each pass. `next`
    // toggles between the two fixed offsets `a`/`p` via XOR -- valid exactly because `next` only
    // ever holds one of those two values at this point, the classic XOR-swap trick applied to a
    // repeated toggle instead of a one-time swap.
    func mergeSort(_ a: Int, _ p: Int, _ length: Int) {
      var j = 16
      let ceilLogValue = ceilLog(length)

      var pos: Int
      if length > 16 && (ceilLogValue & 1) == 1 {
        pos = p
      } else {
        pos = a
      }

      var i = pos
      while i + 16 <= pos + length {
        binaryInsertion(i, i + 16)
        i += 16
      }
      binaryInsertion(i, pos + length)

      var next = pos
      while j < length {
        pos = next
        next ^= a ^ p
        var posNext = next

        i = pos
        while i + 2 * j <= pos + length {
          merge(i, i + j, i + 2 * j, posNext)
          i += 2 * j
          posNext += 2 * j
        }
        if i + j < pos + length {
          merge(i, i + j, pos + length, posNext)
        } else {
          while i < pos + length {
            engine.swap(i, posNext)
            i += 1
            posNext += 1
          }
        }
        j *= 2
      }
    }

    // ArrayV's `bufferedMerge(array, a, b)`: base case at 16 or fewer elements, otherwise builds a
    // sorted buffer in the upper half (shrinking `limit` each pass), recursively sorts the lower
    // half, swaps the buffer down, merges it back in, and recurses on whatever the merge-back left
    // unsorted at the tail.
    func bufferedMerge(_ a: Int, _ b: Int) {
      if b - a <= 16 {
        binaryInsertion(a, b)
        return
      }

      var m = (a + b + 1) / 2
      mergeSort(m, 2 * m - b, b - m)

      var n = (a + m + 1) / 2
      let limit = (b - a) / 16
      while m - a > limit {
        mergeSort(2 * n - m, n, m - n)
        mergeWithBufStatic(n, m, b, 2 * n - m, (b - m) / (m - n) >= ceilLog(n - a))
        m = n
        n = (a + m + 1) / 2
      }

      bufferedMerge(a, m)
      multiSwap(a, b - (m - a), m - a)
      let s = merge(m, b - (m - a), b, a)
      bufferedMerge(b - (m - a) - s, b)
    }

    bufferedMerge(0, n)
  }
}
