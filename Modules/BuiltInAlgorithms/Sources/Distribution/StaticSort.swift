import AlgorithmKit
import SortEngineKit

/// Static Sort — ArrayV's `StaticSort` ("Simple Static Sort"). A distribution sort: classifies
/// each element into one of `n` buckets via a linear formula on its value's position between
/// min/max, cycle-permutes elements into contiguous per-bucket regions in place (same
/// evict/place/adopt technique as `CycleSort`/`FlashSort`), then finishes each bucket with
/// Insertion Sort (<=16 elements) or Heap Sort (larger).
///
/// `CONST = auxLen / (max - min + 1)` — the `+ 1` keeps this finite even when every element is
/// identical (unlike `FlashSort`'s unguarded `c = (m-1)/(max-min)`), so no zero-division guard is
/// needed here.
///
/// The finishing loop computes each bucket's start as `(i > 1) ? offset[i - 1] : a`, so bucket 1's
/// range also re-covers bucket 0's. Not a bug: `classify` is non-decreasing in value, so bucket
/// 0's elements are always `<=` bucket 1's — the only effect is redundant re-scanning when
/// `i == 1`. Ported exactly as ArrayV wrote it.
///
/// Stability: `false` — the cycle-permutation is value-only, and Heap Sort isn't stable either.
public struct StaticSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "staticsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Static Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 6815, coefficients: [135181, 21.4058],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [3.03765, 0.965855], rSquared: 0.983209),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "rectangle.grid.3x2.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    staticSort(into: &engine, a: 0, b: n)
  }

  /// Ports ArrayV's `findMinMax`: a held-value-vs-live-index-value scan, not a stat-tracked
  /// `engine.compare` — it's comparing a live array value against a running local min/max, the
  /// same held-value pattern `CycleSort`'s `t` and `FlashSort`'s own min/max scan already use.
  private func findMinMax(_ engine: RecordingEngine, _ a: Int, _ b: Int) -> (min: Int, max: Int) {
    var minValue = engine.values[a]
    var maxValue = minValue
    var i = a + 1
    while i < b {
      let v = engine.values[i]
      if v < minValue {
        minValue = v
      } else if v > maxValue {
        maxValue = v
      }
      i += 1
    }
    return (minValue, maxValue)
  }

  private func staticSort(into engine: inout RecordingEngine, a: Int, b: Int) {
    let (minValue, maxValue) = findMinMax(engine, a, b)
    let auxLen = b - a

    // See the type-level doc comment: `CONST`'s `+ 1` denominator keeps this finite even when
    // `maxValue == minValue` (every element identical) — no guard needed, unlike `FlashSort`.
    let CONST = Double(auxLen) / Double(maxValue - minValue + 1)
    func classify(_ value: Int) -> Int {
      Int(Double(value - minValue) * CONST)
    }

    // Local shadows of ArrayV's `count`/`offset` (`Writes.createExternalArray(auxLen + 1)`
    // each) — plain Swift `[Int]` arrays kept alongside their aux-array handles since
    // `RecordingEngine.writeAux` has no read-back API, the same precedent `CountingSort`'s
    // `counts`/`output` and `FlashSort`'s `L` establish.
    let countHandle = engine.createAuxArray(length: auxLen + 1)
    let offsetHandle = engine.createAuxArray(length: auxLen + 1)
    var count = [Int](repeating: 0, count: auxLen + 1)
    var offset = [Int](repeating: 0, count: auxLen + 1)

    for i in a..<b {
      let idx = classify(engine.values[i])
      count[idx] += 1
      engine.writeAux(countHandle, at: idx, value: count[idx])
    }

    offset[0] = a
    engine.writeAux(offsetHandle, at: 0, value: offset[0])
    for i in 1..<auxLen {
      offset[i] = count[i - 1] + offset[i - 1]
      engine.writeAux(offsetHandle, at: i, value: offset[i])
    }

    // -------CYCLE-PERMUTE INTO BUCKET REGIONS-------
    // Same "evict, place, adopt" idea as CycleSort/FlashSort's permutation phases, using
    // `offset`/`count` as the shrinking per-bucket write cursors instead of a single global
    // scan (CycleSort) or one shared `L` array (FlashSort).
    for v in 0..<auxLen {
      while count[v] > 0 {
        let origin = offset[v]
        var from = origin
        var num = engine.values[from]

        // Transient sentinel write matching ArrayV's `Writes.write(array, from, -1, ...)`.
        // `-1` is never a valid value here (shuffles are always `Array(1...size)`), so this
        // is bookkeeping only — immediately overwritten before the cycle closes.
        engine.setValue(from, -1)

        repeat {
          let idx = classify(num)
          let to = offset[idx]
          offset[idx] += 1
          engine.writeAux(offsetHandle, at: idx, value: offset[idx])
          count[idx] -= 1
          engine.writeAux(countHandle, at: idx, value: count[idx])

          let temp = engine.values[to]
          engine.setValue(to, num)
          num = temp
          from = to
        } while from != origin
      }
    }

    engine.deleteAuxArray(countHandle)
    engine.deleteAuxArray(offsetHandle)

    // -------FINISH EACH BUCKET-------
    // See the type-level doc comment on `i > 1` vs `i > 0`: ported exactly as ArrayV wrote it.
    for i in 0..<auxLen {
      let s = (i > 1) ? offset[i - 1] : a
      let e = offset[i]
      if e - s <= 1 { continue }
      if e - s > 16 {
        heapSortRange(&engine, s, e)
      } else {
        insertionSortRange(&engine, s, e)
      }
    }
  }

  /// A private, range-scoped ([s, e)) version of `InsertionSort.swift`'s own swap-based logic —
  /// does not call into or modify the shared `InsertionSort` type.
  private func insertionSortRange(_ engine: inout RecordingEngine, _ s: Int, _ e: Int) {
    guard e - s > 1 else { return }
    for i in (s + 1)..<e {
      var j = i
      while j > s && !engine.compare(j, j - 1) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }

  /// A private, range-scoped ([s, e)) version of `MaxHeapSort.swift`'s own logic — every index
  /// `MaxHeapSort` treats as absolute (0-based, up to `size`) is offset by `s` here, and `size`
  /// shrinks exactly the way `MaxHeapSort`'s own `end` does. Does not call into or modify the
  /// shared `MaxHeapSort` type.
  private func heapSortRange(_ engine: inout RecordingEngine, _ s: Int, _ e: Int) {
    let size = e - s
    guard size > 1 else { return }

    func siftDown(_ root: Int, _ size: Int) {
      var root = root
      while true {
        var largest = root
        let left = 2 * root + 1
        let right = 2 * root + 2
        if left < size && !engine.compare(s + largest, s + left) {
          largest = left
        }
        if right < size && !engine.compare(s + largest, s + right) {
          largest = right
        }
        if largest == root { break }
        engine.swap(s + root, s + largest)
        root = largest
      }
    }

    var i = size / 2 - 1
    while i >= 0 {
      siftDown(i, size)
      i -= 1
    }
    var end = size - 1
    while end > 0 {
      engine.swap(s, s + end)
      siftDown(0, end)
      end -= 1
    }
  }
}
