import AlgorithmKit
import SortEngineKit

/// Another bead-sort variant, alongside `GravitySort` and `SimplisticGravitySort` — this one
/// makes the "columns of beads" idea completely literal by building `transpose`, one aux slot per
/// possible height, where `transpose[j]` counts how many of the array's values are tall enough to
/// have a bead resting at height `j`. The first pass fills that column-by-column: each value `v`
/// contributes a bead to every column `0..<v`, exactly like stacking `v` beads on a rod one at a
/// time. The second pass reads the settled result back out from the top down — for each output
/// slot (filled back-to-front), it counts how many columns still have a bead left at all, which is
/// this rod's final height, then knocks one bead off of every column so the next, shorter rod's
/// count is drawn from what's left. Column counts are allowed to run negative past their first
/// empty read (matching ArrayV's own unconditional decrement) since only "is this column still
/// above zero" is ever asked afterward — how far below zero a spent column sits never matters
/// again.
public struct ClassicGravitySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "classicgravitysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Classic Gravity Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 309, coefficients: [239166, 1546.5, 2.5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2.5, 1.5, 0], rSquared: 1),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n \\times k)", average: "O(n \\times k)", worst: "O(n \\times k)"),
    spaceComplexity: "O(k)",
    iconName: "arrow.down.square.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var maxValue = engine.values[0]
    for i in 1..<n where engine.values[i] > maxValue {
      maxValue = engine.values[i]
    }

    let transposeHandle = engine.createAuxArray(length: maxValue)
    var transpose = [Int](repeating: 0, count: maxValue)

    for i in 0..<n {
      let value = engine.values[i]
      for j in 0..<value {
        transpose[j] += 1
        engine.writeAux(transposeHandle, at: j, value: transpose[j])
      }
    }

    for i in 0..<n {
      var sum = 0
      // Re-reads the `transpose` shadow array in full for every one of `n` output slots -- real,
      // repeated work the tape didn't previously see at all (only the decrements below were
      // visible via `writeAux`) -- so each read is marked via `markAuxRead` right where it
      // happens.
      for j in 0..<maxValue {
        engine.markAuxRead(transposeHandle, at: j)
        if transpose[j] > 0 {
          sum += 1
        }
      }
      engine.setValue(n - i - 1, sum)
      for j in 0..<maxValue {
        transpose[j] -= 1
        engine.writeAux(transposeHandle, at: j, value: transpose[j])
      }
    }

    engine.deleteAuxArray(transposeHandle)
  }
}
