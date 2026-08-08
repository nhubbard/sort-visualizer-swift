import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `BinaryQuickSortRecursive` — a pure entry-point wrapper around
/// `BinaryQuickSortingTemplate.binaryQuickSortRecursive`'s call-stack driver. Same partition and
/// bit-depth-bounded recursion as `BinaryQuickSortIterative`, just recursing directly instead of
/// working off an explicit task queue — see `BinaryQuickSortingTemplate`'s own doc comment for the
/// shared algorithm.
public struct BinaryQuickSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binaryquicksortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "Binary Quick Sort (Recursive)",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 4823, coefficients: [130922, 35.5342, 0.00109931],
      measuredSafeCeiling: nil),
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
    BinaryQuickSortingTemplate.binaryQuickSortRecursive(&engine, 0, n - 1, msb)
  }
}
