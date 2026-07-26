import AlgorithmKit
import SortEngineKit

public struct TernaryLLQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "ternaryllquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Ternary Quick Sort (LL)",
    category: .quick,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 250, coefficients: [238753, 1892.46, 3.74962],
      measuredSafeCeiling: nil),
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

    func partitionTernaryLL(_ lo: Int, _ hi: Int) -> (first: Int, second: Int) {
      let p = selectPivot(lo, hi)
      engine.swap(p, hi - 1)
      let pivotIndex = hi - 1

      var i = lo
      var k = hi - 1

      var j = lo
      while j < k {
        let cmp = compare3(j, pivotIndex)
        if cmp == 0 {
          k -= 1
          engine.swap(k, j)
          j -= 1
        } else if cmp < 0 {
          engine.swap(i, j)
          i += 1
        }
        j += 1
      }

      var s = 0
      while s < hi - k {
        engine.swap(i + s, hi - 1 - s)
        s += 1
      }

      return (first: i, second: i + (hi - k))
    }

    func quicksortTernaryLL(_ lo: Int, _ hi: Int) {
      if lo + 1 < hi {
        let mid = partitionTernaryLL(lo, hi)
        quicksortTernaryLL(lo, mid.first)
        quicksortTernaryLL(mid.second, hi)
      }
    }

    quicksortTernaryLL(0, engine.count)
  }
}
