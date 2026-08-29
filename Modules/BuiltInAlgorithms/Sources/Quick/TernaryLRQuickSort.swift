import AlgorithmKit
import SortEngineKit

public struct TernaryLRQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "ternarylrquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Ternary Quick Sort (LR)",
    category: .quick,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 340, coefficients: [239073, 1364.42, 1.94344],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [1.94344, 42.8797, -167.683], rSquared: 1),
    implementationComplexity: 25,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "arrow.triangle.branch"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    func compare3(_ a: Int, _ b: Int) -> Int {
      let geAB = engine.compare(a, b)
      let geBA = engine.compare(b, a)
      if geAB && geBA { return 0 }
      return geAB ? 1 : -1
    }

    func selectPivot(_ lo: Int, _ hi: Int) -> Int {
      let mid = (lo + hi) / 2
      let cLoMid = compare3(lo, mid)
      if cLoMid == 0 { return lo }
      let cLoHi = compare3(lo, hi - 1)
      let cMidHi = compare3(mid, hi - 1)
      if cLoHi == 0 || cMidHi == 0 { return hi - 1 }

      if cLoMid < 0 {
        return cMidHi < 0 ? mid : (cLoHi < 0 ? hi - 1 : lo)
      } else {
        return cMidHi > 0 ? mid : (cLoHi < 0 ? lo : hi - 1)
      }
    }

    func quicksortTernaryLR(_ lo: Int, _ hi: Int) {
      if hi <= lo { return }

      let piv = selectPivot(lo, hi + 1)
      engine.swap(piv, hi)
      let pivotIndex = hi

      var i = lo
      var j = hi - 1
      var p = lo
      var q = hi - 1

      while true {
        var cmp = 0
        while i <= j {
          cmp = compare3(i, pivotIndex)
          guard cmp <= 0 else { break }
          if cmp == 0 {
            engine.swap(i, p)
            p += 1
          }
          i += 1
        }
        while i <= j {
          cmp = compare3(j, pivotIndex)
          guard cmp >= 0 else { break }
          if cmp == 0 {
            engine.swap(j, q)
            q -= 1
          }
          j -= 1
        }
        if i > j { break }
        engine.swap(i, j)
        i += 1
        j -= 1
      }

      engine.swap(i, hi)

      let numLess = i - p
      let numGreater = q - j

      j = i - 1
      i += 1

      let pe = lo + min(p - lo, numLess)
      var k = lo
      while k < pe {
        engine.swap(k, j)
        k += 1
        j -= 1
      }

      let qe = hi - 1 - min(hi - 1 - q, numGreater - 1)
      k = hi - 1
      while k > qe {
        engine.swap(i, k)
        k -= 1
        i += 1
      }

      quicksortTernaryLR(lo, lo + numLess - 1)
      quicksortTernaryLR(hi - numGreater + 1, hi)
    }

    guard engine.count > 1 else { return }
    quicksortTernaryLR(0, engine.count - 1)
  }
}
