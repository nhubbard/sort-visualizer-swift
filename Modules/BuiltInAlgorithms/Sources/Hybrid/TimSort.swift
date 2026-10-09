import AlgorithmKit
import SortEngineKit

// Copyright (C) 2008 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// A stable TimSort port. Strict descending runs can be reversed without moving equal keys past
/// each other. Short runs are extended by binary insertion, and the run stack enforces the two
/// length inequalities used by the corrected TimSort merge policy. A merge copies only its shorter
/// run; repeated wins switch to exponential searches, with the gallop threshold adjusted after
/// galloping merges. The run stack and merge buffer are both visible as recorded auxiliary arrays.
public struct TimSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "timsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Tim Sort",
    category: .hybrid,
    sizeRange: 16...1514,
    growthModel: OperationGrowthModel(
      anchorSize: 1514, coefficients: [208131, 223.798, 0.0455658],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [0.513859, 1.4914], rSquared: 0.479314),
    implementationComplexity: 264,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.triangle.merge"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    let worker = TimSortRecorder(engine: engine)
    worker.sort()
    engine = worker.engine
  }
}

private final class TimSortRecorder {
  var engine: RecordingEngine
  private let count: Int
  private let stackCapacity: Int
  private var runBase: [Int]
  private var runLength: [Int]
  private let baseHandle: AuxHandle
  private let lengthHandle: AuxHandle
  private var stackSize = 0
  private var temp: [Int] = []
  private var tempHandle: AuxHandle?
  private var minGallop = 7

  init(engine: RecordingEngine) {
    self.engine = engine
    count = engine.count
    stackCapacity = count < 120 ? 5 : count < 1542 ? 10 : count < 119_151 ? 19 : 40
    runBase = Array(repeating: 0, count: stackCapacity)
    runLength = Array(repeating: 0, count: stackCapacity)
    baseHandle = self.engine.createAuxArray(length: stackCapacity)
    lengthHandle = self.engine.createAuxArray(length: stackCapacity)
  }

  private func base(_ index: Int) -> Int {
    engine.markAuxRead(baseHandle, at: index)
    return runBase[index]
  }

  private func length(_ index: Int) -> Int {
    engine.markAuxRead(lengthHandle, at: index)
    return runLength[index]
  }

  private func setBase(_ index: Int, _ value: Int) {
    runBase[index] = value
    engine.writeAux(baseHandle, at: index, value: value)
  }

  private func setLength(_ index: Int, _ value: Int) {
    runLength[index] = value
    engine.writeAux(lengthHandle, at: index, value: value)
  }

  private func save(_ index: Int, _ value: Int) {
    temp[index] = value
    if let tempHandle { engine.writeAux(tempHandle, at: index, value: value) }
  }

  private func load(_ index: Int) -> Int {
    if let tempHandle { engine.markAuxRead(tempHandle, at: index) }
    return temp[index]
  }

  private func ensureCapacity(_ minimum: Int) {
    guard temp.count < minimum else { return }
    if let tempHandle { engine.deleteAuxArray(tempHandle) }
    var capacity = max(1, temp.count)
    while capacity < minimum { capacity *= 2 }
    capacity = min(capacity, max(1, count / 2))
    temp = Array(repeating: 0, count: capacity)
    tempHandle = engine.createAuxArray(length: capacity)
  }

  private func minRunLength(_ value: Int) -> Int {
    var n = value
    var remainder = 0
    while n >= 32 {
      remainder |= n & 1
      n >>= 1
    }
    return n + remainder
  }

  private func countRun(_ start: Int, _ end: Int) -> Int {
    guard start + 1 < end else { return 1 }
    var cursor = start + 2
    if engine.teachingCompare(
      start + 1, start, by: (<),
      stageID: "TimSort.run.direction",
      whenTrue: "The run begins in descending order, so TimSort scans and reverses it.",
      whenFalse: "The run begins in nondecreasing order, so TimSort extends it forward."
    ) {
      while cursor < end && engine.teachingCompare(
        cursor, cursor - 1, by: (<),
        stageID: "TimSort.run.descending",
        whenTrue: "The run keeps descending, so extend it before reversing.",
        whenFalse: "The descending run ends here."
      ) { cursor += 1 }
      engine.teachingReversal(start, cursor - 1,
        stageID: "TimSort.run.reverse",
        explanation: "Reverse the descending run to make it ascending.")
    } else {
      while cursor < end && engine.teachingCompare(
        cursor, cursor - 1, by: (>=),
        stageID: "TimSort.run.ascending",
        whenTrue: "The run keeps ascending, so extend it.",
        whenFalse: "The ascending run ends here."
      ) { cursor += 1 }
    }
    return cursor - start
  }

  private func binaryInsertion(_ start: Int, _ end: Int, _ sortedEnd: Int) {
    var cursor = max(start + 1, sortedEnd)
    while cursor < end {
      let pivot = engine.readValue(at: cursor)
      var low = start
      var high = cursor
      while low < high {
        let middle = low + (high - low) / 2
        if engine.teachingCompareValue(
          middle, against: pivot, by: (<=),
          stageID: "TimSort.run.extend",
          whenTrue: "The prefix value is no greater than the held value, so search right.",
          whenFalse: "The prefix value is larger, so search left for insertion."
        ) { low = middle + 1 }
        else { high = middle }
      }
      var shift = cursor
      while shift > low {
        engine.setValue(shift, engine.readValue(at: shift - 1))
        shift -= 1
      }
      engine.setValue(low, pivot)
      cursor += 1
    }
  }

  private func pushRun(_ start: Int, _ runLength: Int) {
    setBase(stackSize, start)
    setLength(stackSize, runLength)
    stackSize += 1
  }

  private func collapse() {
    while stackSize > 1 {
      var index = stackSize - 2
      if (index >= 1 && length(index - 1) <= length(index) + length(index + 1)) ||
        (index >= 2 && length(index - 2) <= length(index) + length(index - 1)) {
        if length(index - 1) < length(index + 1) { index -= 1 }
      } else if length(index) > length(index + 1) {
        break
      }
      mergeAt(index)
    }
  }

  private func forceCollapse() {
    while stackSize > 1 {
      var index = stackSize - 2
      if index > 0 && length(index - 1) < length(index + 1) { index -= 1 }
      mergeAt(index)
    }
  }

  /// Exponential search from either end, followed by binary search in the bracket. `upper`
  /// places equal keys after the searched run; `lower` places them before it.
  private func gallop(
    _ start: Int, _ end: Int, _ key: Int, upper: Bool, fromEnd: Bool,
    valueAt: (Int) -> Int
  ) -> Int {
    guard start < end else { return start }
    func beforeInsertion(_ index: Int) -> Bool {
      let value = valueAt(index)
      return engine.teachingCompareValues(
        value, key, by: upper ? (<=) : (<),
        stageID: "TimSort.merge.gallop",
        whenTrue: "This run value belongs before the insertion boundary, so continue galloping.",
        whenFalse: "This run value reaches the insertion boundary, so stop the gallop."
      )
    }
    var low: Int
    var high: Int
    if fromEnd {
      high = end
      low = end - 1
      var step = 1
      while !beforeInsertion(low) {
        high = low
        if low == start { break }
        step = min(end - start, step * 2)
        low = max(start, end - step)
      }
    } else {
      low = start
      high = start + 1
      while beforeInsertion(high - 1) && high < end {
        low = high
        high = min(end, start + (high - start) * 2)
      }
    }
    while low < high {
      let middle = low + (high - low) / 2
      if beforeInsertion(middle) { low = middle + 1 }
      else { high = middle }
    }
    return low
  }

  private func mainGallop(_ start: Int, _ end: Int, _ key: Int, upper: Bool, fromEnd: Bool = false) -> Int {
    gallop(start, end, key, upper: upper, fromEnd: fromEnd) { engine.readValue(at: $0) }
  }

  private func tempGallop(_ start: Int, _ end: Int, _ key: Int, upper: Bool, fromEnd: Bool = false) -> Int {
    gallop(start, end, key, upper: upper, fromEnd: fromEnd) { load($0) }
  }

  private func mergeAt(_ index: Int) {
    var leftStart = base(index)
    var leftLength = length(index)
    let rightStart = base(index + 1)
    var rightLength = length(index + 1)
    setLength(index, leftLength + rightLength)
    if index == stackSize - 3 {
      setBase(index + 1, base(index + 2))
      setLength(index + 1, length(index + 2))
    }
    stackSize -= 1

    let firstRight = engine.readValue(at: rightStart)
    let skippedLeft = mainGallop(leftStart, rightStart, firstRight, upper: true)
    leftLength -= skippedLeft - leftStart
    leftStart = skippedLeft
    if leftLength == 0 { return }

    let lastLeft = engine.readValue(at: rightStart - 1)
    rightLength = mainGallop(rightStart, rightStart + rightLength, lastLeft, upper: false) - rightStart
    if rightLength == 0 { return }

    if leftLength <= rightLength { mergeLow(leftStart, leftLength, rightStart, rightLength) }
    else { mergeHigh(leftStart, leftLength, rightStart, rightLength) }
  }

  private func mergeLow(_ leftStart: Int, _ leftLength: Int, _ rightStart: Int, _ rightLength: Int) {
    ensureCapacity(leftLength)
    for offset in 0..<leftLength { save(offset, engine.readValue(at: leftStart + offset)) }
    var left = 0
    var right = rightStart
    var destination = leftStart
    let rightEnd = rightStart + rightLength
    var leftWins = 0
    var rightWins = 0
    var galloped = false
    while left < leftLength && right < rightEnd {
      if engine.teachingCompareValues(
        engine.readValue(at: right), load(left), by: (<),
        stageID: "TimSort.merge.lowChoice",
        whenTrue: "The right run has the smaller value, so write it next.",
        whenFalse: "The left run wins or ties, so write its value next."
      ) {
        engine.setValue(destination, engine.readValue(at: right))
        right += 1
        rightWins += 1
        leftWins = 0
      } else {
        engine.setValue(destination, load(left))
        left += 1
        leftWins += 1
        rightWins = 0
      }
      destination += 1
      if left >= leftLength || right >= rightEnd { break }
      if max(leftWins, rightWins) < minGallop { continue }
      galloped = true

      let leftStop = tempGallop(left, leftLength, engine.readValue(at: right), upper: true)
      while left < leftStop {
        engine.setValue(destination, load(left))
        left += 1
        destination += 1
      }
      if left == leftLength { break }
      engine.setValue(destination, engine.readValue(at: right))
      right += 1
      destination += 1
      if right == rightEnd { break }

      let rightStop = mainGallop(right, rightEnd, load(left), upper: false)
      while right < rightStop {
        engine.setValue(destination, engine.readValue(at: right))
        right += 1
        destination += 1
      }
      if right == rightEnd { break }
      engine.setValue(destination, load(left))
      left += 1
      destination += 1
      minGallop = max(1, minGallop - 1)
      leftWins = 0
      rightWins = 0
    }
    while left < leftLength {
      engine.setValue(destination, load(left))
      left += 1
      destination += 1
    }
    if galloped { minGallop += 2 }
  }

  private func mergeHigh(_ leftStart: Int, _ leftLength: Int, _ rightStart: Int, _ rightLength: Int) {
    ensureCapacity(rightLength)
    for offset in 0..<rightLength { save(offset, engine.readValue(at: rightStart + offset)) }
    var left = rightStart - 1
    var right = rightLength - 1
    var destination = rightStart + rightLength - 1
    var leftWins = 0
    var rightWins = 0
    var galloped = false
    while left >= leftStart && right >= 0 {
      if engine.teachingCompareValues(
        load(right), engine.readValue(at: left), by: (<),
        stageID: "TimSort.merge.highChoice",
        whenTrue: "The left run has the larger value, so write it at the high end.",
        whenFalse: "The right run wins or ties, so write it at the high end."
      ) {
        engine.setValue(destination, engine.readValue(at: left))
        left -= 1
        leftWins += 1
        rightWins = 0
      } else {
        engine.setValue(destination, load(right))
        right -= 1
        rightWins += 1
        leftWins = 0
      }
      destination -= 1
      if left < leftStart || right < 0 { break }
      if max(leftWins, rightWins) < minGallop { continue }
      galloped = true

      let leftStop = mainGallop(leftStart, left + 1, load(right), upper: true, fromEnd: true)
      while left >= leftStop {
        engine.setValue(destination, engine.readValue(at: left))
        left -= 1
        destination -= 1
      }
      if left < leftStart { break }
      engine.setValue(destination, load(right))
      right -= 1
      destination -= 1
      if right < 0 { break }

      let rightStop = tempGallop(0, right + 1, engine.readValue(at: left), upper: false, fromEnd: true)
      while right >= rightStop {
        engine.setValue(destination, load(right))
        right -= 1
        destination -= 1
      }
      if right < 0 { break }
      engine.setValue(destination, engine.readValue(at: left))
      left -= 1
      destination -= 1
      minGallop = max(1, minGallop - 1)
      leftWins = 0
      rightWins = 0
    }
    while right >= 0 {
      engine.setValue(destination, load(right))
      right -= 1
      destination -= 1
    }
    if galloped { minGallop += 2 }
  }

  func sort() {
    if count < 32 {
      let run = countRun(0, count)
      binaryInsertion(0, count, run)
      engine.deleteAuxArray(baseHandle)
      engine.deleteAuxArray(lengthHandle)
      return
    }
    let minRun = minRunLength(count)
    var cursor = 0
    while cursor < count {
      var run = countRun(cursor, count)
      if run < minRun {
        let forced = min(minRun, count - cursor)
        binaryInsertion(cursor, cursor + forced, cursor + run)
        run = forced
      }
      pushRun(cursor, run)
      collapse()
      cursor += run
    }
    forceCollapse()
    if let tempHandle { engine.deleteAuxArray(tempHandle) }
    engine.deleteAuxArray(baseHandle)
    engine.deleteAuxArray(lengthHandle)
  }
}
