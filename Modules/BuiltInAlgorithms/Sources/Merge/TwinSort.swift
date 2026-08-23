import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `TwinSort` — a pure entry-point wrapper around
/// `TwinSortingTemplate.twinsort`. See that template's own doc comment for the shared algorithm.
///
/// **Stability**: `tailMerge` mixes `engine.swap` (none, actually — it's pure `engine.setValue`)
/// with `twinSwap`'s `engine.reversal`-based swaps, so the standard swap-tape-shadow stability
/// fuzz test can't observe most of this algorithm's real data movement (same structural
/// limitation `StableQuickSort`/`ShatterSortingTemplate` hit). Verified genuinely stable instead
/// by simulating this exact algorithm in Python with a parallel original-index array threaded
/// through every swap/write (6,000 randomized duplicate-heavy trials, sizes 2-256, zero
/// instability, zero incorrect results) — `twinSwap` only ever reverses *strictly* decreasing runs
/// (ties are treated as run boundaries, never included inside a reversed run, so reversal can't
/// cross two equal elements), and `tailMerge`'s tie-breaks consistently favor the earlier
/// (left-block) element.
public struct TwinSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "twinsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Twin Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 6478, coefficients: [114074, 24.224, 0.000684673],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [0.201857, 1.26168], rSquared: 0.99033),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.triangle.merge"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    TwinSortingTemplate.twinsort(&engine, n)
  }
}
