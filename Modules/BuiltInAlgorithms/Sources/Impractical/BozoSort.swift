import AlgorithmKit
import SortEngineKit

public struct BozoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bozosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bozo Sort",
    category: .impractical,
    sizeRange: 4...7,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [42633.5, 80687, 76353.1, 48168, 22790.4, 8626.49],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .exponential, coefficients: [0.0751986, 6.63643], rSquared: 0.998958),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.swap"
  )
  public init() {}

  /// Classic Bozo Sort swaps two random elements and checks; like `BogoSort`, an open-ended
  /// random walk risks an unbounded pre-recorded tape. Heap's algorithm keeps the "one swap, then
  /// check" shape but makes it deterministic — it visits every permutation exactly once, reaching
  /// each via exactly one swap from the last, giving a hard n!-step ceiling with no repeats.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isSorted() -> Bool {
      for i in 1..<n where !engine.compare(i, i - 1) { return false }
      return true
    }

    var done = false

    func heap(_ k: Int) {
      guard !done else { return }
      if k == 1 {
        if isSorted() { done = true }
        return
      }
      for i in 0..<(k - 1) {
        heap(k - 1)
        guard !done else { return }
        engine.swap(k.isMultiple(of: 2) ? i : 0, k - 1)
      }
      heap(k - 1)
    }

    heap(n)
  }
}
