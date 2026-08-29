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
      anchorSize: 2823, coefficients: [181627, 73.6464, 0.00170668],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [6.97262, 1.01882], rSquared: 0.997448),
    implementationComplexity: 13,
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
