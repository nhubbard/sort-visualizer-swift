import AlgorithmKit
import SortEngineKit

public struct BoseNelsonSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bosenelsonsortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Iterative Bose-Nelson Sort",
    category: .concurrent,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "point.3.connected.trianglepath.dotted"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    // `end` is the real array length; the network structure below is built over the next
    // power of two at or above `end` (ArrayV's `currentLength` local), while every actual
    // array access is guarded against `end` so out-of-range comparator wires are simply
    // skipped. This is the standard trick for running a fixed-size sorting network on an
    // arbitrary-sized array.
    let end = engine.count
    guard end > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      guard b < end else { return }
      if engine.compare(a, b, by: (>)) {
        engine.swap(a, b)
      }
    }

    func rangeComp(_ a: Int, _ b: Int, _ offset: Int) {
      let half = (b - a) / 2
      let m = a + half
      let base = a + offset
      var i = 0
      while i < half - offset {
        if (i & ~offset) == i {
          compSwap(base + i, m + i)
        }
        i += 1
      }
    }

    var paddedLength = 1
    while paddedLength < end {
      paddedLength <<= 1
    }

    var k = 2
    while k <= paddedLength {
      var j = 0
      while j < k / 2 {
        var i = 0
        while i + j < end {
          rangeComp(i, i + k, j)
          i += k
        }
        j += 1
      }
      k *= 2
    }
  }
}
