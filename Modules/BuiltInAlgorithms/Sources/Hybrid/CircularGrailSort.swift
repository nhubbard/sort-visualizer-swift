import AlgorithmKit
import SortEngineKit

/// An in-place block merge sort that treats the main array as a circular work area. The
/// first power-of-two block whose square covers the input becomes an internal rolling buffer;
/// increasingly large runs are merged through that buffer, then the final circular displacement
/// is removed with one block rotation.
///
/// Logical indices deliberately range beyond the physical array. `physicalIndex` is the only
/// conversion point, so every comparison and swap still goes through `RecordingEngine` at a valid
/// live index. The element-level merges take from the left on ties, but the whole-block selection
/// phase can move equal keys across block boundaries, so the complete algorithm is not stable.
public struct CircularGrailSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "circulargrailsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Circular Grail Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1236, coefficients: [214_288, 233.51, 0.0313828],
      measuredSafeCeiling: nil
    ),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [5.60112, 1.20642], rSquared: 0.992024
    ),
    implementationComplexity: 103,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"
    ),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.2.circlepath"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func physicalIndex(_ index: Int) -> Int {
      index % n
    }

    func circularSwap(_ a: Int, _ b: Int) {
      engine.swap(physicalIndex(a), physicalIndex(b))
    }

    func circularCompare(_ a: Int, _ b: Int, by predicate: (Int, Int) -> Bool) -> Bool {
      engine.compare(physicalIndex(a), physicalIndex(b), by: predicate)
    }

    func shiftForward(_ aIn: Int, _ middleIn: Int, _ b: Int) {
      var a = aIn
      var middle = middleIn
      while middle < b {
        circularSwap(a, middle)
        a += 1
        middle += 1
      }
    }

    func shiftBackward(_ a: Int, _ middleIn: Int, _ bIn: Int) {
      var middle = middleIn
      var b = bIn
      while middle > a {
        b -= 1
        middle -= 1
        circularSwap(b, middle)
      }
    }

    func insertion(_ a: Int, _ b: Int) {
      guard a + 1 < b else { return }
      for start in (a + 1) ..< b {
        var i = start
        while i > a, circularCompare(i - 1, i, by: >) {
          i -= 1
          circularSwap(i + 1, i)
        }
      }
    }

    func multiSwap(_ a: Int, _ b: Int, _ length: Int) {
      guard length > 0 else { return }
      for offset in 0 ..< length {
        circularSwap(a + offset, b + offset)
      }
    }

    func rotate(_ aIn: Int, _ middleIn: Int, _ bIn: Int) {
      var a = aIn
      var middle = middleIn
      var b = bIn
      var left = middle - a
      var right = b - middle
      while left > 0, right > 0 {
        if right < left {
          multiSwap(middle - right, middle, right)
          b -= right
          middle -= right
          left -= right
        } else {
          multiSwap(a, middle, left)
          a += left
          middle += left
          right -= left
        }
      }
    }

    func inPlaceMerge(_ a: Int, _ middleIn: Int, _ b: Int) {
      var i = a
      var middle = middleIn
      while i < middle, middle < b {
        if circularCompare(i, middle, by: >) {
          var k = middle + 1
          while k < b, circularCompare(i, k, by: >) {
            k += 1
          }
          rotate(i, middle, k)
          i += k - middle
          middle = k
        } else {
          i += 1
        }
      }
    }

    @discardableResult
    func merge(_ pIn: Int, _ a: Int, _ middle: Int, _ b: Int, full: Bool) -> Int {
      var p = pIn
      var i = a
      var j = middle
      while i < middle && j < b {
        if circularCompare(i, j, by: <=) {
          circularSwap(p, i)
          p += 1
          i += 1
        } else {
          circularSwap(p, j)
          p += 1
          j += 1
        }
      }
      if i < middle {
        if i > p {
          shiftForward(p, i, middle)
        }
      } else if full {
        shiftForward(p, j, b)
      }
      return i < middle ? i : j
    }

    func blockLessThan(_ a: Int, _ b: Int, _ blockLength: Int) -> Bool {
      if circularCompare(a, b, by: <) {
        return true
      }
      return circularCompare(a, b, by: ==)
        && circularCompare(a + blockLength - 1, b + blockLength - 1, by: <)
    }

    func blockMerge(_ a: Int, _ middle: Int, _ b: Int, _ blockLength: Int) {
      let b1 = b - (b - middle - 1) % blockLength - 1
      if b1 > middle {
        var b2 = b1
        var i = middle - blockLength
        while i > a, blockLessThan(b1, i, blockLength) {
          i -= blockLength
          b2 -= blockLength
        }

        var j = a
        while j < b1 - blockLength {
          var minIndex = j
          var candidate = minIndex + blockLength
          while candidate < b1 {
            if blockLessThan(candidate, minIndex, blockLength) {
              minIndex = candidate
            }
            candidate += blockLength
          }
          if minIndex != j {
            multiSwap(j, minIndex, blockLength)
          }
          j += blockLength
        }

        var frontier = a
        var next = a + blockLength
        while next < b2 {
          frontier = merge(frontier - blockLength, frontier, next, next + blockLength, full: false)
          if frontier < next {
            shiftBackward(frontier, next, next + blockLength)
            frontier += blockLength
          }
          next += blockLength
        }
        merge(frontier - blockLength, frontier, b1, b, full: true)
      } else {
        merge(a - blockLength, a, middle, b, full: true)
      }
    }

    if n <= 16 {
      insertion(0, n)
      return
    }

    var blockLength = 1
    while blockLength * blockLength < n {
      blockLength *= 2
    }

    var i = blockLength
    var runLength = 1
    let rollingLength = n - i
    var b = n
    while runLength <= blockLength {
      while i + 2 * runLength < b {
        merge(i - runLength, i, i + runLength, i + 2 * runLength, full: true)
        i += 2 * runLength
      }
      if i + runLength < b {
        merge(i - runLength, i, i + runLength, b, full: true)
      } else {
        shiftForward(i - runLength, i, b)
      }
      i = b + blockLength - runLength
      b = i + rollingLength
      runLength *= 2
    }

    while runLength < rollingLength {
      while i + 2 * runLength < b {
        blockMerge(i, i + runLength, i + 2 * runLength, blockLength)
        i += 2 * runLength
      }
      if i + runLength < b {
        blockMerge(i, i + runLength, b, blockLength)
      } else {
        shiftForward(i - blockLength, i, b)
      }
      i = b
      b += rollingLength
      runLength *= 2
    }

    insertion(i - blockLength, i)
    inPlaceMerge(i - blockLength, i, b)
    rotate(0, (i - blockLength) % n, n)
  }
}
