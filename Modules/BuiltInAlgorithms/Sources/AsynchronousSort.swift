import AlgorithmKit
import SortEngineKit

public struct AsynchronousSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "asynchronoussort")
  public let metadata = AlgorithmMetadata(
    displayName: "Asynchronous Sort",
    category: .selection,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n + k)", average: "O(n + k)", worst: "O(n + k)"),
    spaceComplexity: "O(n)",
    iconName: "timer"
  )
  public init() {}

  /// Despite living among the heap variants in ArrayV's "Selection Sorts" bucket, this isn't
  /// heap-based at all — it's a counting/threshold-scan sort, same family as `CountingSort`, so
  /// it reads `engine.values` directly for the value-dependent decisions (which value range the
  /// original doesn't even have a heap to search in) rather than `engine.compare`, matching
  /// `CountingSort.swift`'s own precedent for ArrayV's non-stat-tracked `Reads.analyzeMax`-style
  /// reads. Repeatedly sweeps a saved copy for every value `<=` a rising threshold `cur`, placing
  /// each such value in the next output slot and marking it consumed (set to one past the true
  /// max, so it's never matched again) — guaranteed to place every element once `cur` reaches the
  /// true maximum. ArrayV's own version ends with an `InsertionSort` cleanup pass "necessary for
  /// floats" — this engine only ever sorts `Int`s, and the counting loop above is already
  /// provably complete (every value is `<=` the true max, which `cur` always reaches) by the time
  /// it exits, so that fallback has nothing left to do here and is omitted.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    let extHandle = engine.createAuxArray(length: n)
    var ext = [Int](repeating: 0, count: n)
    var minValue = engine.values[0]
    var maxValue = engine.values[0]
    for i in 0..<n {
      ext[i] = engine.values[i]
      engine.writeAux(extHandle, at: i, value: ext[i])
      if ext[i] < minValue { minValue = ext[i] }
      if ext[i] > maxValue { maxValue = ext[i] }
    }
    maxValue += 1

    var cur = minValue
    var i = 0
    while i < n {
      for j in 0..<n where ext[j] <= cur {
        engine.setValue(i, ext[j])
        ext[j] = maxValue
        engine.writeAux(extHandle, at: j, value: maxValue)
        i += 1
      }
      cur += 1
    }

    engine.deleteAuxArray(extHandle)
  }
}
