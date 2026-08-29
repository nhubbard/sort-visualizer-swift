import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `GrailSort` — a pure entry-point wrapper around
/// `GrailSortingTemplate.commonSort`, the full block-merge machinery. ArrayV exposes three
/// user-selectable buffer modes (in-place / fixed 32-item static buffer / dynamic `sqrt(n)`
/// buffer) at runtime; this port ships in-place only, matching every other algorithm in this
/// codebase (none take a runtime configuration parameter) — see `GrailSortingTemplate`'s own doc
/// comment for what that simplifies away.
public struct GrailSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "grailsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Grail Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1046, coefficients: [221245, 288.107, 0.0477776],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [6.66926, 1.21828], rSquared: 0.996923),
    implementationComplexity: 214,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.up.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    GrailSortingTemplate.commonSort(&engine, 0, n)
  }
}
