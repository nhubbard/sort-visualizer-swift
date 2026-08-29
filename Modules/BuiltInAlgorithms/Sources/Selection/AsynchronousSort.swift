import AlgorithmKit
import SortEngineKit

public struct AsynchronousSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "asynchronoussort")
  public let metadata = AlgorithmMetadata(
    displayName: "Asynchronous Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 345, coefficients: [239085, 1383, 2],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2, 3, 0], rSquared: 1),
    implementationComplexity: 8,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n + k)", average: "O(n + k)", worst: "O(n + k)"),
    spaceComplexity: "O(n)",
    iconName: "timer"
  )
  public init() {}

  /// Despite ArrayV filing this among heap variants, it isn't heap-based — it's a
  /// counting/threshold-scan sort, same family as `CountingSort`. Repeatedly sweeps a saved copy
  /// (`ext`, shadowing the `extHandle` aux array) for every value `<=` a rising threshold `cur`,
  /// placing each match in the next output slot and marking it consumed (set to one past the true
  /// max). ArrayV's version ends with an `InsertionSort` cleanup pass needed for floats; omitted
  /// here since this engine only sorts `Int`s and the counting loop is already complete once `cur`
  /// reaches the true maximum.
  ///
  /// The inner scan re-reads `ext` — a real, repeated aux-buffer access, not a one-time read — so
  /// each read is marked via `markAuxRead`; the comparison itself is `ext[j] <= cur`, where
  /// neither side is a live array index (`ext[j]` is an aux value, `cur` a plain carried
  /// threshold), so it goes through `engine.compareValues`. This whole O(n × valueRange) scan was
  /// previously invisible to the tape/op count — the original motivating discovery for this fix,
  /// found via the recording-performance test flooring this algorithm's real duration at a
  /// 5-second trial timeout with no way to tell how much slower than 5s it actually was.
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
      for j in 0..<n {
        engine.markAuxRead(extHandle, at: j)
        if engine.compareValues(ext[j], cur, by: (<=)) {
          engine.setValue(i, ext[j])
          ext[j] = maxValue
          engine.writeAux(extHandle, at: j, value: maxValue)
          i += 1
        }
      }
      cur += 1
    }

    engine.deleteAuxArray(extHandle)
  }
}
