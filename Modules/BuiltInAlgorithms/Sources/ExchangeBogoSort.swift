import AlgorithmKit
import SortEngineKit

public struct ExchangeBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "exchangebogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Exchange Bogo Sort",
    category: .impractical,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "die.face.3.fill"
  )
  public init() {}

  /// ArrayV's `ExchangeBogoSort` picks two random indices each iteration and swaps them only if
  /// out of order, repeating until sorted — an open-ended random walk, same as `BogoSort`.
  ///
  /// Ported here as a deterministic substitute: for each `i`, scan every `j > i` and swap
  /// whenever `values[j] < values[i]`, leaving `values[i]` holding the minimum of `[i, n)` by the
  /// time the inner loop finishes — a single `O(n^2)` pass with no repeats fully sorts the array.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isSorted() -> Bool {
      for i in 1..<n where engine.compare(i, i - 1, by: (<)) { return false }
      return true
    }

    if isSorted() { return }

    for i in 0..<(n - 1) {
      for j in (i + 1)..<n where engine.compare(j, i, by: (<)) {
        engine.swap(i, j)
      }
    }
  }
}
