import AlgorithmKit
import SortEngineKit

public struct WeakHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "weakheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Weak Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2213, coefficients: [198458, 101.593],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [11.3751, 1.00303], rSquared: 0.999961),
    implementationComplexity: 10,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "flag.fill"
  )
  public init() {}

  /// A weak heap relaxes the ordinary heap invariant: each node only needs to dominate one child
  /// directly; a "reverse" bit per index tracks which subtree holds the larger root, deferring
  /// the other comparison — fewer comparisons overall than an ordinary heap. ArrayV bit-packs
  /// these flags into a byte array; this port uses a plain `Bool` array instead (same behavior,
  /// no zero-fill loop needed since Swift already zero-initializes `repeating: false`).
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var flags = [Bool](repeating: false, count: n)

    func weakHeapMerge(_ i: Int, _ j: Int) {
      if engine.compare(i, j, by: (<)) {
        flags[j].toggle()
        engine.swap(i, j)
      }
    }

    for i in stride(from: n - 1, through: 1, by: -1) {
      var j = i
      while (j & 1) == (flags[j >> 1] ? 1 : 0) {
        j >>= 1
      }
      let gparent = j >> 1
      weakHeapMerge(gparent, i)
    }

    for i in stride(from: n - 1, through: 2, by: -1) {
      engine.swap(0, i)

      var x = 1
      while true {
        let y = 2 * x + (flags[x] ? 1 : 0)
        guard y < i else { break }
        x = y
      }
      while x > 0 {
        weakHeapMerge(0, x)
        x >>= 1
      }
    }
    engine.swap(0, 1)
  }
}
