import AlgorithmKit
import SortEngineKit

/// ArrayV's `FlashSort` (Neubert's algorithm) — classifies each element into one of roughly `0.2n`
/// classes based on where its value falls between the array's min and max, cycle-permutes elements
/// into their class's contiguous region in one in-place pass, then finishes with a straight
/// (shift-based) insertion sort.
///
/// ArrayV's post-permutation recursion into oversized classes is skipped: it's verified dead code
/// in ArrayV itself — the recursion's result is never written back before the final full-array
/// insertion sort overwrites it. This port relies on that final pass exactly as much as ArrayV's
/// own code secretly always did.
///
/// Stability: `true` — contrary to Flash Sort's usual reputation as unstable. Ties never move
/// `maxIndex` during the min/max scan (strict `>`), class slots fill in strictly decreasing index
/// order, and the final insertion sort only shifts elements past strictly-greater neighbors, so
/// equal elements are never reordered.
public struct FlashSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "flashsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Flash Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 5935, coefficients: [239951, 71.1776, 0.00518025],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "bolt.horizontal.circle.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    // m = number of classes: ~20% of n, with a floor of 2 so there's always at least one
    // real class boundary to permute across.
    let m = Int(0.2 * Double(n)) + 2

    // -------CLASS FORMATION-------

    // Paired min/max scan: ArrayV examines array[i]/array[i+1] two at a time via one strict
    // live-index compare per pair, then folds that pair's bigger/smaller value into the
    // running min/max via plain local-variable comparisons — `big`/`small` are held values at
    // that point, not necessarily live at any index once the pair has been classified.
    var minValue = engine.values[0]
    var maxValue = engine.values[0]
    var maxIndex = 0

    var i = 1
    while i < n - 1 {
      let small: Int
      let big: Int
      let bigIndex: Int
      if engine.compare(i, i + 1, by: (<)) {
        small = engine.values[i]
        big = engine.values[i + 1]
        bigIndex = i + 1
      } else {
        big = engine.values[i]
        bigIndex = i
        small = engine.values[i + 1]
      }
      if big > maxValue {
        maxValue = big
        maxIndex = bigIndex
      }
      if small < minValue {
        minValue = small
      }
      i += 2
    }

    // ArrayV always re-examines the last element on its own, regardless of whether the paired
    // loop above already visited it — a held-value-vs-live-index-value comparison, not a
    // two-live-index compare.
    let last = engine.values[n - 1]
    if last < minValue {
      minValue = last
    } else if last > maxValue {
      maxValue = last
      maxIndex = n - 1
    }

    // All elements are identical: nothing to classify, permute, or insertion-sort — and this
    // guards the `c = (m - 1.0) / (max - min)` division just below from a divide-by-zero.
    guard maxValue != minValue else { return }

    // Local shadow of ArrayV's `L` (`Writes.createExternalArray(m + 1)`), 1-indexed with
    // index 0 unused, exactly like ArrayV. Kept as a plain Swift `[Int]` alongside the
    // aux-array handle since `RecordingEngine` has no read-back API — same pattern as
    // CountingSort's `output`/MSDRadixSort's per-frame `buckets`.
    let auxHandle = engine.createAuxArray(length: m + 1)
    var L = [Int](repeating: 0, count: m + 1)
    for t in 1...m {
      engine.writeAux(auxHandle, at: t, value: 0)
    }

    // K(x) = 1 + floor((m-1)(x-min)/(max-min)). `c` is the precomputed `(m-1)/(max-min)`
    // factor; Swift's `Int(Double)` truncates toward zero exactly like Java's `(int)` cast,
    // and since `value - minValue` is always >= 0 here, truncation and floor agree.
    let c = Double(m - 1) / Double(maxValue - minValue)
    func classOf(_ value: Int) -> Int {
      Int(Double(value - minValue) * c) + 1
    }

    for h in 0..<n {
      let k = classOf(engine.values[h])
      L[k] += 1
      engine.writeAux(auxHandle, at: k, value: L[k])
    }

    for k in 2...m {
      L[k] += L[k - 1]
      engine.writeAux(auxHandle, at: k, value: L[k])
    }

    // -------PERMUTATION-------

    // Swap the max value into the front of the array first, exactly like ArrayV.
    engine.swap(maxIndex, 0)

    // `j` is the cycle leader: the lowest index that starts a class boundary still missing
    // elements. `k` is the class currently being filled. `evicted` (introduced inside the
    // loop below) carries the value bumped out of each write location forward to the next
    // link in the cycle, the same "evict, place, adopt the evicted value" pattern CycleSort
    // uses — except here `L` supplies a shrinking, per-class write cursor instead of a single
    // global `countLesser` scan.
    var j = 0
    var k = m
    var numMoves = 0

    while numMoves < n {
      // Advance `j` to the next cycle leader: the next class boundary that still has an
      // element outside its borders. Reads `array[j]` directly (a live-index read used only
      // for classification math, not a two-live-index compare).
      while j >= L[k] {
        j += 1
        k = classOf(engine.values[j])
      }

      var evicted = engine.values[j]

      // Follow the cycle: repeatedly reclassify the evicted value, place it at its class's
      // next free slot (`L[k] - 1`), and adopt whatever was sitting there as the new
      // evicted value. Pure evict-and-place via `setValue` — no `swap` inside this loop,
      // matching ArrayV's `Writes.write(array, location, evicted, ...)`.
      while j < L[k] {
        k = classOf(evicted)
        let location = L[k] - 1
        let temp = engine.values[location]
        engine.setValue(location, evicted)
        evicted = temp
        L[k] -= 1
        engine.writeAux(auxHandle, at: k, value: L[k])
        numMoves += 1
      }
    }

    engine.deleteAuxArray(auxHandle)

    // -------STRAIGHT INSERTION-------
    // See the type-level doc comment: ArrayV's recursion into oversized classes is skipped as
    // verified dead code. This final full-array pass is what ArrayV's own code actually
    // relies on to finish the sort in every case.
    straightInsertionSort(into: &engine, n: n)
  }

  /// Ports ArrayV's `InsertionSorting.insertionSort(array, 0, sortLength, 0.75, false)` — a
  /// shift-based (not swap-based) insertion sort: the held value at `i` walks left one slot at
  /// a time via single-element writes, rather than adjacent swaps. `current`/`array[pos]` are a
  /// held-value-vs-live-index-value comparison, so this reads `engine.values` directly rather
  /// than going through `engine.compare` — the same precedent `DoubleInsertionSort`'s own
  /// shift loops and `CountingSort`'s max scan use.
  private func straightInsertionSort(into engine: inout RecordingEngine, n: Int) {
    guard n > 1 else { return }
    for i in 1..<n {
      let current = engine.values[i]
      var pos = i - 1
      while pos >= 0 && engine.values[pos] > current {
        engine.setValue(pos + 1, engine.values[pos])
        pos -= 1
      }
      engine.setValue(pos + 1, current)
    }
  }
}
