import AlgorithmKit
import SortEngineKit

public struct BinomialSmoothSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binomialsmoothsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Binomial Smooth Sort",
    category: .selection,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "wind"
  )
  public init() {}

  /// A Smoothsort-family algorithm built on the same implicit-binomial-heap-in-an-array idea as
  /// `BinomialHeapSort`, but 0-indexed and recursive (`thrift`). `height(node)` counts `node`'s
  /// trailing set bits, telling `thrift` which sibling subtree to look at. `thrift(node, parent,
  /// root)` decides whether an earlier subtree root beats `node` and, if so, swaps it up and
  /// recurses into the vacated spot.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func height(_ node: Int) -> Int {
      var count = 0
      while (node >> count) % 2 == 1 {
        count += 1
      }
      return count
    }

    func thrift(_ node: Int, _ parentFlag: Bool, _ rootFlag: Bool) {
      let isRoot = rootFlag && (node >= (1 << height(node)))
      guard isRoot || parentFlag else { return }

      var choice = height(node) - (isRoot ? 0 : 1)
      if parentFlag {
        for child in stride(from: choice - 1, through: 0, by: -1)
        where !engine.compare(node - (1 << choice), node - (1 << child), by: (>)) {
          choice = child
        }
      }
      guard engine.compare(node - (1 << choice), node, by: (>)) else { return }

      engine.swap(node, node - (1 << choice))
      let nextNode = node - (1 << choice)
      thrift(nextNode, nextNode % 2 == 1, choice == height(node))
    }

    var node = 1
    while node < n {
      thrift(node, node % 2 == 1, (node + (1 << height(node))) >= n)
      node += 1
    }

    node -= (node - 1) % 2
    while node > 2 {
      for child in stride(from: height(node) - 1, through: 0, by: -1) {
        thrift(node - (1 << child), false, true)
      }
      node -= 2
    }
  }
}
