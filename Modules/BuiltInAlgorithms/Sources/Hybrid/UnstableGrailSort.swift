import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `UnstableGrailSort` — a pure entry-point wrapper around
/// `UnstableGrailSortingTemplate.commonSort`. See that template's own doc comment for the shared
/// algorithm.
public struct UnstableGrailSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "unstablegrailsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Unstable Grail Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1086, coefficients: [219148, 281.797, 0.0495357],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.91049, 1.2534], rSquared: 0.987274),
    implementationComplexity: 98,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.up"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    UnstableGrailSortingTemplate.commonSort(&engine, 0, n)
  }
}
