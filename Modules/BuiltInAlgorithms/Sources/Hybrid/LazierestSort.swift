import AlgorithmKit
import SortEngineKit

/// The cube-root-block successor to Laziest Stable Sort. First insertion-sort runs of roughly
/// `cbrt(n)` elements, then merge them in groups of roughly `cbrt(n)²` from right to left.
/// `fragmentedMerge` finishes by inserting a block's elements into the sorted suffix using
/// galloping searches and stable rotations. This preserves the source's forward/backward merge
/// distinction: the backward pass rotates the shorter right run against the left run.
///
/// Every rotation is a permutation of adjacent blocks through the already-shipped Grail rotation
/// primitive. It has the same result as the source's `cycleReverse` and block-swap rotations, but
/// records the exchanges as real engine swaps. Ties stay in their original order: insertion uses
/// the rightmost equal position, the forward merge moves only strict inversions, and the backward
/// merge searches past equal left values before rotating.
public struct LazierestSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lazierestsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Lazierest Stable",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1007, coefficients: [239834, 410.204, 0.170115],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.170115, 67.5915, -735.724], rSquared: 0.999875),
    implementationComplexity: 86,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n²)"),
    spaceComplexity: "O(1)",
    iconName: "moon.stars.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func ceilCbrt(_ value: Int) -> Int {
      var low = 0
      var high = min(1291, value)
      while low < high {
        let mid = (low + high) / 2
        if mid * mid * mid >= value { high = mid } else { low = mid + 1 }
      }
      return low
    }

    func rotate(_ a: Int, _ m: Int, _ b: Int) {
      GrailSortingTemplate.rotate(&engine, a, m - a, b - m)
    }

    func insertTo(_ source: Int, _ destination: Int) {
      let value = engine.readValue(at: source)
      var index = source
      while index > destination {
        engine.setValue(index, engine.readValue(at: index - 1))
        index -= 1
      }
      engine.setValue(destination, value)
    }

    func leftBinSearch(_ aIn: Int, _ bIn: Int, _ value: Int) -> Int {
      var a = aIn
      var b = bIn
      while a < b {
        let mid = a + (b - a) / 2
        if engine.compareValue(mid, against: value, by: >=) { b = mid } else { a = mid + 1 }
      }
      return a
    }

    func rightBinSearch(_ aIn: Int, _ bIn: Int, _ value: Int) -> Int {
      var a = aIn
      var b = bIn
      while a < b {
        let mid = a + (b - a) / 2
        if engine.compareValue(mid, against: value, by: >) { b = mid } else { a = mid + 1 }
      }
      return a
    }

    func leftExpSearch(_ a: Int, _ b: Int, _ value: Int) -> Int {
      var step = 1
      while a - 1 + step < b && engine.compareValue(a - 1 + step, against: value, by: <) {
        step *= 2
      }
      return leftBinSearch(a + step / 2, min(b, a - 1 + step), value)
    }

    func rightExpSearch(_ a: Int, _ b: Int, _ value: Int) -> Int {
      var step = 1
      while b - step >= a && engine.compareValue(b - step, against: value, by: >) {
        step *= 2
      }
      return rightBinSearch(max(a, b - step + 1), b - step / 2, value)
    }

    func binaryInsertion(_ a: Int, _ b: Int) {
      guard b - a > 1 else { return }
      for index in (a + 1)..<b {
        insertTo(index, rightBinSearch(a, index, engine.readValue(at: index)))
      }
    }

    func mergeForward(_ a: Int, _ m: Int, _ b: Int) {
      var i = a
      var j = m
      while i < j && j < b {
        if engine.compare(i, j, by: >) {
          let k = leftExpSearch(j + 1, b, engine.readValue(at: i))
          rotate(i, j, k)
          i += k - j
          j = k
        } else {
          i += 1
        }
      }
    }

    func mergeBackward(_ a: Int, _ m: Int, _ b: Int) {
      var i = m - 1
      var j = b - 1
      while j > i && i >= a {
        if engine.compare(i, j, by: >) {
          let k = rightExpSearch(a, i, engine.readValue(at: j))
          rotate(k, i + 1, j + 1)
          j -= i + 1 - k
          i = k - 1
        } else {
          j -= 1
        }
      }
    }

    func inPlaceMerge(_ a: Int, _ m: Int, _ b: Int) {
      if b - m < m - a {
        mergeBackward(a, m, b)
      } else {
        mergeForward(a, m, b)
      }
    }

    func fragmentedMerge(_ start: Int, _ middle: Int, _ end: Int, _ size: Int) {
      var a = start
      var m = middle
      var i = a + (m - a) % size
      while i < m {
        let j = leftExpSearch(m, end, engine.readValue(at: i))
        rotate(i, m, j)
        let rightLength = j - m
        let boundary = i
        i += rightLength
        m += rightLength
        inPlaceMerge(a, boundary, i)
        a = i
        i += size
      }
      inPlaceMerge(max(a, i - size), i, end)
    }

    if n <= 16 {
      binaryInsertion(0, n)
      return
    }

    let size = ceilCbrt(n)
    let groupSize = size * size
    var i = n % size
    while i <= n {
      binaryInsertion(max(0, i - size), i)
      i += size
    }

    i = n - size
    var j = n
    while i > 0 {
      if j - i == groupSize {
        j -= groupSize
        i -= size
      }
      mergeForward(max(0, i - size), i, j)
      i -= size
    }

    i = n - groupSize
    while i > 0 {
      fragmentedMerge(max(0, i - groupSize), i, n, size)
      i -= groupSize
    }
  }
}
