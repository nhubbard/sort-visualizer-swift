import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.CIRCLE`. Fully randomizes the array via Fisher-Yates, then runs
/// exactly one top-level pass of Circle Sort's own recursive comparator routine over it (padded to
/// the next power of two, out-of-range comparisons skipped) — a single pass barely dents a fully
/// random array, hence "first" circle pass.
public struct CircleShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "circle")
  public let metadata = ShuffleMetadata(displayName: "First Circle Pass")
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    var i = n - 1
    while i > 0 {
      let j = Int.random(in: 0...i)
      engine.swap(i, j)
      i -= 1
    }

    var paddedLength = 1
    while paddedLength < n {
      paddedLength <<= 1
    }
    circleSortRoutine(&engine, lo: 0, hi: paddedLength - 1, end: n)
  }

  private func circleSortRoutine(_ engine: inout RecordingEngine, lo: Int, hi: Int, end: Int) {
    guard lo != hi else { return }

    let high = hi
    let low = lo
    let mid = (hi - lo) / 2

    var lo = lo
    var hi = hi
    while lo < hi {
      if hi < end && engine.compare(lo, hi, by: (>)) {
        engine.swap(lo, hi)
      }
      lo += 1
      hi -= 1
    }

    circleSortRoutine(&engine, lo: low, hi: low + mid, end: end)
    if low + mid + 1 < end {
      circleSortRoutine(&engine, lo: low + mid + 1, hi: high, end: end)
    }
  }
}
