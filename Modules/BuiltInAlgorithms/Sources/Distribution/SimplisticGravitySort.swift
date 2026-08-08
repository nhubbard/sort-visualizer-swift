import AlgorithmKit
import SortEngineKit

/// A bead-sort variant that moves one bead at a time instead of `GravitySort`'s tally-and-partial-
/// sum shortcut. `transferTo` walks a position's value down to the array's minimum, moving each
/// unit it sheds onto the next free slot of a single shared external "column" array (`aux`) —
/// literally shifting beads off that position's rod and onto a communal rack one at a time.
/// `transferFrom`, run afterward in reverse index order, walks the same shared rack from its first
/// column and pulls a bead back onto the current position for every column that still holds one,
/// stopping at the first empty column. Since every later position's `transferFrom` only ever
/// drains columns starting from `aux[0]`, and a position can't gain more beads than the columns
/// still holding any, the result settles into the same ascending arrangement a real bead rack would
/// under gravity — just simulated bead-by-bead instead of column-by-column.
public struct SimplisticGravitySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "simplisticgravitysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Simplistic Gravity Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 346, coefficients: [238740, 1382, 2],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n \\times k)", average: "O(n \\times k)", worst: "O(n \\times k)"),
    spaceComplexity: "O(k)",
    iconName: "arrow.down.to.line"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var minValue = engine.values[0]
    var maxValue = engine.values[0]
    for i in 1..<n {
      if engine.values[i] < minValue { minValue = engine.values[i] }
      if engine.values[i] > maxValue { maxValue = engine.values[i] }
    }

    // Sized `max - min` exactly like ArrayV's own `aux` — every position's value can shed at
    // most that many beads before reaching `minValue`, so the shared rack never needs more
    // columns than that, even though every position's `transferTo` walks it starting from
    // column 0 again.
    let auxLength = maxValue - minValue
    let auxHandle = engine.createAuxArray(length: auxLength)
    var aux = [Int](repeating: 0, count: auxLength)

    func transferTo(_ index: Int) {
      var pointer = 0
      while engine.values[index] > minValue {
        engine.setValue(index, engine.values[index] - 1)
        aux[pointer] += 1
        engine.writeAux(auxHandle, at: pointer, value: aux[pointer])
        pointer += 1
      }
    }

    func transferFrom(_ index: Int) {
      var pointer = 0
      while pointer < auxLength, aux[pointer] != 0 {
        engine.setValue(index, engine.values[index] + 1)
        aux[pointer] -= 1
        engine.writeAux(auxHandle, at: pointer, value: aux[pointer])
        pointer += 1
      }
    }

    for i in 0..<n {
      transferTo(i)
    }
    for i in stride(from: n - 1, through: 0, by: -1) {
      transferFrom(i)
    }

    engine.deleteAuxArray(auxHandle)
  }
}
