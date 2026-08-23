import AlgorithmKit
import SortEngineKit

/// ArrayV's `OptimizedGnomeSort.java` credits Wikipedia's "smart Gnome Sort," but it isn't classic
/// `GnomeSort` (`Modules/BuiltInAlgorithms/Sources/GnomeSort.swift`) plus an early exit — it's a
/// different algorithm shape entirely: for each prefix length `i` from 1 up to `n`, run a single
/// backward-swapping insertion pass that walks the new element (at index `i - 1`) leftward past
/// every predecessor it's smaller than, then move on to the next prefix. That's insertion sort
/// expressed as repeated adjacent swaps rather than a shift-then-place, not Gnome Sort's usual
/// single forward/backward pointer over the whole array.
public struct OptimizedGnomeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedgnomesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Gnome Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [238710, 2185, 5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [5, -5, -1.35917e-10], rSquared: 1),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "figure.walk.motion"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    for i in 1..<n {
      var pos = i
      // Strict `>` (not the default `>=`): ties never trigger a swap, matching ArrayV's
      // `Reads.compareValues(...) == 1` and keeping the sort stable.
      while pos > 0 && engine.compare(pos - 1, pos, by: (>)) {
        engine.swap(pos - 1, pos)
        pos -= 1
      }
    }
  }
}
