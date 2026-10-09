import AlgorithmKit
import SortEngineKit

/// ArrayV's median-merge hybrid: partition around a median pivot, merge-sort the smaller side
/// using the larger side as an in-array swap buffer, then repeat on that larger side. A bad split
/// switches the next pivot selection to median-of-five groups. No auxiliary array is allocated:
/// every displaced buffer value is swapped back during the second merge pass.
///
/// This is not stable: partitioning and the buffer exchanges can reorder equal elements.
public struct MedianMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "medianmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Median Merge",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1394, coefficients: [239914, 322.843, 0.10802],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.10802, 21.6839, -221.74], rSquared: 0.999949),
    implementationComplexity: 62,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n²)"),
    spaceComplexity: "O(1)",
    iconName: "rectangle.stack.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let count = engine.count
    guard count > 1 else { return }
    Self.sort(&engine, 0, count)
  }

  private static func insertion(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    guard b - a > 1 else { return }
    for i in (a + 1)..<b {
      var j = i
      while j > a && engine.compare(j - 1, j, by: >) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }

  private static func binaryInsertion(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    guard b - a > 1 else { return }
    for i in (a + 1)..<b {
      let value = engine.readValue(at: i)
      var low = a
      var high = i
      while low < high {
        let mid = low + (high - low) / 2
        if value < engine.readValue(at: mid) { high = mid } else { low = mid + 1 }
      }
      var j = i
      while j > low {
        engine.setValue(j, engine.readValue(at: j - 1))
        j -= 1
      }
      engine.setValue(low, value)
    }
  }

  private static func medianOfThree(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    let m = a + (b - 1 - a) / 2
    if engine.compare(a, m, by: >) { engine.swap(a, m) }
    if engine.compare(m, b - 1, by: >) {
      engine.swap(m, b - 1)
      if engine.compare(a, m, by: >) { return }
    }
    engine.swap(a, m)
  }

  private static func medianOfMedians(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    var end = b
    let start = a
    var alternate = true
    while end - start > 1 {
      var j = start
      var i = start
      while i + 10 <= end {
        insertion(&engine, i, i + 5)
        engine.swap(j, i + 2)
        j += 1
        i += 5
      }
      if i < end {
        insertion(&engine, i, end)
        engine.swap(j, i + (end - (alternate ? 1 : 0) - i) / 2)
        j += 1
        if (end - i) % 2 == 0 { alternate.toggle() }
      }
      end = j
    }
  }

  private static func partition(_ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ pivot: Int) -> Int {
    var i = a - 1
    var j = b
    while true {
      repeat { i += 1 } while i < j && engine.compare(i, pivot, by: <)
      repeat { j -= 1 } while j >= i && engine.compare(j, pivot, by: >)
      if i >= j { return j }
      engine.swap(i, j)
    }
  }

  private static func merge(_ engine: inout RecordingEngine, _ a: Int, _ m: Int, _ b: Int, _ p: Int) {
    var i = a
    var j = m
    var dest = p
    while i < m && j < b {
      if engine.compare(i, j, by: <=) {
        engine.swap(dest, i)
        i += 1
      } else {
        engine.swap(dest, j)
        j += 1
      }
      dest += 1
    }
    while i < m { engine.swap(dest, i); dest += 1; i += 1 }
    while j < b { engine.swap(dest, j); dest += 1; j += 1 }
  }

  private static func mergeSort(_ engine: inout RecordingEngine, _ a: Int, _ b: Int, _ p: Int) {
    let length = b - a
    guard length > 1 else { return }
    var width = length
    while width >= 32 { width = (width + 3) / 4 }

    var i = a
    while i + width <= b {
      binaryInsertion(&engine, i, i + width)
      i += width
    }
    binaryInsertion(&engine, i, b)

    while width < length {
      var pos = p
      i = a
      while i + 2 * width <= b {
        merge(&engine, i, i + width, i + 2 * width, pos)
        i += 2 * width
        pos += 2 * width
      }
      if i + width < b {
        merge(&engine, i, i + width, b, pos)
      } else {
        while i < b { engine.swap(i, pos); i += 1; pos += 1 }
      }
      width *= 2

      pos = a
      i = p
      while i + 2 * width <= p + length {
        merge(&engine, i, i + width, i + 2 * width, pos)
        i += 2 * width
        pos += 2 * width
      }
      if i + width < p + length {
        merge(&engine, i, i + width, p + length, pos)
      } else {
        while i < p + length { engine.swap(i, pos); i += 1; pos += 1 }
      }
      width *= 2
    }
  }

  private static func sort(_ engine: inout RecordingEngine, _ a: Int, _ b: Int) {
    var start = a
    var end = b
    var badPartition = false
    var usedMedianOfMedians = false
    while end - start > 16 {
      if badPartition {
        medianOfMedians(&engine, start, end)
        usedMedianOfMedians = true
      } else {
        medianOfThree(&engine, start, end)
      }
      let pivot = partition(&engine, start + 1, end, start)
      engine.swap(start, pivot)
      let left = pivot - start
      let right = end - pivot - 1
      badPartition = !usedMedianOfMedians &&
        (left == 0 || right == 0 || (left > 0 && right > 0 && (left / right >= 16 || right / left >= 16)))
      if left <= right {
        mergeSort(&engine, start, pivot, pivot + 1)
        start = pivot + 1
      } else {
        mergeSort(&engine, pivot + 1, end, 2 * pivot + 1 - end)
        end = pivot
      }
    }
    binaryInsertion(&engine, start, end)
  }
}
