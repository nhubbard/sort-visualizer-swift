import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `BinaryQuickSortIterative` — a pure entry-point wrapper around
/// `BinaryQuickSortingTemplate.binaryQuickSort`'s task-queue driver. See that template's own doc
/// comment for the shared algorithm.
public struct BinaryQuickSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binaryquicksortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Binary Quick Sort (Iterative)",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2823, coefficients: [181627, 73.6464, 0.00170668],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [6.97262, 1.01882], rSquared: 0.997448),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(log n)",
    iconName: "square.stack.3d.up.badge.a"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let msb = BinaryQuickSortingTemplate.mostSignificantBit(engine.values)
    BinaryQuickSortingTemplate.binaryQuickSort(&engine, 0, n - 1, msb)
  }
}
