import AlgorithmKit
import SortEngineKit

/// ArrayV's `ClassicThreeSmoothCombSort` — Shellsort run as a fixed, data-independent sorting
/// NETWORK using Pratt's 3-smooth gap sequence (`2^a * 3^b`), rather than an adaptive comb/shrink
/// heuristic. `is3Smooth` tests membership by stripping factors of 6, then 3, then 2.
///
/// Unlike `CombSort`/`HybridCombSort`, this needs only ONE compare-and-swap pass per gap: Pratt's
/// 1972 theorem proves that one pass per 3-smooth gap below `n`, in decreasing order down to `1`,
/// provably sorts any input — no outer "did anything move" convergence loop is needed.
///
/// Complexity: `Θ(n log^2 n)` in every case (best/average/worst identical, since the gap sequence
/// is fixed regardless of input) — `Θ(log^2 n)` distinct 3-smooth gaps, each pass costing `Θ(n)`.
/// Space: `O(1)`.
///
/// Stability: `false` — gap passes compare far-apart elements without comparing the ones between
/// them, so equal-valued elements can cross paths without ever being compared directly, same as
/// `CombSort`/`HybridCombSort`/`ShellSort`.
public struct ClassicThreeSmoothCombSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "classicthreesmoothcombsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Classic 3-Smooth Comb Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1057, coefficients: [220385, 289.129, 0.0508555],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "point.3.filled.connected.trianglepath.dotted"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    let length = engine.count

    // `n = 2^a * 3^b` for some `a, b >= 0`, mirroring ArrayV's repeated-division structure
    // exactly: strip factors of 6, then 3, then 2, and check whether `1` is all that remains.
    func is3Smooth(_ n: Int) -> Bool {
      var n = n
      while n % 6 == 0 { n /= 6 }
      while n % 3 == 0 { n /= 3 }
      while n % 2 == 0 { n /= 2 }
      return n == 1
    }

    var g = length - 1
    while g > 0 {
      if is3Smooth(g) {
        var i = g
        while i < length {
          if engine.compare(i - g, i, by: (>)) {
            engine.swap(i - g, i)
          }
          i += 1
        }
      }
      g -= 1
    }
  }
}
