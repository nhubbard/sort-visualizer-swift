import AlgorithmKit
import SortEngineKit

public struct BinomialHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binomialheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Binomial Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 900, coefficients: [225607, 373.111, 0.0982337],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "b.square.fill"
  )
  public init() {}

  /// ArrayV's arithmetic is 1-indexed (`array[x - 1]` everywhere): a binomial heap node `x`'s
  /// parent-ward neighbors are found by clearing successively higher set bits of `x`. Index
  /// bookkeeping stays 1-indexed internally and is only converted to 0-indexed at the point of an
  /// `engine` call, to keep the traversal order identical to ArrayV's.
  ///
  /// Phase 1 (`index` stepping by 2) builds the binomial-heap structure: for each even `index`,
  /// bubbles the largest of `index` and its binomial siblings up via swap until a pass finds
  /// nothing bigger.
  ///
  /// Phase 2 (`index` counting down from `n`) extracts the max at the current root by walking
  /// `index`'s set bits, then re-runs phase 1's bubble-up from any bigger node found before moving on.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var index = 2
    while index <= n {
      var maxNode = index
      var focus: Int
      repeat {
        focus = maxNode
        var depth = 1
        while (focus & depth) == 0 {
          if engine.compare(focus - depth - 1, maxNode - 1, by: (>)) {
            maxNode = focus - depth
          }
          depth *= 2
        }
        if focus != maxNode {
          engine.swap(focus - 1, maxNode - 1)
        }
      } while focus != maxNode
      index += 2
    }

    index = n
    while index > 2 {
      var maxNode = index
      var focus = index
      var depth = 1
      while focus != 0 {
        if (focus & depth) != 0 {
          if engine.compare(focus - 1, maxNode - 1, by: (>)) {
            maxNode = focus
          }
          focus -= depth
        }
        depth *= 2
      }

      if maxNode != index {
        focus = index
        repeat {
          engine.swap(focus - 1, maxNode - 1)
          focus = maxNode
          var innerDepth = 1
          while (focus & innerDepth) == 0 {
            if engine.compare(focus - innerDepth - 1, maxNode - 1, by: (>)) {
              maxNode = focus - innerDepth
            }
            innerDepth *= 2
          }
        } while focus != maxNode
      }
      index -= 1
    }
  }
}
