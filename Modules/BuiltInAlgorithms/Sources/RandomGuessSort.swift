import AlgorithmKit
import SortEngineKit

public struct RandomGuessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "randomguesssort")
  public let metadata = AlgorithmMetadata(
    displayName: "Random Guess Sort",
    category: .impractical,
    sizeRange: 4...6,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^n)", worst: "O(n^n)"),
    spaceComplexity: "O(n)",
    iconName: "questionmark.diamond.fill"
  )
  public init() {}

  /// ArrayV's `RandomGuessSort` repeatedly draws `loops[pos]` uniformly at random from `0..<n`
  /// per position and checks whether reading the array through that guess comes out stably
  /// sorted — the same open-ended-random-walk problem `BogoSort` already solved, just over a
  /// bigger `n^n` guess space (each position guessed independently, not constrained to be a
  /// permutation) rather than `n!`. ArrayV's own later variant, `OptimizedGuessSort`, already
  /// solves exactly this by walking that same guess space as a deterministic base-`n` odometer
  /// instead of drawing randomly — reused here rather than re-deriving a different technique,
  /// since it's the same search space this algorithm itself explores, just walked in fixed order.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var loops = [Int](repeating: 0, count: n)

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
