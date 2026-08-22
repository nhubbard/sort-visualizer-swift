import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.PDQ_BAD`. A self-contained adversarial arrangement targeting
/// pattern-defeating quicksort's worst case — embeds its own copy of pdqsort's branch-based
/// partition scheme (structurally the same shape as `PDQSortingTemplate.swift`'s branch-based
/// half, which this doesn't depend on or reuse — ArrayV's own `PDQ_BAD` embeds its own copy too,
/// independent of whether `PDQBranchedSort` exists) driven by a custom comparator instead of `<`.
/// The branchless block-quicksort partition is never needed here: ArrayV's `PDQ_BAD` always drives
/// its embedded `pdqLoop` with `branchless: false`.
///
/// The comparator (`less`) *is* the adversary: it lazily assigns each element a "frozen rank" the
/// first time it's compared against something other than the current "candidate" (the one element
/// perpetually deferred, matching ArrayV's own `compare(ap, bp)`), so pdqsort ends up sorting
/// exactly the sequence of comparisons it happens to make against itself. `RecordingEngine.compare`
/// already looks up `values[i]`/`values[j]` before calling its closure, so passing `less` as that
/// closure means positions go in, values come out — no separate lookup needed.
///
/// Every position starts holding its own identity label (`engine.setValue(i, i)`) before the sort
/// runs, and those labels only ever move via swaps, never get overwritten — so `temp`, built by
/// `less` keyed on *label*, ends up keyed on *original position* too (the same numeric domain). The
/// final gather (`copy[temp[i] - 1]`) uses that directly: `temp[i]` is the frozen rank the label
/// that started at position `i` ended up with.
///
/// Held-value comparisons in the insertion-sort helpers (`less(tmp, engine.values[pos])`) call
/// `less` directly rather than through `engine.compare` — there's no live position for the held
/// value, the same convention `SmoothSort.swift`/`PoplarHeapSort.swift` already use for their own
/// held-value comparisons (an intentionally uncounted comparison, not a new departure).
public struct PDQAdversaryShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "pdqbad")
  public let metadata = ShuffleMetadata(displayName: "PDQ Adversary")
  public init() {}

  private static let insertSortThreshold = 24
  private static let nintherThreshold = 128
  private static let partialInsertSortLimit = 8

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let gas = n
    var temp = [Int](repeating: gas, count: n)
    var hasCandidate = false
    var candidate = 0
    var frozen = 1

    func less(_ a: Int, _ b: Int) -> Bool {
      if !hasCandidate {
        candidate = 0
        hasCandidate = true
      }
      if temp[a] == gas && temp[b] == gas {
        if a == candidate {
          temp[a] = frozen
          frozen += 1
        } else {
          temp[b] = frozen
          frozen += 1
        }
      }
      if temp[a] == gas {
        candidate = a
        return false
      }
      if temp[b] == gas {
        candidate = b
        return true
      }
      return temp[a] < temp[b]
    }

    let copy = engine.values
    for i in 0..<n {
      engine.setValue(i, i)
    }

    pdqLoop(&engine, 0, n, badAllowed: pdqLog(n), less: less)

    for i in 0..<n {
      engine.setValue(i, copy[temp[i] - 1])
    }
  }

  private func pdqLog(_ nIn: Int) -> Int {
    var n = nIn
    var log = 0
    n >>= 1
    while n != 0 {
      log += 1
      n >>= 1
    }
    return log
  }

  // MARK: - Insertion sort family

  private func insertSort(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ less: (Int, Int) -> Bool
  ) {
    guard begin != end else { return }
    for cur in (begin + 1)..<end where engine.compare(cur, cur - 1, by: less) {
      let tmp = engine.values[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      repeat {
        engine.setValue(sift, engine.values[siftMinusOne])
        sift -= 1
        siftMinusOne -= 1
      } while sift != begin && less(tmp, engine.values[siftMinusOne])
      engine.setValue(sift, tmp)
    }
  }

  private func unguardInsertSort(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ less: (Int, Int) -> Bool
  ) {
    guard begin != end else { return }
    for cur in (begin + 1)..<end where engine.compare(cur, cur - 1, by: less) {
      let tmp = engine.values[cur]
      var sift = cur
      var siftMinusOne = cur - 1
      repeat {
        engine.setValue(sift, engine.values[siftMinusOne])
        sift -= 1
        siftMinusOne -= 1
      } while less(tmp, engine.values[siftMinusOne])
      engine.setValue(sift, tmp)
    }
  }

  private func partialInsertSort(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ less: (Int, Int) -> Bool
  ) -> Bool {
    guard begin != end else { return true }
    var limit = 0
    for cur in (begin + 1)..<end {
      if limit > Self.partialInsertSortLimit { return false }
      if engine.compare(cur, cur - 1, by: less) {
        let tmp = engine.values[cur]
        var sift = cur
        var siftMinusOne = cur - 1
        repeat {
          engine.setValue(sift, engine.values[siftMinusOne])
          sift -= 1
          siftMinusOne -= 1
        } while sift != begin && less(tmp, engine.values[siftMinusOne])
        engine.setValue(sift, tmp)
        limit += cur - sift
      }
    }
    return true
  }

  // MARK: - Pivot selection

  private func sortTwo(
    _ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ less: (Int, Int) -> Bool
  ) {
    if engine.compare(b, a, by: less) {
      engine.swap(a, b)
    }
  }

  private func sortThree(
    _ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ c: Int, _ less: (Int, Int) -> Bool
  ) {
    sortTwo(&engine, a, b, less)
    sortTwo(&engine, b, c, less)
    sortTwo(&engine, a, b, less)
  }

  // MARK: - Range-scoped heap-build fallback

  /// Builds a max-heap over `[begin, end)` and stops — matching ArrayV's own (deliberately
  /// truncated) fallback exactly: no extraction phase, just enough real comparisons to keep
  /// `less`'s bookkeeping moving.
  private func heapBuildFallback(
    _ engine: inout RecordingEngine, _ begin: Int, _ length: Int, _ less: (Int, Int) -> Bool
  ) {
    func siftDown(_ rootIn: Int) {
      var root = rootIn
      while root <= length / 2 {
        var leaf = 2 * root
        if leaf < length && engine.compare(begin + leaf - 1, begin + leaf, by: less) {
          leaf += 1
        }
        if engine.compare(begin + root - 1, begin + leaf - 1, by: less) {
          engine.swap(begin + root - 1, begin + leaf - 1)
          root = leaf
        } else {
          break
        }
      }
    }
    var i = length / 2
    while i >= 1 {
      siftDown(i)
      i -= 1
    }
  }

  // MARK: - Branch-based partition

  private func partRight(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ less: (Int, Int) -> Bool
  ) -> (pivotPos: Int, alreadyParted: Bool) {
    var first = begin
    var last = end

    repeat { first += 1 } while engine.compare(first, begin, by: less)

    if first - 1 == begin {
      repeat { last -= 1 } while first < last && !engine.compare(last, begin, by: less)
    } else {
      repeat { last -= 1 } while !engine.compare(last, begin, by: less)
    }

    let alreadyParted = first >= last
    while first < last {
      engine.swap(first, last)
      repeat { first += 1 } while engine.compare(first, begin, by: less)
      repeat { last -= 1 } while !engine.compare(last, begin, by: less)
    }

    let pivotPos = first - 1
    let pivotValue = engine.values[begin]
    engine.setValue(begin, engine.values[pivotPos])
    engine.setValue(pivotPos, pivotValue)
    return (pivotPos, alreadyParted)
  }

  private func partLeft(
    _ engine: inout RecordingEngine, _ begin: Int, _ end: Int, _ less: (Int, Int) -> Bool
  ) -> Int {
    var first = begin
    var last = end

    repeat { last -= 1 } while engine.compare(begin, last, by: less)

    if last + 1 == end {
      repeat { first += 1 } while first < last && !engine.compare(begin, first, by: less)
    } else {
      repeat { first += 1 } while !engine.compare(begin, first, by: less)
    }

    while first < last {
      engine.swap(first, last)
      repeat { last -= 1 } while engine.compare(begin, last, by: less)
      repeat { first += 1 } while !engine.compare(begin, first, by: less)
    }

    let pivotPos = last
    let pivotValue = engine.values[begin]
    engine.setValue(begin, engine.values[pivotPos])
    engine.setValue(pivotPos, pivotValue)
    return pivotPos
  }

  // MARK: - Main driver

  private func pdqLoop(
    _ engine: inout RecordingEngine, _ beginIn: Int, _ end: Int, badAllowed badAllowedIn: Int,
    less: (Int, Int) -> Bool
  ) {
    var begin = beginIn
    var badAllowed = badAllowedIn
    var leftmost = true

    while true {
      let size = end - begin

      if size < Self.insertSortThreshold {
        if leftmost {
          insertSort(&engine, begin, end, less)
        } else {
          unguardInsertSort(&engine, begin, end, less)
        }
        return
      }

      let halfSize = size / 2
      if size > Self.nintherThreshold {
        sortThree(&engine, begin, begin + halfSize, end - 1, less)
        sortThree(&engine, begin + 1, begin + (halfSize - 1), end - 2, less)
        sortThree(&engine, begin + 2, begin + (halfSize + 1), end - 3, less)
        sortThree(&engine, begin + (halfSize - 1), begin + halfSize, begin + (halfSize + 1), less)
        engine.swap(begin, begin + halfSize)
      } else {
        sortThree(&engine, begin + halfSize, begin, end - 1, less)
      }

      if !leftmost && !engine.compare(begin - 1, begin, by: less) {
        begin = partLeft(&engine, begin, end, less) + 1
        continue
      }

      let (pivotPos, alreadyParted) = partRight(&engine, begin, end, less)

      let leftSize = pivotPos - begin
      let rightSize = end - (pivotPos + 1)
      let highUnbalance = leftSize < size / 8 || rightSize < size / 8

      if highUnbalance {
        badAllowed -= 1
        if badAllowed == 0 {
          heapBuildFallback(&engine, begin, end - begin, less)
          return
        }

        if leftSize >= Self.insertSortThreshold {
          engine.swap(begin, begin + leftSize / 4)
          engine.swap(pivotPos - 1, pivotPos - leftSize / 4)
          if leftSize > Self.nintherThreshold {
            engine.swap(begin + 1, begin + (leftSize / 4 + 1))
            engine.swap(begin + 2, begin + (leftSize / 4 + 2))
            engine.swap(pivotPos - 2, pivotPos - (leftSize / 4 + 1))
            engine.swap(pivotPos - 3, pivotPos - (leftSize / 4 + 2))
          }
        }
        if rightSize >= Self.insertSortThreshold {
          engine.swap(pivotPos + 1, pivotPos + (1 + rightSize / 4))
          engine.swap(end - 1, end - rightSize / 4)
          if rightSize > Self.nintherThreshold {
            engine.swap(pivotPos + 2, pivotPos + (2 + rightSize / 4))
            engine.swap(pivotPos + 3, pivotPos + (3 + rightSize / 4))
            engine.swap(end - 2, end - (1 + rightSize / 4))
            engine.swap(end - 3, end - (2 + rightSize / 4))
          }
        }
      } else if alreadyParted
        && partialInsertSort(&engine, begin, pivotPos, less)
        && partialInsertSort(&engine, pivotPos + 1, end, less) {
        return
      }

      pdqLoop(&engine, begin, pivotPos, badAllowed: badAllowed, less: less)
      begin = pivotPos + 1
      leftmost = false
    }
  }
}
