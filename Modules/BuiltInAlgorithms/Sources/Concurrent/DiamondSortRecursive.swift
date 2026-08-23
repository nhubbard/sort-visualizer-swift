import AlgorithmKit
import SortEngineKit

public struct DiamondSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "diamondsortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "Diamond Sort (Recursive)",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 187, coefficients: [240674, 2561.81, 6.65882],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [3.75894, 1.79932], rSquared: 0.999984),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(log n)",
    iconName: "diamond.fill"
  )
  public init() {}

  /// ArrayV's `DiamondSortRecursive.sort` is a sorting network only proven correct when the range
  /// length is a power of two — an unpadded port fails on in-between sizes (5, 6, 9, 10, ...).
  /// `record(into:)` runs the network over the next power of two at or above `engine.count`, and
  /// `compareAndSwap` silently skips any comparison touching an out-of-range index — those indices
  /// are conceptually filler elements larger than everything real, so skipping them never needs a
  /// swap and leaves the real elements to sort correctly among themselves.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var paddedLength = 1
    while paddedLength < n {
      paddedLength <<= 1
    }

    func compareAndSwap(_ i: Int, _ j: Int) {
      guard i < n, j < n else { return }
      if engine.compare(i, j, by: (>)) {
        engine.swap(i, j)
      }
    }

    func sort(_ start: Int, _ stop: Int, merge: Bool) {
      if stop - start == 2 {
        compareAndSwap(start, stop - 1)
      } else if stop - start >= 3 {
        let div = Double(stop - start) / 4
        let mid = (stop - start) / 2 + start
        let quarter = Int(div) + start
        let threeQuarters = Int(div * 3) + start

        if merge {
          sort(start, mid, merge: true)
          sort(mid, stop, merge: true)
        }
        sort(quarter, threeQuarters, merge: false)
        sort(start, mid, merge: false)
        sort(mid, stop, merge: false)
        sort(quarter, threeQuarters, merge: false)
      }
    }

    sort(0, paddedLength, merge: true)
  }
}
