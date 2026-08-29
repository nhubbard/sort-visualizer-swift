import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `LazyStableSort` — a pure entry-point wrapper around
/// `GrailSortingTemplate.lazyStableSort`, the simple O(n log n) alternate path independent of the
/// full block-merge machinery. See that template's own doc comment for the shared algorithm.
public struct LazyStableSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lazystablesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Lazy Stable Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 491, coefficients: [238170, 793.515, 0.500959],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.13781, 1.47449], rSquared: 0.992666),
    implementationComplexity: 31,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "tortoise"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    GrailSortingTemplate.lazyStableSort(&engine, 0, n)
  }
}
