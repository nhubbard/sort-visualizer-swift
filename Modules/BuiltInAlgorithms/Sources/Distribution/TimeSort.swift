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
/// scratch copy by value (ties broken by original index, exactly what noise-free monotonic sleep
/// durations would produce), written into place in that order. Keeping ArrayV's own insertion-sort
/// cleanup pass afterward — rather than trusting the simulated wake order outright — means
/// correctness never secretly depends on that simulation being flawless, the same defensive
/// posture the real algorithm has for the same reason.
public struct TimeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "timesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Time Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 304, coefficients: [2064.16, 6.3784],
      measuredSafeCeiling: nil),
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
    var scratch: [(value: Int, originalIndex: Int)] = []
    for i in 0..<n {
      scratch.append((engine.values[i], i))
      engine.writeAux(scratchHandle, at: i, value: engine.values[i])
    }

    let wakeOrder = scratch.sorted { lhs, rhs in
      lhs.value != rhs.value ? lhs.value < rhs.value : lhs.originalIndex < rhs.originalIndex
    }.map(\.value)

    for i in 0..<n {
      engine.setValue(i, wakeOrder[i])
    }
    engine.deleteAuxArray(scratchHandle)

    // ArrayV's own defensive cleanup pass — a no-op here since `wakeOrder` is already sorted,
    // but kept so correctness doesn't quietly depend on that.
    for i in 1..<n {
      var j = i
      while j > 0 && engine.compare(j - 1, j, by: (>)) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }
}
