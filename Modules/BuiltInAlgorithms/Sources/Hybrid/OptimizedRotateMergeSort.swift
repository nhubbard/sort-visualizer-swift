import AlgorithmKit
import SortEngineKit

/// A bounded-buffer port of ArrayV's optimized rotate merge sort. It sorts 32-element runs by
/// insertion, then doubles their length through stable merges. A merge copies its shorter side
/// into a 64-element auxiliary buffer when possible; larger merges partition at a median,
/// rotate the crossing blocks, and recurse. The in-place rotation uses reversals rather than
/// ArrayV's four-pointer rotation, preserving the same block order with simpler tape operations.
public struct OptimizedRotateMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedrotatemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Rotate Merge",
    category: .hybrid,
    sizeRange: 16...1813,
    growthModel: OperationGrowthModel(
      anchorSize: 1813, coefficients: [239942, 227.07, 0.0521322],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0521322, 38.0386, -378.968], rSquared: 0.999971),
    implementationComplexity: 52,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log² n)"),
    spaceComplexity: "O(log n)",
    iconName: "arrow.clockwise"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let count = engine.count
    guard count > 1 else { return }
    let capacity = 64
    let handle = engine.createAuxArray(length: capacity)
    var buffer = Array(repeating: 0, count: capacity)

    func save(_ index: Int, _ value: Int) {
      buffer[index] = value
      engine.writeAux(handle, at: index, value: value)
    }

    func load(_ index: Int) -> Int {
      engine.markAuxRead(handle, at: index)
      return buffer[index]
    }

    func lowerBound(_ start: Int, _ end: Int, _ value: Int) -> Int {
      var low = start
      var high = end
      while low < high {
        let middle = low + (high - low) / 2
        if engine.teachingCompareValue(
          middle, against: value, by: (<),
          stageID: "OptimizedRotateMergeSort.merge.boundary",
          whenTrue: "This run value is below the held value, so the boundary search advances.",
          whenFalse: "This run value is at least the held value, so the boundary search moves left."
        ) {
          low = middle + 1
        } else {
          high = middle
        }
      }
      return low
    }

    func upperBound(_ start: Int, _ end: Int, _ value: Int) -> Int {
      var low = start
      var high = end
      while low < high {
        let middle = low + (high - low) / 2
        if engine.teachingCompareValue(
          middle, against: value, by: (<=),
          stageID: "OptimizedRotateMergeSort.upperBound",
          whenTrue: "This value is no greater than the held item, so insertion searches farther right.",
          whenFalse: "This value is greater, so insertion narrows the boundary to the left."
        ) {
          low = middle + 1
        } else {
          high = middle
        }
      }
      return low
    }

    func rotate(_ start: Int, _ middle: Int, _ end: Int) {
      guard start < middle && middle < end else { return }
      let left = middle - start
      let right = end - middle
      if left <= capacity {
        for offset in 0..<left { save(offset, engine.readValue(at: start + offset)) }
        for index in middle..<end {
          engine.setValue(index - left, engine.readValue(at: index))
        }
        for offset in 0..<left { engine.setValue(end - left + offset, load(offset)) }
      } else if right <= capacity {
        for offset in 0..<right { save(offset, engine.readValue(at: middle + offset)) }
        for index in stride(from: middle - 1, through: start, by: -1) {
          engine.setValue(index + right, engine.readValue(at: index))
        }
        for offset in 0..<right { engine.setValue(start + offset, load(offset)) }
      } else {
        engine.reversal(start, middle - 1)
        engine.reversal(middle, end - 1)
        engine.reversal(start, end - 1)
      }
    }

    func bufferedMerge(_ start: Int, _ middle: Int, _ end: Int) {
      let leftLength = middle - start
      let rightLength = end - middle
      if leftLength <= rightLength {
        for offset in 0..<leftLength { save(offset, engine.readValue(at: start + offset)) }
        var left = 0
        var right = middle
        var destination = start
        while left < leftLength && right < end {
          let leftValue = load(left)
          if engine.compareValue(right, against: leftValue, by: (<)) {
            engine.setValue(destination, engine.readValue(at: right))
            right += 1
          } else {
            engine.setValue(destination, leftValue)
            left += 1
          }
          destination += 1
        }
        while left < leftLength {
          engine.setValue(destination, load(left))
          left += 1
          destination += 1
        }
      } else {
        for offset in 0..<rightLength { save(offset, engine.readValue(at: middle + offset)) }
        var left = middle - 1
        var right = rightLength - 1
        var destination = end - 1
        while left >= start && right >= 0 {
          let rightValue = load(right)
          if engine.compareValue(left, against: rightValue, by: (>)) {
            engine.setValue(destination, engine.readValue(at: left))
            left -= 1
          } else {
            engine.setValue(destination, rightValue)
            right -= 1
          }
          destination -= 1
        }
        while right >= 0 {
          engine.setValue(destination, load(right))
          right -= 1
          destination -= 1
        }
      }
    }

    func merge(_ start: Int, _ middle: Int, _ end: Int) {
      guard start < middle && middle < end else { return }
      guard engine.compare(middle - 1, middle, by: (>)) else { return }
      if min(middle - start, end - middle) <= capacity {
        bufferedMerge(start, middle, end)
        return
      }
      let leftSplit: Int
      let rightSplit: Int
      if middle - start >= end - middle {
        leftSplit = start + (middle - start) / 2
        rightSplit = lowerBound(middle, end, engine.readValue(at: leftSplit))
      } else {
        rightSplit = middle + (end - middle) / 2
        leftSplit = upperBound(start, middle, engine.readValue(at: rightSplit))
      }
      rotate(leftSplit, middle, rightSplit)
      let newMiddle = leftSplit + rightSplit - middle
      merge(start, leftSplit, newMiddle)
      merge(newMiddle, rightSplit, end)
    }

    func insertionSort(_ start: Int, _ end: Int) {
      guard end - start > 1 else { return }
      for index in (start + 1)..<end {
        let value = engine.readValue(at: index)
        let destination = upperBound(start, index, value)
        var cursor = index
        while cursor > destination {
          engine.setValue(cursor, engine.readValue(at: cursor - 1))
          cursor -= 1
        }
        if destination != index { engine.setValue(destination, value) }
      }
    }

    var start = 0
    while start < count {
      insertionSort(start, min(start + 32, count))
      start += 32
    }
    var run = 32
    while run < count {
      var lower = 0
      while lower + run < count {
        merge(lower, lower + run, min(lower + 2 * run, count))
        lower += 2 * run
      }
      run *= 2
    }
    engine.deleteAuxArray(handle)
  }
}
