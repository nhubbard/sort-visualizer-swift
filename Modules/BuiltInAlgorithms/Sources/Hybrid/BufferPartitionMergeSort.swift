import AlgorithmKit
import Foundation
import SortEngineKit

/// An in-place hybrid that sorts the upper half into the lower half as a swap buffer, then
/// repeatedly selects a buffer-sized partition from the unsorted prefix and merges it into the
/// sorted suffix. The buffer moves forward with each merge until only a small prefix remains;
/// binary insertion sort and an in-place rotation merge finish that prefix.
///
/// Median-of-three selection handles ordinary partitions. A severely unbalanced split switches
/// to median-of-five groups so selection cannot repeatedly make negligible progress. Partitioning
/// and buffer swaps can reorder equal elements, so the algorithm is not stable.
public struct BufferPartitionMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bufferpartitionmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Buffer Partition Merge Sort",
    category: .hybrid,
    sizeRange: 16...1831,
    growthModel: OperationGrowthModel(
      anchorSize: 1831, coefficients: [200223, 132.505, 0.00713212],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [8.06341, 1.07862], rSquared: 0.998237),
    implementationComplexity: 83,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"
    ),
    spaceComplexity: "O(1)",
    iconName: "rectangle.split.2x1"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    Self.sort(&engine, 0, engine.count)
  }

  private static func insertion(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for i in (start + 1)..<end {
      var j = i
      while j > start && engine.teachingCompare(
        j - 1, j, by: >,
        stageID: "BufferPartitionMergeSort.smallRun.insert",
        whenTrue: "The preceding value is larger, so insertion swaps the adjacent pair.",
        whenFalse: "The pair is ordered, so this insertion scan can stop."
      ) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }

  private static func binaryInsertion(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for i in (start + 1)..<end {
      let value = engine.readValue(at: i)
      var low = start
      var high = i
      while low < high {
        let middle = low + (high - low) / 2
        if engine.teachingCompareValue(
          middle, against: value, by: >,
          stageID: "BufferPartitionMergeSort.binaryInsert",
          whenTrue: "This run value exceeds the held item, so binary insertion searches the left half.",
          whenFalse: "This run value is no greater, so binary insertion searches the right half."
        ) {
          high = middle
        } else {
          low = middle + 1
        }
      }
      var j = i
      while j > low {
        engine.setValue(j, engine.readValue(at: j - 1))
        j -= 1
      }
      engine.setValue(low, value)
    }
  }

  private static func shiftBackward(
    _ engine: inout RecordingEngine, _ start: Int, _ middle: Int, _ end: Int
  ) {
    var middle = middle
    var end = end
    while middle > start {
      middle -= 1
      end -= 1
      engine.swap(end, middle)
    }
  }

  private static func multiSwap(
    _ engine: inout RecordingEngine, _ first: Int, _ second: Int, _ length: Int
  ) {
    for offset in 0..<length {
      engine.swap(first + offset, second + offset)
    }
  }

  private static func rotate(
    _ engine: inout RecordingEngine, _ start: Int, _ middle: Int, _ end: Int
  ) {
    var start = start
    var middle = middle
    var end = end
    var leftLength = middle - start
    var rightLength = end - middle

    while leftLength > 0 && rightLength > 0 {
      if rightLength < leftLength {
        multiSwap(&engine, middle - rightLength, middle, rightLength)
        end -= rightLength
        middle -= rightLength
        leftLength -= rightLength
      } else {
        multiSwap(&engine, start, middle, leftLength)
        start += leftLength
        middle += leftLength
        rightLength -= leftLength
      }
    }
  }

  private static func inPlaceMerge(
    _ engine: inout RecordingEngine, _ start: Int, _ middle: Int, _ end: Int
  ) {
    var left = start
    var right = middle
    while left < right && right < end {
      if engine.compare(left, right, by: >) {
        var upper = right + 1
        while upper < end && engine.compare(left, upper, by: >) {
          upper += 1
        }
        rotate(&engine, left, right, upper)
        left += upper - right
        right = upper
      } else {
        left += 1
      }
    }
  }

  private static func medianOfThree(
    _ engine: inout RecordingEngine, _ start: Int, _ end: Int
  ) {
    let middle = start + (end - 1 - start) / 2
    if engine.compare(start, middle, by: >) {
      engine.swap(start, middle)
    }
    if engine.compare(middle, end - 1, by: >) {
      engine.swap(middle, end - 1)
      if engine.compare(start, middle, by: >) {
        return
      }
    }
    engine.swap(start, middle)
  }

  private static func medianOfMedians(
    _ engine: inout RecordingEngine, _ start: Int, _ end: Int, _ stride: Int
  ) {
    var reducedEnd = end
    var alternate = true
    while reducedEnd - start > 1 {
      var destination = start
      var groupStart = start
      while groupStart + 2 * stride <= reducedEnd {
        insertion(&engine, groupStart, groupStart + stride)
        engine.swap(destination, groupStart + stride / 2)
        destination += 1
        groupStart += stride
      }
      if groupStart < reducedEnd {
        insertion(&engine, groupStart, reducedEnd)
        let median = groupStart + (reducedEnd - (alternate ? 1 : 0) - groupStart) / 2
        engine.swap(destination, median)
        destination += 1
        if (reducedEnd - groupStart).isMultiple(of: 2) {
          alternate.toggle()
        }
      }
      reducedEnd = destination
    }
  }

  private static func partition(
    _ engine: inout RecordingEngine, _ start: Int, _ end: Int
  ) -> Int {
    var left = start
    var right = end
    while true {
      repeat {
        left += 1
      } while left < right && engine.compare(left, start, by: >)
      repeat {
        right -= 1
      } while right >= left && engine.compare(right, start, by: <)
      if left < right {
        engine.swap(left, right)
      } else {
        return right
      }
    }
  }

  private static func quickSelect(
    _ engine: inout RecordingEngine, _ lower: Int, _ upper: Int, _ target: Int
  ) -> Int {
    var lower = lower
    var upper = upper
    var badPartition = false
    var usedMedianOfMedians = false
    let targetUpperBound = (target + upper + 1) / 2

    while true {
      if badPartition {
        medianOfMedians(&engine, lower, upper, 5)
        usedMedianOfMedians = true
      } else {
        medianOfThree(&engine, lower, upper)
      }

      let pivot = partition(&engine, lower, upper)
      engine.swap(lower, pivot)

      let leftLength = max(1, pivot - lower)
      let rightLength = max(1, upper - (pivot + 1))
      badPartition = !usedMedianOfMedians &&
        (leftLength / rightLength >= 16 || rightLength / leftLength >= 16)

      if pivot >= target && pivot < targetUpperBound {
        return pivot
      } else if pivot < target {
        lower = pivot + 1
      } else {
        upper = pivot
      }
    }
  }

  private static func merge(
    _ engine: inout RecordingEngine, _ start: Int, _ middle: Int, _ end: Int,
    into destinationStart: Int
  ) {
    var left = start
    var right = middle
    var destination = destinationStart
    while left < middle && right < end {
      if engine.compare(left, right, by: <=) {
        engine.swap(destination, left)
        left += 1
      } else {
        engine.swap(destination, right)
        right += 1
      }
      destination += 1
    }
    while left < middle {
      engine.swap(destination, left)
      destination += 1
      left += 1
    }
    while right < end {
      engine.swap(destination, right)
      destination += 1
      right += 1
    }
  }

  private static func mergeForward(
    _ engine: inout RecordingEngine, _ destinationStart: Int, _ start: Int, _ middle: Int, _ end: Int
  ) -> Int {
    var destination = destinationStart
    var left = start
    var right = middle
    while left < middle && right < end {
      if engine.compare(left, right, by: <=) {
        engine.swap(destination, left)
        left += 1
      } else {
        engine.swap(destination, right)
        right += 1
      }
      destination += 1
    }
    return left < middle ? left : right
  }

  private static func minimumLevel(_ length: Int) -> Int {
    var length = length
    while length >= 32 {
      length = (length + 3) / 4
    }
    return length
  }

  private static func mergeSort(
    _ engine: inout RecordingEngine, _ start: Int, _ end: Int, _ bufferStart: Int
  ) {
    let length = end - start
    guard length > 1 else { return }

    var width = minimumLevel(length)
    var i = start
    while i + width <= end {
      binaryInsertion(&engine, i, i + width)
      i += width
    }
    binaryInsertion(&engine, i, end)

    while width < length {
      var destination = bufferStart
      i = start
      while i + 2 * width <= end {
        merge(&engine, i, i + width, i + 2 * width, into: destination)
        i += 2 * width
        destination += 2 * width
      }
      if i + width < end {
        merge(&engine, i, i + width, end, into: destination)
      } else {
        while i < end {
          engine.swap(i, destination)
          i += 1
          destination += 1
        }
      }
      width *= 2

      destination = start
      i = bufferStart
      while i + 2 * width <= bufferStart + length {
        merge(&engine, i, i + width, i + 2 * width, into: destination)
        i += 2 * width
        destination += 2 * width
      }
      if i + width < bufferStart + length {
        merge(&engine, i, i + width, bufferStart + length, into: destination)
      } else {
        while i < bufferStart + length {
          engine.swap(i, destination)
          i += 1
          destination += 1
        }
      }
      width *= 2
    }
  }

  private static func sort(
    _ engine: inout RecordingEngine, _ lowerBound: Int, _ upperBound: Int
  ) {
    var start = lowerBound
    var middle = (lowerBound + upperBound + 1) / 2
    let minimumLevel = Int(Double(upperBound - lowerBound).squareRoot())

    mergeSort(&engine, middle, upperBound, start)

    while middle - start > minimumLevel {
      var selected = (start + middle + 1) / 2
      selected = quickSelect(&engine, start, middle, selected)
      mergeSort(&engine, selected, middle, start)

      let bufferLength = selected - start
      var mergeEnd = min(selected + bufferLength, upperBound)
      selected = mergeForward(&engine, start, selected, middle, mergeEnd)

      while selected < middle {
        shiftBackward(&engine, selected, middle, mergeEnd)
        selected = mergeEnd - (middle - selected)
        start = selected - bufferLength
        middle = mergeEnd

        if middle == upperBound {
          break
        }

        mergeEnd = min(mergeEnd + bufferLength, upperBound)
        selected = mergeForward(&engine, start, selected, middle, mergeEnd)
      }
      middle = selected
      start = selected - bufferLength
    }

    binaryInsertion(&engine, start, middle)
    inPlaceMerge(&engine, start, middle, upperBound)
  }
}
