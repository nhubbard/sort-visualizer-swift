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

  /// Despite ArrayV filing this among heap variants, it isn't heap-based — it's a
  /// counting/threshold-scan sort, same family as `CountingSort`, so value-dependent decisions
  /// read `engine.values` directly rather than `engine.compare`. Repeatedly sweeps a saved copy
  /// for every value `<=` a rising threshold `cur`, placing each match in the next output slot and
  /// marking it consumed (set to one past the true max). ArrayV's version ends with an
  /// `InsertionSort` cleanup pass needed for floats; omitted here since this engine only sorts
  /// `Int`s and the counting loop is already complete once `cur` reaches the true maximum.
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
