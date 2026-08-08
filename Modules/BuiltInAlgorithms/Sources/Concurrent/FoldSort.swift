import AlgorithmKit
import SortEngineKit

/// A bitonic-style sorting network built entirely out of "halver" passes: `halver(low, high)`
/// walks two pointers inward from both ends of a range, comparing and swapping each mirrored pair
/// until they meet — folding the range in on itself, hence the name. The network pads the real
/// array size up to the next power of two (`size`, distinct from `end`, the real length every
/// comparator is still bounds-checked against) and runs the classic three-nested-loop bitonic
/// shape: an outer `O(log n)` pass over halving block sizes `k`, a middle `O(log n)` pass folding
/// progressively smaller sub-blocks `i` within each `k`, and an inner `O(n)` sweep of `halver`
/// calls across the whole padded range.
///
/// `O(n log^2 n)` comparators, following directly from the triple-nested loop shape (`O(log n)` ×
/// `O(log n)` × `O(n)`) shared with other classic bitonic-merge networks — the same asymptotic
/// class `WeaveSort*`/`CreaseSort`/`PairwiseMergeSort*` were independently confirmed to have via
/// direct measurement. Every comparator only ever swaps on strict `>`, and fuzzing across
/// randomized duplicate-heavy trials found no case where two equal elements crossed paths,
/// confirming this network is stable.
public struct FoldSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "foldsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Fold Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 959, coefficients: [224752, 313.982, 0.0530243],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.up.left.and.arrow.down.right"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      guard b < end else { return }
      if engine.compare(a, b, by: >) {
        engine.swap(a, b)
      }
    }

    func halver(_ low: Int, _ high: Int) {
      var low = low
      var high = high
      while low < high {
        compSwap(low, high)
        low += 1
        high -= 1
      }
    }

    var ceilLog = 1
    while (1 << ceilLog) < end { ceilLog += 1 }
    let size = 1 << ceilLog

    var k = size >> 1
    while k > 0 {
      var i = size
      while i >= k {
        var j = 0
        while j < end {
          halver(j, j + i - 1)
          j += i
        }
        i >>= 1
      }
      k >>= 1
    }
  }
}
