import AlgorithmKit
import SortEngineKit

public struct FlippedMinHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "flippedminheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Flipped Min Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1359, coefficients: [213649, 195.55, 0.0164349],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [10.1963, 1.10527], rSquared: 0.999043),
    implementationComplexity: 10,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.down.forward.fill"
  )
  public init() {}

  /// ArrayV's `FlippedMinHeapSort` is an ordinary min-heap sort, but every array access is
  /// mirrored through `array[length - p]` instead of `array[p]` — same min-heap shape as
  /// `MinHeapSort`, just built and extracted from the back of the array toward the front. `idx(_:)`
  /// below is that one mirroring rule, applied consistently instead of duplicating the
  /// `length -` arithmetic at every call site.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func idx(_ p: Int) -> Int { n - p }

    func siftDown(_ root: Int, _ dist: Int) {
      var root = root
      while root <= dist / 2 {
        var leaf = 2 * root
        if leaf < dist, engine.compare(idx(leaf), idx(leaf + 1), by: (>)) {
          leaf += 1
        }
        if engine.compare(idx(root), idx(leaf), by: (>)) {
          engine.swap(idx(root), idx(leaf))
          root = leaf
        } else {
          break
        }
      }
    }

    var i = n / 2
    while i >= 1 {
      siftDown(i, n)
      i -= 1
    }

    i = n
    while i > 1 {
      engine.swap(idx(1), idx(i))
      siftDown(1, i - 1)
      i -= 1
    }
  }
}
