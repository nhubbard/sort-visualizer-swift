import AlgorithmKit
import SortEngineKit

public struct OptimizedGuessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedguesssort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Guess Sort",
    category: .impractical,
    sizeRange: 3...4,
    growthModel: OperationGrowthModel(
      anchorSize: 5, coefficients: [20780.6, 52044.5, 67166.7, 59269.6, 40096.7, 22126.9],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^n)", worst: "O(n^n)"),
    spaceComplexity: "O(n)",
    iconName: "questionmark.circle.fill"
  )
  public init() {}

  /// Already fully deterministic in ArrayV — no `randInt` in the Java source. `loops[pos]` is an
  /// n-digit, base-`n` odometer (every position independently 0..<n, so this brute-forces every
  /// `n^n` index tuple, not just the `n!` permutations — a strictly bigger search space than
  /// `BogoSort`'s, hence the much smaller `sizeRange`), incremented like a counter until the
  /// array read through `loops` as an index map comes out stably non-decreasing. `loops` is pure
  /// bookkeeping (never visualized in the original either), so it stays a local Swift array.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var loops = [Int](repeating: 0, count: n)

    /// `array[loops[i]]` read through in order must be non-decreasing, with `loops[i] <
    /// loops[i+1]` breaking ties on equal values — this is what stops `loops` from ever
    /// settling on a mapping that reads the same source index twice while skipping another.
    func isValidMapping() -> Bool {
      for i in 0..<(n - 1) {
        if engine.compare(loops[i], loops[i + 1], by: (<)) { continue }
        if engine.compare(loops[i], loops[i + 1], by: (==)), loops[i] < loops[i + 1] { continue }
        return false
      }
      return true
    }

    while !isValidMapping() {
      for pos in 0..<n {
        if loops[pos] < n - 1 {
          loops[pos] += 1
          break
        } else {
          loops[pos] = 0
        }
      }
    }

    let mapped = loops.map { engine.values[$0] }
    for i in 0..<n {
      engine.setValue(i, mapped[i])
    }
  }
}
