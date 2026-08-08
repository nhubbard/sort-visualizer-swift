import AlgorithmKit
import SortEngineKit

public struct BaseNMaxHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "basenmaxheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Base-N Max Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1466, coefficients: [212542, 174.346, 0.0111134],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.grid.2x2.fill"
  )
  public init() {}

  /// Ported from ArrayV's `BaseNMaxHeapSort` — an ordinary max-heap sort generalized so each
  /// node has `base` children instead of 2. ArrayV exposes `base` as a runtime question
  /// (`@SortMeta(question = ..., defaultAnswer = 4)`); this app has no per-algorithm parameter
  /// prompt, so `base` is fixed at 4 — the same default ArrayV itself uses for its own showcase
  /// run ("Base-N Max Heap Sort, Base 4").
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let base = 4

    func siftDown(_ node: Int, _ stop: Int) {
      let left = node * base + 1
      guard left < stop else { return }

      var maxIndex = left
      var i = left + 1
      while i < left + base && i < stop {
        if engine.compare(maxIndex, i, by: (<)) {
          maxIndex = i
        }
        i += 1
      }

      if engine.compare(node, maxIndex, by: (<)) {
        engine.swap(node, maxIndex)
        siftDown(maxIndex, stop)
      }
    }

    for i in stride(from: n - 1, through: 0, by: -1) {
      siftDown(i, n)
    }

    for end in stride(from: n - 1, to: 0, by: -1) {
      engine.swap(0, end)
      siftDown(0, end)
    }
  }
}
