import AlgorithmKit
import SortEngineKit

// MIT License
// Copyright (c) 2014 Andrey Astrelin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/// Astrelin's stable square-root block merge sort. A sorted prefix is held in external storage
/// while the remaining runs use its vacated positions as a moving merge buffer. Block tags retain
/// the original half of each block, so equal keys remain stable after block selection. The small
/// recursive base case uses stable insertion sort instead of ArrayV's insertion helper.
public struct SqrtSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "sqrtsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Sqrt Sort",
    category: .hybrid,
    sizeRange: 16...1382,
    growthModel: OperationGrowthModel(
      anchorSize: 1382, coefficients: [209182, 203.327, 0.0242079],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.75237, 1.20503], rSquared: 0.991106),
    implementationComplexity: 269,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(√n)",
    iconName: "square.grid.3x3"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    var worker = SqrtSortRecorder(engine: engine)
    worker.sort()
    engine = worker.engine
  }
}

private struct SqrtSortRecorder {
  enum Storage: Equatable { case main, buffer }

  var engine: RecordingEngine
  private var buffer: [Int] = []
  private var tags: [Int] = []
  private var bufferHandle: AuxHandle?
  private var tagHandle: AuxHandle?

  private mutating func read(_ storage: Storage, _ index: Int) -> Int {
    switch storage {
    case .main: return engine.readValue(at: index)
    case .buffer:
      engine.markAuxRead(bufferHandle!, at: index)
      return buffer[index]
    }
  }

  private mutating func write(_ storage: Storage, _ index: Int, _ value: Int) {
    switch storage {
    case .main: engine.setValue(index, value)
    case .buffer:
      buffer[index] = value
      engine.writeAux(bufferHandle!, at: index, value: value)
    }
  }

  private mutating func compare(_ storage: Storage, _ a: Int, _ b: Int) -> Int {
    if storage == .main {
      if engine.compare(a, b, by: (<)) { return -1 }
      if engine.compare(a, b, by: (>)) { return 1 }
      return 0
    }
    let left = read(storage, a)
    let right = read(storage, b)
    if engine.compareValues(left, right, by: (<)) { return -1 }
    if engine.compareValues(left, right, by: (>)) { return 1 }
    return 0
  }

  private mutating func compare(_ aStorage: Storage, _ a: Int, _ bStorage: Storage, _ b: Int) -> Int {
    if aStorage == bStorage { return compare(aStorage, a, b) }
    let left = read(aStorage, a)
    let right = read(bStorage, b)
    if engine.compareValues(left, right, by: (<)) { return -1 }
    if engine.compareValues(left, right, by: (>)) { return 1 }
    return 0
  }

  private mutating func copy(_ sourceStorage: Storage, _ source: Int, _ destinationStorage: Storage, _ destination: Int, _ count: Int) {
    guard count > 0 else { return }
    if sourceStorage == destinationStorage && destination > source && destination < source + count {
      for offset in stride(from: count - 1, through: 0, by: -1) {
        write(destinationStorage, destination + offset, read(sourceStorage, source + offset))
      }
    } else {
      for offset in 0..<count {
        write(destinationStorage, destination + offset, read(sourceStorage, source + offset))
      }
    }
  }

  private mutating func swap(_ storage: Storage, _ a: Int, _ b: Int) {
    guard a != b else { return }
    let left = read(storage, a)
    let right = read(storage, b)
    write(storage, a, right)
    write(storage, b, left)
  }

  private mutating func insertion(_ storage: Storage, _ position: Int, _ length: Int) {
    guard length > 1 else { return }
    for index in (position + 1)..<(position + length) {
      let value = read(storage, index)
      var cursor = index
      while cursor > position {
        let previous = read(storage, cursor - 1)
        if !engine.compareValues(previous, value, by: (>)) { break }
        write(storage, cursor, previous)
        cursor -= 1
      }
      if cursor != index { write(storage, cursor, value) }
    }
  }

  private mutating func mergeRight(_ storage: Storage, _ position: Int, _ leftLength: Int, _ rightLength: Int, _ distance: Int) {
    var destination = position + leftLength + rightLength + distance - 1
    var right = position + leftLength + rightLength - 1
    var left = position + leftLength - 1
    while left >= position {
      if right < position + leftLength || compare(storage, left, right) > 0 {
        write(storage, destination, read(storage, left))
        left -= 1
      } else {
        write(storage, destination, read(storage, right))
        right -= 1
      }
      destination -= 1
    }
    if right != destination {
      while right >= position + leftLength {
        write(storage, destination, read(storage, right))
        right -= 1
        destination -= 1
      }
    }
  }

  private mutating func mergeLeft(_ storage: Storage, _ position: Int, _ leftLength: Int, _ rightLength: Int, _ distance: Int) {
    var left = position
    var right = position + leftLength
    var destination = position + distance
    let leftEnd = right
    let rightEnd = right + rightLength
    while right < rightEnd {
      if left == leftEnd || compare(storage, left, right) > 0 {
        write(storage, destination, read(storage, right))
        right += 1
      } else {
        write(storage, destination, read(storage, left))
        left += 1
      }
      destination += 1
    }
    if destination != left {
      while left < leftEnd {
        write(storage, destination, read(storage, left))
        left += 1
        destination += 1
      }
    }
  }

  private mutating func mergeDown(_ storage: Storage, _ position: Int, _ prefix: Storage, _ prefixPosition: Int, _ leftLength: Int, _ prefixLength: Int) {
    var left = 0
    var right = 0
    var destination = position - prefixLength
    while right < prefixLength {
      if left == leftLength || compare(storage, position + left, prefix, prefixPosition + right) >= 0 {
        write(storage, destination, read(prefix, prefixPosition + right))
        right += 1
      } else {
        write(storage, destination, read(storage, position + left))
        left += 1
      }
      destination += 1
    }
    if destination != position + left {
      while left < leftLength {
        write(storage, destination, read(storage, position + left))
        left += 1
        destination += 1
      }
    }
  }

  private mutating func smartMerge(_ storage: Storage, _ position: Int, _ priorLength: Int, _ priorFragment: Int, _ blockLength: Int) -> (Int, Int) {
    var left = position
    var right = position + priorLength
    var destination = position - blockLength
    var leftEnd = right
    var rightEnd = right + blockLength
    let opposite = 1 - priorFragment
    while left < leftEnd && right < rightEnd {
      let order = compare(storage, left, right)
      if order < 0 || (order == 0 && opposite == 1) {
        write(storage, destination, read(storage, left))
        left += 1
      } else {
        write(storage, destination, read(storage, right))
        right += 1
      }
      destination += 1
    }
    if left < leftEnd {
      let remaining = leftEnd - left
      while left < leftEnd {
        leftEnd -= 1
        rightEnd -= 1
        write(storage, rightEnd, read(storage, leftEnd))
      }
      return (remaining, priorFragment)
    }
    return (rightEnd - right, opposite)
  }

  private mutating func writeTag(_ index: Int, _ value: Int) {
    tags[index] = value
    engine.writeAux(tagHandle!, at: index, value: value)
  }

  private mutating func readTag(_ index: Int) -> Int {
    engine.markAuxRead(tagHandle!, at: index)
    return tags[index]
  }

  private mutating func mergeBuffers(_ storage: Storage, _ position: Int, _ middleTag: Int, _ blockCount: Int, _ blockLength: Int, _ trailingABlocks: Int, _ tailLength: Int) {
    if blockCount == 0 {
      mergeLeft(storage, position, trailingABlocks * blockLength, tailLength, -blockLength)
      return
    }
    var priorLength = blockLength
    var priorFragment = readTag(0) < middleTag ? 0 : 1
    var process = blockLength
    if blockCount > 1 {
      for tagIndex in 1..<blockCount {
        var rest = process - priorLength
        let nextFragment = readTag(tagIndex) < middleTag ? 0 : 1
        if nextFragment == priorFragment {
          copy(storage, position + rest, storage, position + rest - blockLength, priorLength)
          rest = process
          priorLength = blockLength
        } else {
          (priorLength, priorFragment) = smartMerge(storage, position + rest, priorLength, priorFragment, blockLength)
        }
        process += blockLength
      }
    }
    var rest = process - priorLength
    if tailLength != 0 {
      if priorFragment != 0 {
        copy(storage, position + rest, storage, position + rest - blockLength, priorLength)
        rest = process
        priorLength = blockLength * trailingABlocks
      } else {
        priorLength += blockLength * trailingABlocks
      }
      mergeLeft(storage, position + rest, priorLength, tailLength, -blockLength)
    } else {
      copy(storage, position + rest, storage, position + rest - blockLength, priorLength)
    }
  }

  private mutating func buildBlocks(_ storage: Storage, _ position: Int, _ length: Int, _ blockLength: Int) {
    var position = position
    var pair = 1
    while pair < length {
      let lower = compare(storage, position + pair - 1, position + pair) > 0 ? 1 : 0
      write(storage, position + pair - 3, read(storage, position + pair - 1 + lower))
      write(storage, position + pair - 2, read(storage, position + pair - lower))
      pair += 2
    }
    if length % 2 != 0 { write(storage, position + length - 3, read(storage, position + length - 1)) }
    position -= 2
    var part = 2
    while part < blockLength {
      var left = 0
      let right = length - 2 * part
      while left <= right {
        mergeLeft(storage, position + left, part, part, -part)
        left += 2 * part
      }
      let rest = length - left
      if rest > part {
        mergeLeft(storage, position + left, part, rest - part, -part)
      } else {
        while left < length {
          write(storage, position + left - part, read(storage, position + left))
          left += 1
        }
      }
      position -= part
      part *= 2
    }
    let remainder = length % (2 * blockLength)
    var leftover = length - remainder
    if remainder <= blockLength {
      copy(storage, position + leftover, storage, position + leftover + blockLength, remainder)
    } else {
      mergeRight(storage, position + leftover, blockLength, remainder - blockLength, blockLength)
    }
    while leftover > 0 {
      leftover -= 2 * blockLength
      mergeRight(storage, position + leftover, blockLength, blockLength, blockLength)
    }
  }

  private mutating func combineBlocks(_ storage: Storage, _ position: Int, _ length: Int, _ runLength: Int, _ blockLength: Int) {
    let combineCount = length / (2 * runLength)
    var remainder = length % (2 * runLength)
    var length = length
    if remainder <= runLength {
      length -= remainder
      remainder = 0
    }
    for group in 0...combineCount {
      if group == combineCount && remainder == 0 { break }
      let groupPosition = position + group * 2 * runLength
      let count = (group == combineCount ? remainder : 2 * runLength) / blockLength
      let tagEnd = count + (group == combineCount ? 1 : 0)
      for tag in 0...tagEnd { writeTag(tag, tag) }
      let middle = runLength / blockLength
      if count > 1 {
        for tagIndex in 1..<count {
          var selected = tagIndex - 1
          for candidate in tagIndex..<count {
            let order = compare(storage, groupPosition + selected * blockLength, groupPosition + candidate * blockLength)
            if order > 0 || (order == 0 && readTag(selected) > readTag(candidate)) { selected = candidate }
          }
          if selected != tagIndex - 1 {
            for offset in 0..<blockLength {
              swap(storage, groupPosition + (tagIndex - 1) * blockLength + offset, groupPosition + selected * blockLength + offset)
            }
            let firstTag = readTag(tagIndex - 1)
            let selectedTag = readTag(selected)
            writeTag(tagIndex - 1, selectedTag)
            writeTag(selected, firstTag)
          }
        }
      }
      var trailingA = 0
      let tail = group == combineCount ? remainder % blockLength : 0
      if tail != 0 {
        while trailingA < count && compare(storage, groupPosition + count * blockLength, groupPosition + (count - trailingA - 1) * blockLength) < 0 {
          trailingA += 1
        }
      }
      mergeBuffers(storage, groupPosition, middle, count - trailingA, blockLength, trailingA, tail)
    }
    if length > 0 {
      for index in stride(from: length - 1, through: 0, by: -1) {
        write(storage, position + index, read(storage, position + index - blockLength))
      }
    }
  }

  private mutating func commonSort(_ storage: Storage, _ position: Int, _ length: Int, _ prefix: Storage, _ prefixPosition: Int) {
    if length <= 16 {
      insertion(storage, position, length)
      return
    }
    var blockLength = 1
    while blockLength * blockLength < length { blockLength *= 2 }
    copy(storage, position, prefix, prefixPosition, blockLength)
    commonSort(prefix, prefixPosition, blockLength, storage, position)
    buildBlocks(storage, position + blockLength, length - blockLength, blockLength)
    var runLength = blockLength
    while true {
      runLength *= 2
      if length <= runLength { break }
      combineBlocks(storage, position + blockLength, length - blockLength, runLength, blockLength)
    }
    mergeDown(storage, position + blockLength, prefix, prefixPosition, length - blockLength, blockLength)
  }

  mutating func sort() {
    let length = engine.count
    var bufferLength = 1
    while bufferLength * bufferLength < length { bufferLength *= 2 }
    buffer = Array(repeating: 0, count: bufferLength)
    tags = Array(repeating: 0, count: (length - 1) / bufferLength + 2)
    bufferHandle = engine.createAuxArray(length: buffer.count)
    tagHandle = engine.createAuxArray(length: tags.count)
    commonSort(.main, 0, length, .buffer, 0)
    engine.deleteAuxArray(tagHandle!)
    engine.deleteAuxArray(bufferHandle!)
  }
}
