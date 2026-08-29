import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `QuadSort` — a pure entry-point wrapper around
/// `QuadSortingTemplate.sort(_:start:length:)`, Igor van den Hoven's real `quadsort.c` (via
/// ArrayV's Java re-implementation). See that template's own doc comment for the shared
/// algorithm; ArrayV files this under Merge despite the template's name.
///
/// `stable: true` is asserted by construction, not by the usual swap-tape-shadow-replay fuzz test
/// (see `NativeAlgorithmCorrectnessTests.expectStable`) — that technique only holds when an
/// algorithm moves data exclusively via `engine.swap`/`.reversal`, and this one moves almost
/// everything via `engine.setValue` inside its merge passes, which would make the shadow go
/// stale and the test meaningless. Every merge primitive in `QuadSortingTemplate` (`parityMerge4`/
/// `8`, `forwardMerge`, `partialBackwardMerge`) breaks ties in the same direction: each forward
/// comparison uses `<=` and takes the left run, each backward comparison uses strict `>` and only
/// takes the left run when it's *not* tied, deferring to the right run otherwise — so on any tie,
/// the left run's copy always lands at the lower index. The pre-sort pass (`quadSwap`) only ever
/// swaps or reverses on strict `>`, so equal adjacent elements are never disturbed there either.
/// This is the standard technique that makes real-world quadsort a documented stable sort, and
/// every comparison this port makes is a direct translation of the original's `<=`/`>` operators.
public struct QuadSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "quadsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Quadsort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 3349, coefficients: [154913, 61.7612, 0.00298586],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [1.02001, 1.21198], rSquared: 0.859447),
    implementationComplexity: 592,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "square.stack.3d.up"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    QuadSortingTemplate.sort(&engine, start: 0, length: n)
  }
}
