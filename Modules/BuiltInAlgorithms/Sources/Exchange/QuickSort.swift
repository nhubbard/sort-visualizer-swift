import AlgorithmKit
import SortEngineKit

public struct QuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "quicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 306, coefficients: [239423, 1547.5, 2.5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2.5, 17.5, -22], rSquared: 1),
    implementationComplexity: 9,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "bolt.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    quickSort(&engine, 0, engine.count - 1)
  }

  private func quickSort(_ engine: inout RecordingEngine, _ left: Int, _ right: Int) {
    guard left < right else { return }
    let pivot = left
    var i = left
    var j = right
    while i < j {
      while true {
        let isOnLeft = engine.compare(pivot, i)
        if engine.shouldAnnotateCurrentOperation {
          engine.annotateLastOperation(
            stageID: "quick.partition.scanLeft",
            decisionID: "quick.pivotSide",
            outcome: !isOnLeft ? "oppositeSide" : (i < j ? "advance" : "boundary"),
            roles: ["pivot": .arrayIndex(pivot), "candidate": .arrayIndex(i)],
            explanationKey: "quick.pivotSide",
            explanation: !isOnLeft
              ? "This item is larger than the pivot, so the left scan stops to exchange it."
              : (i < j ? "This item stays on the pivot's left side; advance the scan."
                : "The left scan reached the partition boundary."))
        }
        guard isOnLeft && i < j else { break }
        i += 1
      }
      while true {
        let isOnLeft = engine.compare(pivot, j)
        if engine.shouldAnnotateCurrentOperation {
          engine.annotateLastOperation(
            stageID: "quick.partition.scanRight",
            decisionID: "quick.pivotSide",
            outcome: isOnLeft ? "stop" : "retreat",
            roles: ["pivot": .arrayIndex(pivot), "candidate": .arrayIndex(j)],
            explanationKey: "quick.pivotSide",
            explanation: isOnLeft
              ? "This item belongs on or before the pivot, so the right scan stops."
              : "This item is larger than the pivot; retreat through the right partition.")
        }
        guard !isOnLeft else { break }
        j -= 1
      }
      if i < j {
        engine.swap(i, j)
      }
    }
    engine.swap(pivot, j)
    quickSort(&engine, left, j - 1)
    quickSort(&engine, j + 1, right)
  }
}
