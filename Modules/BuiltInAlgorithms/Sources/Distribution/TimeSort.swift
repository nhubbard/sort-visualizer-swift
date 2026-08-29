import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `TimeSort` — a real "sleep sort": one thread per element sleeps for a
/// duration proportional to that element's value, then reports itself into the next output slot
/// on waking. Sleep duration is monotonic in value, so a jitter-free race reports elements in
/// non-decreasing order on its own — but ArrayV doesn't actually trust that: after every thread
/// reports, it runs a *real* insertion-sort cleanup pass over the result, defending against
/// whatever real OS thread-scheduling jitter might have done to the ordering.
///
/// A live thread race has no meaning in `RecordingEngine`'s single deterministic tape, so this
/// substitutes the *idealized*, jitter-free outcome that race is chasing: a stable sort of a
/// scratch copy by value (a standard stable merge naturally breaks ties by original index, exactly
/// what noise-free monotonic sleep durations would produce), written into place in that order.
/// Keeping ArrayV's own insertion-sort cleanup pass afterward — rather than trusting the simulated
/// wake order outright — means correctness never secretly depends on that simulation being
/// flawless, the same defensive posture the real algorithm has for the same reason.
///
/// The wake-order simulation used to be a single untracked `Array.sorted()` call — real O(n log n)
/// comparison work with zero `RecordingEngine` visibility, since neither operand of any of those
/// comparisons was ever a live array index. Replaced with an explicit stable merge sort whose
/// comparisons go through `engine.compareValues`, so this algorithm's real cost finally shows up
/// in `compareCount` instead of looking like `n` free writes.
public struct TimeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "timesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Time Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 11060, coefficients: [161628, 14.4775],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.65303, 0.883283], rSquared: 0.999378),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "timer"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let scratchHandle = engine.createAuxArray(length: n)
    var scratch = [Int](repeating: 0, count: n)
    for i in 0..<n {
      scratch[i] = engine.values[i]
      engine.writeAux(scratchHandle, at: i, value: scratch[i])
    }

    // `buffer` is pure merge-sort bookkeeping, never mirrored into a visualized aux array — same
    // precedent as `TwinSortingTemplate.tailMerge`'s own `swap` buffer.
    var buffer = scratch
    Self.mergeSort(&engine, &scratch, &buffer, 0, n)

    for i in 0..<n {
      engine.setValue(i, scratch[i])
    }
    engine.deleteAuxArray(scratchHandle)

    // ArrayV's own defensive cleanup pass — a no-op here since `scratch` is already sorted, but
    // kept so correctness doesn't quietly depend on that.
    for i in 1..<n {
      var j = i
      while j > 0 && engine.compare(j - 1, j, by: (>)) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }

  /// Standard top-down stable merge sort over the held scratch copy — "take from the left half
  /// whenever it's `<=` the right half" is what makes this stable without needing to track
  /// original indices separately: neither half ever internally reorders equal elements, so the
  /// merge step alone preserves their relative order.
  private static func mergeSort(
    _ engine: inout RecordingEngine, _ array: inout [Int], _ buffer: inout [Int], _ lo: Int,
    _ hi: Int
  ) {
    guard hi - lo > 1 else { return }
    let mid = lo + (hi - lo) / 2
    mergeSort(&engine, &array, &buffer, lo, mid)
    mergeSort(&engine, &array, &buffer, mid, hi)

    var i = lo
    var j = mid
    var k = lo
    while i < mid && j < hi {
      if engine.compareValues(array[i], array[j], by: (<=)) {
        buffer[k] = array[i]
        i += 1
      } else {
        buffer[k] = array[j]
        j += 1
      }
      k += 1
    }
    while i < mid {
      buffer[k] = array[i]
      i += 1
      k += 1
    }
    while j < hi {
      buffer[k] = array[j]
      j += 1
      k += 1
    }
    for x in lo..<hi {
      array[x] = buffer[x]
    }
  }
}
