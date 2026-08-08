import AlgorithmKit
import SortEngineKit

/// A poplar heap (Morwenn's "poplar sort") sorted by repeated max-extraction — a "poplar" is a
/// complete binary heap of size `2^k - 1`, and the whole array is covered by a run of poplars
/// whose sizes follow the binary representation of a running element count (a binary-carry
/// sequence), the same way `SmoothSort.swift`'s Leonardo heaps follow a Fibonacci-like sequence
/// instead. Below a threshold of 15 elements, both `make_heap` and any leftover tail just fall
/// back to plain insertion sort, since a single poplar/Leonardo heap that small has no real
/// structural advantage over it.
///
/// Two deliberate, correctness-motivated departures from ArrayV's `PoplarHeapSort.java`:
/// - `hyperfloor(n)` (the largest power of two `<= n`) is computed here via
///   `Int.leadingZeroBitCount` rather than ArrayV's `(int) Math.pow(2, Math.floor(Math.log(n) /
///   Math.log(2)))` — floating-point `log`'s rounding error can push an exact power of two's
///   `log(n)/log(2)` a hair below its true integer value (e.g. yielding `2.9999999996` instead of
///   `3.0`), silently returning half the correct answer right at a heap-size boundary. The
///   integer bit-count version can't have that failure mode and always gives the exact answer.
/// - `makeHeap`'s merge step bails out of merging two same-size poplars once doing so would run
///   past `last` — a real, reproducible out-of-bounds crash in ArrayV's own `make_heap`, verified
///   independently against a from-scratch Java transcription of `make_heap`/`sort_heap`, not just
///   this Swift port: reverse-sorted input of length 62 (and 125, 126, 189, 252, 253, 254 — several
///   within this app's own `16...256` size range) throws
///   `ArrayIndexOutOfBoundsException`/traps, because the binary-carry merge sequence assumes an
///   extra "spare" element always exists past the two poplars being combined, which isn't true
///   once the merge would reach past the array's actual end. Leaving that merge for a later pass
///   (once more elements have been folded in) instead of forcing it now is the minimal fix;
///   verified correct by fuzzing every size from 2 to 300 many times over, matching the
///   `FunSort`/`StablePermutationSort` precedent that an ArrayV source's own behavior isn't proof
///   of correctness.
///
/// `unchecked_insertion_sort`/`sift` hold a candidate in a plain local (`val`/`tmp`), only
/// writing it to its final resting index once found — the same "hole" shape as
/// `SmoothSort.swift`'s `sift`/`trinkle`, so comparisons against that held value read
/// `engine.values` directly rather than through `engine.compare`, while comparisons between two
/// genuinely live indices still go through `engine.compare` for real marking/counting — same
/// convention, same reasoning, as that file's own doc comment.
///
/// Stability: `false` — heap extraction reorders equal elements the same way any heap-shaped
/// sift can.
public struct PoplarHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "poplarheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Poplar Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1158, coefficients: [239862, 359.367, 0.130811],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "tree.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    makeHeap(&engine, 0, n)
    sortHeap(&engine, 0, n)
  }

  public func poplarHeapify(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    makeHeap(&engine, 0, n)
  }

  private func hyperfloor(_ n: Int) -> Int {
    1 &<< (Int.bitWidth - n.leadingZeroBitCount - 1)
  }

  private func uncheckedInsertionSort(_ engine: inout RecordingEngine, _ first: Int, _ last: Int) {
    var cur = first + 1
    while cur != last {
      if engine.compare(cur, cur - 1, by: <) {
        let tmp = engine.values[cur]
        var sift = cur
        var sift1 = cur - 1
        while true {
          engine.setValue(sift, engine.values[sift1])
          sift -= 1
          if sift == first { break }
          sift1 -= 1
          if tmp >= engine.values[sift1] { break }
        }
        engine.setValue(sift, tmp)
      }
      cur += 1
    }
  }

  private func insertionSort(_ engine: inout RecordingEngine, _ first: Int, _ last: Int) {
    guard first != last else { return }
    uncheckedInsertionSort(&engine, first, last)
  }

  private func poplarSift(_ engine: inout RecordingEngine, _ firstIn: Int, _ sizeIn: Int) {
    var size = sizeIn
    guard size >= 2 else { return }
    var root = firstIn + (size - 1)
    var childRoot1 = root - 1
    var childRoot2 = firstIn + (size / 2 - 1)
    while true {
      var maxRoot = root
      if engine.compare(maxRoot, childRoot1, by: <) { maxRoot = childRoot1 }
      if engine.compare(maxRoot, childRoot2, by: <) { maxRoot = childRoot2 }
      if maxRoot == root { return }
      engine.swap(root, maxRoot)
      size /= 2
      if size < 2 { return }
      root = maxRoot
      childRoot1 = root - 1
      childRoot2 = maxRoot - (size - size / 2)
    }
  }

  private func popHeapWithSize(_ engine: inout RecordingEngine, _ first: Int, _ last: Int, _ sizeIn: Int) {
    var size = sizeIn
    var poplarSize = hyperfloor(size + 1) - 1
    let lastRoot = last - 1
    var bigger = lastRoot
    var biggerSize = poplarSize

    var it = first
    while true {
      let root = it + poplarSize - 1
      if root == lastRoot { break }
      if engine.compare(bigger, root, by: <) {
        bigger = root
        biggerSize = poplarSize
      }
      it = root + 1
      size -= poplarSize
      poplarSize = hyperfloor(size + 1) - 1
    }

    if bigger != lastRoot {
      engine.swap(bigger, lastRoot)
      poplarSift(&engine, bigger - (biggerSize - 1), biggerSize)
    }
  }

  private func makeHeap(_ engine: inout RecordingEngine, _ first: Int, _ last: Int) {
    let size = last - first
    guard size >= 2 else { return }
    let smallPoplarSize = 15
    if size <= smallPoplarSize {
      uncheckedInsertionSort(&engine, first, last)
      return
    }

    var poplarLevel = 1
    var it = first
    var next = it + smallPoplarSize
    while true {
      uncheckedInsertionSort(&engine, it, next)
      var poplarSize = smallPoplarSize
      var i = (poplarLevel & -poplarLevel) &>> 1
      while i != 0 {
        it -= poplarSize
        poplarSize = 2 * poplarSize + 1
        if it + poplarSize > last { break }
        poplarSift(&engine, it, poplarSize)
        next += 1
        i = i &>> 1
      }
      if (last - next) <= smallPoplarSize {
        insertionSort(&engine, next, last)
        return
      }
      it = next
      next += smallPoplarSize
      poplarLevel += 1
    }
  }

  private func sortHeap(_ engine: inout RecordingEngine, _ first: Int, _ lastIn: Int) {
    var last = lastIn
    var size = last - first
    guard size >= 2 else { return }
    repeat {
      popHeapWithSize(&engine, first, last, size)
      last -= 1
      size -= 1
    } while size > 1
  }
}
