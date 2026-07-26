import AlgorithmKit
import SortEngineKit

public struct BubbleBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bubblebogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bubble Bogo Sort",
    category: .impractical,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "questionmark.bubble.fill"
  )
  public init() {}

  /// ArrayV's `BubbleBogoSort` repeatedly picks a random adjacent pair and swaps it if inverted,
  /// repeating until sorted — an open-ended random walk, same as `BogoSort`.
  ///
  /// Ported here as a deterministic substitute: repeatedly sweep every adjacent pair
  /// left-to-right, swapping when inverted, until a full sweep finds nothing to fix — this is
  /// bubble sort's own mechanic, guaranteeing termination in `O(n^2)` (hence the larger
  /// `sizeRange` than a typical bogo variant).
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var swapped = true
    while swapped {
      swapped = false
      for i in 0..<(n - 1) where engine.compare(i, i + 1, by: (>)) {
        engine.swap(i, i + 1)
        swapped = true
      }
    }
  }
}
