import AlgorithmKit
import Foundation
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/CompleteGraphSort` — a sorting network, not a
/// comparison-driven adaptive algorithm: `record(into:)` recursively `split`s a range `[a, b)`
/// around a midpoint `m`, compare-swapping each element of the first half against a rotating
/// window of the second half. The outer loop in `record(into:)` walks a doubling stride `d` (the
/// network's "distance" parameter) up to the next power of two past `n - 1`, partitioning the
/// whole array into `split`-sized chunks at each stride and applying the network to each chunk.
/// ArrayV's own name comes from visualizing every `compSwap` pair as an edge of a complete graph
/// over the array's indices.
///
/// `compSwap` only ever swaps on a strict `>`, never on a tie, but that alone doesn't make the
/// network stable — fuzzing (`completeGraphSortTiedElementsCanLoseTheirOriginalRelativeOrder`)
/// shows two equal-valued elements can still be carried past each other via separate swaps
/// against a shared third element at different strides.
public struct CompleteGraphSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "completegraphsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Complete Graph Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 304, coefficients: [239996, 1506.77, 2.21202],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [2.0821, 1.73369], rSquared: 0.998671),
    implementationComplexity: 19,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "point.3.connected.trianglepath.dotted"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV: `1 << (int)(Math.log(n-1)/Math.log(2) + 1)` — the next power of two strictly
    // greater than `n - 1`. `log2` is used directly here rather than replicating the
    // natural-log division, since it's the numerically cleaner way to express the same
    // intended value; correctness for this engine's `16...256` sizeRange is confirmed by the
    // generic + duplicate-heavy correctness suite.
    var d = 2
    let end = 1 << (Int(log2(Double(n - 1))) + 1)

    while d <= end {
      var i = 0
      var dec = 0

      while i < n {
        var j = i
        dec += n
        while dec >= d {
          dec -= d
          j += 1
        }

        var k = j
        dec += n
        while dec >= d {
          dec -= d
          k += 1
        }

        split(&engine, i, j, k)
        i = k
      }

      d *= 2
    }
  }

  private func compSwap(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    if engine.compare(a, b, by: >) {
      engine.swap(a, b)
    }
  }

  private func split(_ engine: inout RecordingEngine, _ rangeStart: Int, _ m: Int, _ rangeEnd: Int) {
    guard rangeEnd - rangeStart >= 2 else { return }

    var a = rangeStart
    var b = rangeEnd
    var c = 0
    let len1 = (b - a) / 2
    let odd = (b - a) % 2 == 1

    if odd {
      if m - a > b - m {
        c = a
        a += 1
      } else {
        b -= 1
        c = b
      }
    }

    for s in 0..<len1 {
      var i = a
      for j in s..<len1 {
        compSwap(&engine, i, m + j)
        i += 1
      }
      for j in 0..<s {
        compSwap(&engine, i, m + j)
        i += 1
      }
    }

    if odd {
      if c < m {
        for j in 0..<len1 {
          compSwap(&engine, c, m + j)
        }
      } else {
        for j in 0..<len1 {
          compSwap(&engine, a + j, c)
        }
      }
    }
  }
}
