import AlgorithmKit
import SortEngineKit

/// ArrayV's `PigeonholeSort`: a close cousin of `CountingSort` in the same `.distribution`
/// family — both find the value range, tally occurrences per value into an aux array of
/// "holes"/buckets sized to that range, then re-emit values in ascending order. The two diverge
/// on *how* they re-emit: `CountingSort` turns its tally into a cumulative (prefix-sum) table and
/// walks the input backward, consulting-and-decrementing each element's own count to find its
/// exact output slot — a technique that happens to preserve relative order for equal elements.
/// Pigeonhole Sort here does something simpler and lossier: it never looks at the input again
/// once tallying is done. It just walks the holes in ascending order and, for each one, writes out
/// that value as many times as it was tallied. Nothing in that second pass distinguishes one
/// instance of a repeated value from another — the original positions were discarded the moment
/// they were folded into a hole's count — so this is NOT a stable sort, unlike `CountingSort`.
public struct PigeonholeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pigeonholesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Pigeonhole Sort",
    category: .distribution,
    sizeRange: 16...256,
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
