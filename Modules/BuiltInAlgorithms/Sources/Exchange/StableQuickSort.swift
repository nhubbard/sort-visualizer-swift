import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/StableQuickSort` (by Rodney Shaghoulian) — genuinely
/// O(n) extra space per partition, not an in-place Hoare/Lomuto scheme: `stablePartition` makes
/// a single left-to-right scan over `[start + 1, end]`, appending each element to a "less than
/// pivot" list or a "not less than pivot" list in the order it's encountered, then writes
/// `leftList + pivot + rightList` back over the same range. Because both lists preserve encounter
/// order and the write-back preserves list order, no equal-valued pair can ever cross past each
/// other — this is a textbook stable partition by construction, not a name that needs empirical
/// fuzzing to trust (unlike e.g. `StablePermutationSort`'s rotation trick, whose stability claim
/// turned out false under fuzzing). ArrayV's own `ArrayVList` is a growable external structure this
/// engine's fixed-length `createAuxArray` doesn't model, so the two lists stay plain local `[Int]`s
/// rather than a visualized aux buffer — every real array mutation is a single `engine.setValue`
/// write-back, matching ArrayV's own `Writes.write` calls exactly (no `.swap` is ever emitted, so
/// the shared swap-tape-shadow stability fuzz test other algorithms use doesn't apply here; see
/// `NativeAlgorithmCorrectnessTests.swift`'s omission of a dedicated test for this one).
public struct StableQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stablequicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stable Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 692, coefficients: [239777, 692.5, 0.5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.5, 0.5, -1], rSquared: 1),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "list.bullet.rectangle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    quickSort(&engine, 0, n - 1)
  }

  /// Poor pivot choice (always `array[start]`, matching ArrayV's own comment), returns the
  /// pivot's final resting index.
  private func stablePartition(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) -> Int {
    let pivotValue = engine.values[start]

    var leftList: [Int] = []
    var rightList: [Int] = []

    for i in (start + 1)...end {
      if engine.values[i] < pivotValue {
        leftList.append(engine.values[i])
      } else {
        rightList.append(engine.values[i])
      }
    }

    var writeIndex = start
    for value in leftList {
      engine.setValue(writeIndex, value)
      writeIndex += 1
    }

    let newPivotIndex = writeIndex
    engine.setValue(newPivotIndex, pivotValue)
    writeIndex += 1

    for value in rightList {
      engine.setValue(writeIndex, value)
      writeIndex += 1
    }

    return newPivotIndex
  }

  private func quickSort(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard start < end else { return }
    let pivotIndex = stablePartition(&engine, start, end)
    quickSort(&engine, start, pivotIndex - 1)
    quickSort(&engine, pivotIndex + 1, end)
  }
}
