import AlgorithmKit
import SortEngineKit

/// ArrayV's `PigeonholeSort`, a `.distribution` cousin of `CountingSort`: both tally value
/// occurrences into an aux array sized to the value range, then re-emit in ascending order.
/// Unlike `CountingSort`'s cumulative prefix-sum re-emission (which preserves original positions),
/// this walks holes in ascending order and writes each value out by raw count, discarding original
/// positions — so it is NOT stable, unlike `CountingSort`.
public struct PigeonholeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pigeonholesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Pigeonhole Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 79999, coefficients: [239997, 3],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n+k)", average: "O(n+k)", worst: "O(n+k)"),
    spaceComplexity: "O(n+k)",
    iconName: "square.grid.3x3.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    // ArrayV's min/max scan reads values directly (no stat-tracked compares), so this reads
    // `engine.values` and compares against the plain local `min`/`max` variables rather than
    // going through `engine.compare` — the same held-value pattern as `CycleSort`'s `t`.
    var minValue = engine.values[0]
    var maxValue = engine.values[0]
    for i in 1..<n {
      if engine.values[i] < minValue { minValue = engine.values[i] }
      if engine.values[i] > maxValue { maxValue = engine.values[i] }
    }

    let mi = minValue
    let size = maxValue - mi + 1

    // `holes` is the one aux array this algorithm uses; `RecordingEngine.writeAux` has no
    // read-back method, so a local Swift shadow array tracks the running counts alongside the
    // `.writeAux` calls that make them visible in the replay — same precedent as
    // `CountingSort`'s local `counts`/`output` shadow arrays.
    let holesHandle = engine.createAuxArray(length: size)
    var holes = [Int](repeating: 0, count: size)

    for x in 0..<n {
      let value = engine.values[x]
      holes[value - mi] += 1
      engine.writeAux(holesHandle, at: value - mi, value: holes[value - mi])
    }

    var j = 0
    for count in 0..<size {
      while holes[count] > 0 {
        holes[count] -= 1
        engine.writeAux(holesHandle, at: count, value: holes[count])
        engine.setValue(j, count + mi)
        j += 1
      }
    }

    engine.deleteAuxArray(holesHandle)
  }
}
