import SortEngineKit

/// Scratch offset buffers `PDQSortingTemplate.partRightBranchless` needs, allocated once per
/// top-level sort call (not per recursive `pdqLoop` call) and threaded through every recursion —
/// mirrors ArrayV's own `visualizeAux()`/`deleteAux()` bracket around the whole sort. Always
/// allocated by both entry points here (even the branch-based one, which never touches them) —
/// a harmless simplification versus ArrayV's own lazier allocation, in exchange for `pdqLoop`
/// having one shared signature instead of two.
private struct PDQOffsetBuffers {
  var left: [Int]
  var right: [Int]

  init(size: Int) {
    left = [Int](repeating: 0, count: size)
    right = [Int](repeating: 0, count: size)
  }
}

/// Ported from ArrayV's `sorts/templates/PDQSorting` — Orson Peters' pattern-defeating quicksort.
/// Two concrete algorithms extend this template (`PDQBranchedSort`/`PDQBranchlessSort`), both pure
/// configuration wrappers around one shared `pdqLoop` (a `branchless` flag selects between the
/// plain Hoare-style partition and a block-quicksort-style branchless one) — the cleanest reuse
/// case in this whole batch of template ports, confirmed by research: neither subclass shadows or
/// reimplements anything, all the real complexity (pivot selection, both partition schemes,
/// balance-checking, anti-adversarial-pattern scrambling, a heapsort depth-limit fallback, and a
/// many-equal-elements fast path) lives entirely here.
enum PDQSortingTemplate {
  private static let insertSortThreshold = 24
  private static let nintherThreshold = 128
  private static let partialInsertSortLimit = 8
  private static let blockSize = 64
  private static let cachelineSize = 64

  /// `floor(log2(n))`, assumes `n > 0` — seeds the `badAllowed` depth-limit counter.
  static func pdqLog(_ n: Int) -> Int {
    var n = n
    var log = 0
    n >>= 1
    while n != 0 {
      log += 1
      n >>= 1
    }
    return log
  }

  // MARK: - Insertion sort family

  private static func insertSort(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int) {
    guard begin != end else { return }
    for cur in (begin + 1)..<end where engine.compare(cur, cur - 1, by: <) {
      let tmp = engine.values[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      repeat {
        engine.setValue(sift, engine.values[siftMinusOne])
        sift -= 1
        siftMinusOne -= 1
      } while sift != begin && tmp < engine.values[siftMinusOne]
      engine.setValue(sift, tmp)
    }
  }

  /// Same as `insertSort`, but assumes `engine.values[begin - 1] <= everything in [begin, end)` —
  /// valid whenever this isn't the leftmost partition, letting the shift loop skip the
  /// left-edge check.
  private static func unguardInsertSort(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int) {
    guard begin != end else { return }
    for cur in (begin + 1)..<end where engine.compare(cur, cur - 1, by: <) {
      let tmp = engine.values[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      repeat {
        engine.setValue(sift, engine.values[siftMinusOne])
        sift -= 1
        siftMinusOne -= 1
      } while tmp < engine.values[siftMinusOne]
      engine.setValue(sift, tmp)
    }
  }

  /// Attempts an insertion sort but bails out (returns `false`, array left partially modified) if
  /// the total shift count exceeds `partialInsertSortLimit` — a cheap "is this nearly sorted
  /// already" finishing move after a partition reported already-partitioned.
  private static func partialInsertSort(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int)
    -> Bool {
    guard begin != end else { return true }
    var limit = 0
    for cur in (begin + 1)..<end {
      if limit > partialInsertSortLimit { return false }
      if engine.compare(cur, cur - 1, by: <) {
        let tmp = engine.values[cur]
        var sift = cur
        var siftMinusOne = cur - 1
        repeat {
          engine.setValue(sift, engine.values[siftMinusOne])
          sift -= 1
          siftMinusOne -= 1
        } while sift != begin && tmp < engine.values[siftMinusOne]
        engine.setValue(sift, tmp)
        limit += cur - sift
      }
    }
    return true
  }

  // MARK: - Pivot selection

  private static func sortTwo(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    if engine.compare(b, a, by: <) {
      engine.swap(a, b)
    }
  }

  private static func sortThree(_ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ c: Int) {
    sortTwo(&engine, a, b)
    sortTwo(&engine, b, c)
    sortTwo(&engine, a, b)
  }

  // MARK: - Range-scoped heapsort fallback

  /// Guarantees O(n log n) once too many highly-unbalanced partitions have been seen — same
  /// algorithm as this codebase's whole-array `MaxHeapSort.swift`, scoped to `[pos, pos+len)`.
  private static func heapSort(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int) {
    guard len > 1 else { return }

    func siftDown(_ relRoot: Int, _ size: Int) {
      var root = relRoot
      while true {
        var largest = root
        let left = 2 * root + 1
        let right = 2 * root + 2
        if left < size && !engine.compare(pos + largest, pos + left) { largest = left }
        if right < size && !engine.compare(pos + largest, pos + right) { largest = right }
        if largest == root { break }
        engine.swap(pos + root, pos + largest)
        root = largest
      }
    }

    var i = len / 2 - 1
    while i >= 0 {
      siftDown(i, len)
      i -= 1
    }
    var end = len - 1
    while end > 0 {
      engine.swap(pos, pos + end)
      siftDown(0, end)
      end -= 1
    }
  }

  // MARK: - Branch-based partition

  /// Partitions `[begin, end)` around `engine.values[begin]`. Equal elements land to the right.
  /// Returns the pivot's final index and whether the input was already correctly partitioned.
  /// `engine.values[begin]` never changes until the final placement write, so every comparison
  /// against "the pivot" below is a live `engine.compare(_, begin, ...)` rather than a cached
  /// scalar read — matching ArrayV's own `Reads.compareValues` real-comparison tracking here
  /// (contrast with the branchless variant below, which deliberately reads raw values).
  private static func partRight(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int) -> (
    pivotPos: Int, alreadyParted: Bool
  ) {
    var first = begin
    var last = end

    repeat { first += 1 } while engine.compare(first, begin, by: <)

    if first - 1 == begin {
      repeat { last -= 1 } while first < last && !engine.compare(last, begin, by: <)
    } else {
      repeat { last -= 1 } while !engine.compare(last, begin, by: <)
    }

    let alreadyParted = first >= last
    while first < last {
      engine.swap(first, last)
      repeat { first += 1 } while engine.compare(first, begin, by: <)
      repeat { last -= 1 } while !engine.compare(last, begin, by: <)
    }

    let pivotPos = first - 1
    let pivotValue = engine.values[begin]
    engine.setValue(begin, engine.values[pivotPos])
    engine.setValue(pivotPos, pivotValue)
    return (pivotPos, alreadyParted)
  }

  /// Mirror of `partRight`, but equal elements land to the LEFT and no `alreadyParted` flag is
  /// tracked (only used for the "many equal elements" fast path, where it isn't needed).
  private static func partLeft(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int) -> Int {
    var first = begin
    var last = end

    repeat { last -= 1 } while engine.compare(begin, last, by: <)

    if last + 1 == end {
      repeat { first += 1 } while first < last && !engine.compare(begin, first, by: <)
    } else {
      repeat { first += 1 } while !engine.compare(begin, first, by: <)
    }

    while first < last {
      engine.swap(first, last)
      repeat { last -= 1 } while engine.compare(begin, last, by: <)
      repeat { first += 1 } while !engine.compare(begin, first, by: <)
    }

    let pivotPos = last
    let pivotValue = engine.values[begin]
    engine.setValue(begin, engine.values[pivotPos])
    engine.setValue(pivotPos, pivotValue)
    return pivotPos
  }

  // MARK: - Branchless (block quicksort) partition

  /// Given parallel offset arrays for the left/right scan blocks, either swaps every matched pair
  /// (needed for correctness on descending input, where `leftNum == rightNum` throughout) or does
  /// a cyclic single-pass move that saves about half the writes when the counts differ.
  private static func swapOffsets(
    _ engine: inout RecordingEngine, _ first: Int, _ last: Int,
    _ leftOffsets: [Int], _ leftOffsetsPos: Int,
    _ rightOffsets: [Int], _ rightOffsetsPos: Int,
    _ num: Int, _ useSwaps: Bool
  ) {
    if useSwaps {
      for i in 0..<num {
        engine.swap(first + leftOffsets[leftOffsetsPos + i], last - rightOffsets[rightOffsetsPos + i])
      }
    } else if num > 0 {
      var left = first + leftOffsets[leftOffsetsPos]
      var right = last - rightOffsets[rightOffsetsPos]
      let tmp = engine.values[left]
      engine.setValue(left, engine.values[right])
      for i in 1..<num {
        left = first + leftOffsets[leftOffsetsPos + i]
        engine.setValue(right, engine.values[left])
        right = last - rightOffsets[rightOffsetsPos + i]
        engine.setValue(left, engine.values[right])
      }
      engine.setValue(right, tmp)
    }
  }

  /// Same contract as `partRight`, but partitions via the block-quicksort technique from
  /// "BlockQuicksort: How Branch Mispredictions don't affect Quicksort" (Edelkamp & Weiss):
  /// scan `blockSize`-sized chunks from both ends recording which elements are on the wrong side
  /// into `offsets`, then swap matched wrong-side pairs `blockSize` at a time. Every comparison in
  /// here reads `engine.values` directly rather than going through `engine.compare` — matching
  /// ArrayV's own deliberate choice (`pdqLessThan`'s doc comment) not to track these as ordinary
  /// comparisons, since real branchless code has no per-comparison overhead to model.
  private static func partRightBranchless(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ offsets: inout PDQOffsetBuffers
  ) -> (pivotPos: Int, alreadyParted: Bool) {
    let pivot = engine.values[begin]
    var first = begin
    var last = end

    repeat { first += 1 } while engine.values[first] < pivot

    if first - 1 == begin {
      repeat { last -= 1 } while first < last && !(engine.values[last] < pivot)
    } else {
      repeat { last -= 1 } while !(engine.values[last] < pivot)
    }

    let alreadyParted = first >= last
    if !alreadyParted {
      engine.swap(first, last)
      first += 1
    }

    var leftNum = 0
    var rightNum = 0
    var leftStart = 0
    var rightStart = 0

    while last - first > 2 * blockSize {
      if leftNum == 0 {
        leftStart = 0
        var it = first
        for i in 0..<blockSize {
          offsets.left[leftNum] = i
          if !(engine.values[it] < pivot) { leftNum += 1 }
          it += 1
        }
      }
      if rightNum == 0 {
        rightStart = 0
        var it = last
        var i = 0
        while i < blockSize {
          i += 1
          offsets.right[rightNum] = i
          it -= 1
          if engine.values[it] < pivot { rightNum += 1 }
        }
      }

      let num = min(leftNum, rightNum)
      swapOffsets(
        &engine, first, last, offsets.left, leftStart, offsets.right, rightStart, num,
        leftNum == rightNum)
      leftNum -= num
      rightNum -= num
      leftStart += num
      rightStart += num
      if leftNum == 0 { first += blockSize }
      if rightNum == 0 { last -= blockSize }
    }

    var leftSize = 0
    var rightSize = 0
    let unknownLeft = (last - first) - ((rightNum != 0 || leftNum != 0) ? blockSize : 0)
    if rightNum != 0 {
      leftSize = unknownLeft
      rightSize = blockSize
    } else if leftNum != 0 {
      leftSize = blockSize
      rightSize = unknownLeft
    } else {
      leftSize = unknownLeft / 2
      rightSize = unknownLeft - leftSize
    }

    if unknownLeft != 0 && leftNum == 0 {
      leftStart = 0
      var it = first
      for i in 0..<leftSize {
        offsets.left[leftNum] = i
        if !(engine.values[it] < pivot) { leftNum += 1 }
        it += 1
      }
    }
    if unknownLeft != 0 && rightNum == 0 {
      rightStart = 0
      var it = last
      var i = 0
      while i < rightSize {
        i += 1
        offsets.right[rightNum] = i
        it -= 1
        if engine.values[it] < pivot { rightNum += 1 }
      }
    }

    let num = min(leftNum, rightNum)
    swapOffsets(
      &engine, first, last, offsets.left, leftStart, offsets.right, rightStart, num,
      leftNum == rightNum)
    leftNum -= num
    rightNum -= num
    leftStart += num
    rightStart += num
    if leftNum == 0 { first += leftSize }
    if rightNum == 0 { last -= rightSize }

    let leftOffsetsPos = leftStart
    let rightOffsetsPos = rightStart

    // We have now fully identified [first, last)'s proper position -- swap the last elements.
    if leftNum != 0 {
      while leftNum > 0 {
        leftNum -= 1
        last -= 1
        engine.swap(first + offsets.left[leftOffsetsPos + leftNum], last)
      }
      first = last
    }
    if rightNum != 0 {
      while rightNum > 0 {
        rightNum -= 1
        engine.swap(last - offsets.right[rightOffsetsPos + rightNum], first)
        first += 1
      }
      last = first
    }

    let pivotPos = first - 1
    engine.setValue(begin, engine.values[pivotPos])
    engine.setValue(pivotPos, pivot)

    return (pivotPos, alreadyParted)
  }

  // MARK: - Main driver

  /// The actual recursive quicksort loop, iterative via `while true` with tail-call elimination
  /// on the right partition (real recursion only on the left).
  private static func pdqLoop(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ branchless: Bool,
    _ badAllowedInput: Int, _ offsets: inout PDQOffsetBuffers
  ) {
    var begin = begin
    var badAllowed = badAllowedInput
    var leftmost = true

    while true {
      let size = end - begin

      if size < insertSortThreshold {
        if leftmost {
          insertSort(&engine, begin, end)
        } else {
          unguardInsertSort(&engine, begin, end)
        }
        return
      }

      // Pivot: median of 3 for smaller ranges, pseudomedian of 9 (four median-of-3s) above
      // `nintherThreshold`.
      let halfSize = size / 2
      if size > nintherThreshold {
        sortThree(&engine, begin, begin + halfSize, end - 1)
        sortThree(&engine, begin + 1, begin + (halfSize - 1), end - 2)
        sortThree(&engine, begin + 2, begin + (halfSize + 1), end - 3)
        sortThree(&engine, begin + (halfSize - 1), begin + halfSize, begin + (halfSize + 1))
        engine.swap(begin, begin + halfSize)
      } else {
        sortThree(&engine, begin + halfSize, begin, end - 1)
      }

      // Many-equal-elements fast path: if this isn't the leftmost partition and the pivot ties
      // the previous partition's right boundary, everything in [begin, end) equal to the pivot
      // is already correctly placed -- partition left-heavy and skip recursing on the left.
      if !leftmost && !engine.compare(begin - 1, begin, by: <) {
        begin = partLeft(&engine, begin, end) + 1
        continue
      }

      let (pivotPos, alreadyParted) =
        branchless
        ? partRightBranchless(&engine, begin, end, &offsets)
        : partRight(&engine, begin, end)

      let leftSize = pivotPos - begin
      let rightSize = end - (pivotPos + 1)
      let highUnbalance = leftSize < size / 8 || rightSize < size / 8

      if highUnbalance {
        badAllowed -= 1
        if badAllowed == 0 {
          // Too many bad partitions in a row -- guarantee O(n log n) via heapsort.
          heapSort(&engine, begin, end - begin)
          return
        }

        // Scramble a handful of elements near both partition boundaries to defeat adversarial
        // patterns (organ-pipe, median-of-3 killer, etc.).
        if leftSize >= insertSortThreshold {
          engine.swap(begin, begin + leftSize / 4)
          engine.swap(pivotPos - 1, pivotPos - leftSize / 4)
          if leftSize > nintherThreshold {
            engine.swap(begin + 1, begin + (leftSize / 4 + 1))
            engine.swap(begin + 2, begin + (leftSize / 4 + 2))
            engine.swap(pivotPos - 2, pivotPos - (leftSize / 4 + 1))
            engine.swap(pivotPos - 3, pivotPos - (leftSize / 4 + 2))
          }
        }
        if rightSize >= insertSortThreshold {
          engine.swap(pivotPos + 1, pivotPos + (1 + rightSize / 4))
          engine.swap(end - 1, end - rightSize / 4)
          if rightSize > nintherThreshold {
            engine.swap(pivotPos + 2, pivotPos + (2 + rightSize / 4))
            engine.swap(pivotPos + 3, pivotPos + (3 + rightSize / 4))
            engine.swap(end - 2, end - (1 + rightSize / 4))
            engine.swap(end - 3, end - (2 + rightSize / 4))
          }
        }
      } else if alreadyParted && partialInsertSort(&engine, begin, pivotPos)
        && partialInsertSort(&engine, pivotPos + 1, end) {
        // Balanced, and the input was already partitioned -- a cheap insertion-sort finish
        // handled both sides.
        return
      }

      pdqLoop(&engine, begin, pivotPos, branchless, badAllowed, &offsets)
      begin = pivotPos + 1
      leftmost = false
    }
  }

  // MARK: - Entry points

  static func sortBranched(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int) {
    var offsets = PDQOffsetBuffers(size: blockSize + cachelineSize)
    pdqLoop(&engine, begin, end, false, pdqLog(end - begin), &offsets)
  }

  static func sortBranchless(_ engine: inout RecordingEngine, _ begin: Int, _ end: Int) {
    var offsets = PDQOffsetBuffers(size: blockSize + cachelineSize)
    pdqLoop(&engine, begin, end, true, pdqLog(end - begin), &offsets)
  }
}
