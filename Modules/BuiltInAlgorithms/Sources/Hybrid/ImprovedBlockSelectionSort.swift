import AlgorithmKit
import SortEngineKit

/// ArrayV's `ImprovedBlockSelectionSort` (aphitorite, 2020) — a bottom-up, in-place merge sort
/// whose merge step is preceded by a cheap block-reordering pass. For each doubling of the
/// already-sorted run length `j`, `blockSelect` treats each run as a sequence of `bLen`-sized
/// blocks and does a selection sort *on whole blocks* (reordering them via `multiSwap`, never
/// touching an individual element), at successively finer granularities
/// (`j -> sqrt(j) -> sqrt(sqrt(j)) -> ...` down to `<= 16`). Only once the blocks are in
/// approximately correct order does the expensive element-level `inPlaceMerge`/`inPlaceMergeBW`
/// run, over chunks now small enough (`<= 16`) that its rotations stay cheap. No recursion, no
/// auxiliary buffer.
///
/// `selectRange`'s tie-break (comparing two blocks' *last* elements when their first elements are
/// equal) needs `array[a] < array[min]` and `array[a] == array[min]` as separate facts about the
/// same pair. ArrayV gets both from one `Reads.compareIndices` call by inspecting its three-way
/// `Integer.compare` sign; `RecordingEngine.compare` only returns a `Bool`, so recovering both
/// facts here costs a second real comparison whenever `array[a] >= array[min]` — an intentional,
/// bounded overcount versus ArrayV's exact call count, not a hidden one.
///
/// Stable: `false`, despite `inPlaceMerge`/`inPlaceMergeBW`'s own comparisons all being strict
/// (`>`, never `>=`). Those two only run *after* `blockSelect` has already reordered whole
/// `bLen`-sized blocks via `multiSwap`; a block is moved as an atomic unit purely by comparing
/// representative (first/last) elements, so two blocks that happen to tie on their representative
/// values can still swap places wholesale, taking every element inside them along — including any
/// that share a value with an element in a *different*, not-yet-repositioned block. That
/// cross-block reordering happens before the strict, otherwise order-preserving element-level
/// merge ever sees the data. Verified empirically via
/// `improvedBlockSelectionSortTiedElementsCanLoseTheirOriginalRelativeOrder` (consistent
/// reordering in 50/50 duplicate-heavy trials) — the strict merge comparisons alone are not
/// sufficient evidence of stability for this algorithm's two-phase design.
public struct ImprovedBlockSelectionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "improvedblockselectionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Improved Block Selection Merge Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 921, coefficients: [225858, 330.766, 0.0597746],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [9.0329, 1.20228], rSquared: 0.99526),
    implementationComplexity: 53,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `sqrt(n)`: smallest power of two whose square is >= n. Pure integer doubling —
    // no `Math.log`, so unlike the top-level `d` in `OptimizedWeaveMergeSort` there's no
    // floating-point/NaN hazard to special-case here.
    func sqrt(_ value: Int) -> Int {
      var i = 1
      while i * i < value {
        i *= 2
      }
      return i
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

    // ArrayV's `selectRange(array, a, b, bLen)`: finds the block (stepping by `bLen`) with the
    // smallest representative (first) element in `[a, b)`. See the type doc comment on the
    // two-call tie-break tradeoff below.
    func selectRange(_ start: Int, _ end: Int, _ bLen: Int) -> Int {
      var minIndex = start
      var a = start + bLen
      while a < end {
        if engine.compare(a, minIndex, by: (<)) {
          minIndex = a
        } else if engine.compare(a, minIndex, by: (==))
          && engine.compare(a + bLen - 1, minIndex + bLen - 1, by: (<))
        {
          minIndex = a
        }
        a += bLen
      }
      return minIndex
    }

    // ArrayV's `blockSelect(array, a, m, b, bLen)`: selection-sort-on-blocks over the two
    // already-block-sorted halves `[a,m)`/`[m,b)`, reordering whole `bLen`-sized blocks (never
    // individual elements) into ascending order by representative element.
    func blockSelect(_ a: Int, _ m: Int, _ b: Int, _ bLen: Int) {
      var k = a
      var j = m
      while k < m && engine.compare(k, m, by: (<=)) {
        k += bLen
      }
      guard k != m else { return }

      var i = m
      multiSwap(k, j, bLen)
      k += bLen
      j += bLen

      while k < j && j < b {
        if engine.compare(i, j, by: (<=)) {
          if k != i { multiSwap(k, i, bLen) }
          k += bLen
          i = selectRange(max(m, k), j, bLen)
        } else {
          if i == k { i = j }
          if k != j { multiSwap(k, j, bLen) }
          k += bLen
          j += bLen
        }
      }
      while k < j {
        i = selectRange(k, b, bLen)
        if k != i { multiSwap(k, i, bLen) }
        k += bLen
      }
    }

    // ArrayV's `inPlaceMerge(array, a, m, b)`: standard in-place merge of `[a,m)`/`[m,b)` via
    // `rotate`, returning the merge boundary reached so the caller can chain the next merge
    // without rescanning already-settled elements.
    func inPlaceMerge(_ a: Int, _ m: Int, _ b: Int) -> Int {
      var i = a
      var j = m
      while i < j && j < b {
        if engine.compare(i, j, by: (>)) {
          var k = j + 1
          while k < b && engine.compare(i, k, by: (>)) {
            k += 1
          }
          rotate(i, j, k)
          i += k - j
          j = k
        } else {
          i += 1
        }
      }
      return i
    }

    // ArrayV's `inPlaceMergeBW(array, a, m, b)`: the mirror-image, right-to-left in-place merge,
    // used only for the trailing remainder block that doesn't divide evenly into `2*j`-sized
    // pairs.
    func inPlaceMergeBW(_ a: Int, _ m: Int, _ b: Int) {
      var i = m - 1
      var j = b - 1
      while j > i && i >= a {
        if engine.compare(i, j, by: (>)) {
          var k = i - 1
          while k >= a && engine.compare(k, j, by: (>)) {
            k -= 1
          }
          rotate(k + 1, i + 1, j + 1)
          j -= i - k
          i = k
        } else {
          j -= 1
        }
      }
    }

    // ArrayV's `runSort`: for each doubling run length `j`, coarsen block size from `j` down to
    // `<= 16` via `blockSelect`, then finish with element-level merges over the now-small,
    // near-sorted chunks.
    var j = 1
    while j < n {
      var bLen = sqrt(j)
      var runLength = j
      let b = n - n % bLen

      while runLength > 16 {
        var i = 0
        while i + j < b {
          var k = i
          while k + runLength < min(i + 2 * j, b) {
            blockSelect(k, k + runLength, min(k + 2 * runLength, b), bLen)
            k += runLength
          }
          i += 2 * j
        }
        runLength = bLen
        bLen = sqrt(bLen)
      }

      var i = 0
      while i + j < b {
        var k = i
        var f = i
        while k + runLength < min(i + 2 * j, b) {
          f = inPlaceMerge(f, k + runLength, min(k + 2 * runLength, b))
          k += runLength
        }
        i += 2 * j
      }

      inPlaceMergeBW(n - n % (2 * j), b, n)
      j *= 2
    }
  }
}
