import AlgorithmKit
import SortEngineKit

/// ArrayV's `GravitySort` ("Beadsort") — models Bead Sort (beads on vertical rods settling under
/// gravity into a sorted staircase) via an equivalent tally-and-partial-sum computation instead of
/// simulating falling beads. `x` is the input shifted non-negative (`array[i] - min`). `y[v]` starts
/// as a per-value occurrence count, then a backward partial sum turns it into "count of elements
/// with shifted-value >= v" (how many beads rest at or above height `v`). The final double loop
/// reconstructs each `array[i]`: walking levels `j` from highest to lowest, position `i` gains `+1`
/// if it's among the rightmost `y[j]` slots, and loses it back via `-1` if `i`'s original shifted
/// value was already `>= j` (avoiding double-counting).
///
/// Not stable — like `PigeonholeSort`, reconstruction tracks only value counts, not original index.
public struct GravitySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "gravitysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Gravity (Bead) Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 309, coefficients: [239528, 1549.14, 2.50453],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2.50453, 1.34498, -22.9079], rSquared: 0.999999),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n \\times k)", average: "O(n \\times k)", worst: "O(n \\times k)"),
    spaceComplexity: "O(n+k)",
    iconName: "arrow.down.circle.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's min/max scan reads values directly (no stat-tracked compares), so this reads
    // `engine.values` and compares against the plain local `min`/`max` variables rather than
    // going through `engine.compare` — the same held-value pattern as `CycleSort`'s `t` and
    // `PigeonholeSort`'s own min/max scan.
    var minValue = engine.values[0]
    var maxValue = engine.values[0]
    for i in 1..<n {
      if engine.values[i] < minValue { minValue = engine.values[i] }
      if engine.values[i] > maxValue { maxValue = engine.values[i] }
    }

    let mi = minValue
    let ySize = maxValue - mi + 1

    // `x` and `y` are two separate ArrayV external arrays; `RecordingEngine.writeAux` has no
    // read-back method, so a local Swift shadow array tracks each one's running values
    // alongside the `.writeAux` calls that make them visible in the replay — same precedent as
    // `CountingSort`'s local `counts`/`output` shadow arrays.
    let xHandle = engine.createAuxArray(length: n)
    var x = [Int](repeating: 0, count: n)
    let yHandle = engine.createAuxArray(length: ySize)
    var y = [Int](repeating: 0, count: ySize)

    // Save a shifted copy of the input in `x`, and tally the count of each shifted value in
    // `y`.
    for i in 0..<n {
      let shifted = engine.values[i] - mi
      x[i] = shifted
      engine.writeAux(xHandle, at: i, value: shifted)

      y[shifted] += 1
      engine.writeAux(yHandle, at: shifted, value: y[shifted])
    }

    // A backward partial sum turns "count of elements with this exact shifted value" into
    // "count of elements with shifted value >= this one".
    for i in stride(from: ySize - 1, to: 0, by: -1) {
      y[i - 1] += y[i]
      engine.writeAux(yHandle, at: i - 1, value: y[i - 1])
    }

    // Walk every possible shifted value from highest to lowest, updating every array position
    // in place — each pass over `i` either credits position `i` with reaching this level (if
    // `i` is one of the rightmost `y[j]` positions known to end up `>= j`) or debits it back
    // out (if position `i`'s original shifted value already started `>= j`, so it shouldn't be
    // credited again on the way down).
    //
    // `y[j]`/`x[i]` are re-read from `writeAux`'s own local shadow copies on every one of the
    // `ySize * n` inner iterations -- real, repeated work the tape didn't previously see at all
    // (only the occasional resulting `setValue` was visible), so each read is marked via
    // `markAuxRead` right where it happens.
    for j in stride(from: ySize - 1, through: 0, by: -1) {
      for i in 0..<n {
        engine.markAuxRead(yHandle, at: j)
        engine.markAuxRead(xHandle, at: i)
        let inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0)
        // Most `(j, i)` pairs across a full `ySize * n` sweep leave position `i` unchanged at
        // this level (`inc == 0`) -- skipping the write is a genuine no-op (`values[i] + 0 ==
        // values[i]`), not a behavior change, and cuts real, redundant tape volume.
        guard inc != 0 else { continue }
        engine.setValue(i, engine.values[i] + inc)
      }
    }

    engine.deleteAuxArray(xHandle)
    engine.deleteAuxArray(yHandle)
  }
}
