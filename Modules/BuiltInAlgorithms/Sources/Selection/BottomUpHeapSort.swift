import AlgorithmKit
import SortEngineKit

public struct BottomUpHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bottomupheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bottom-up Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1824, coefficients: [206453, 130.237, 0.00482764],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [13.2217, 1.01746], rSquared: 0.999978),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.up.square.fill"
  )
  public init() {}

  /// The "bottom-up heapsort" optimization: unlike `MaxHeapSort`'s `siftDown`, which compares the
  /// sift value at each level on the way down, this descends straight to a leaf via the larger
  /// child, climbs back up while the sift value is still greater than the current ancestor, then
  /// shifts every node between that resting point and `i` one step toward the root. Fewer
  /// comparisons on average than plain sift-down, same end result.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func siftDown(_ i: Int, _ b: Int) {
      var j = i
      while 2 * j + 1 < b {
        if 2 * j + 2 < b {
          j = engine.compare(2 * j + 2, 2 * j + 1, by: (>)) ? 2 * j + 2 : 2 * j + 1
        } else {
          j = 2 * j + 1
        }
      }
      while engine.compare(i, j, by: (>)) {
        j = (j - 1) / 2
      }
      while j > i {
        engine.swap(i, j)
        j = (j - 1) / 2
      }
    }

    for i in stride(from: (n - 1) / 2, through: 0, by: -1) {
      siftDown(i, n)
    }

    for i in stride(from: n - 1, to: 0, by: -1) {
      engine.swap(0, i)
      siftDown(0, i)
    }
  }
}
