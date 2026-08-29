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
      anchorSize: 1097, coefficients: [219025, 278.045, 0.0478977],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.96437, 1.24975], rSquared: 0.990058),
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
