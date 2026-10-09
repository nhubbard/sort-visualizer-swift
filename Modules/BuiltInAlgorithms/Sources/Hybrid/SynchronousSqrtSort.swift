import AlgorithmKit
import SortEngineKit

// MIT License
// Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
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

/// A stable port of aphitorite's synchronous square-root block merge sort. Forward merges build
/// sorted blocks in vacated prefix space, then backward merges combine block runs. Selection tags
/// retain each block's source half so equal keys keep their original order through the final
/// backward merge. The saved prefix is merged back after the block passes.
public struct SynchronousSqrtSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "synchronoussqrtsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Synchronous Sqrt Sort",
    category: .hybrid,
    sizeRange: 16...1780,
    growthModel: OperationGrowthModel(
      anchorSize: 1780, coefficients: [196940, 142.952, 0.0111721],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.51645, 1.15843], rSquared: 0.995007),
    implementationComplexity: 73,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(√n)",
    iconName: "square.grid.3x3.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    let worker = SynchronousSqrtRecorder(engine: engine)
    worker.sort()
    engine = worker.engine
  }
}

private final class SynchronousSqrtRecorder: BlockMergeSortingTemplate {
  private var prefix: [Int] = []
  private var tags: [Int] = []
  private var prefixHandle: AuxHandle?
  private var tagHandle: AuxHandle?

  private func readPrefix(_ index: Int) -> Int {
    engine.markAuxRead(prefixHandle!, at: index)
    return prefix[index]
  }

  private func writePrefix(_ index: Int, _ value: Int) {
    prefix[index] = value
    engine.writeAux(prefixHandle!, at: index, value: value)
  }

  private func readTag(_ index: Int) -> Int {
    engine.markAuxRead(tagHandle!, at: index)
    return tags[index]
  }

  private func writeTag(_ index: Int, _ value: Int) {
    tags[index] = value
    engine.writeAux(tagHandle!, at: index, value: value)
  }

  private func swapTags(_ first: Int, _ second: Int) {
    let value = readTag(first)
    writeTag(first, readTag(second))
    writeTag(second, value)
  }

  private func smartMergeBackward(_ start: Int, _ middle: Int, _ end: Int, _ destinationEnd: Int, _ reversed: Bool) -> Int {
    var left = middle - 1
    var right = end - 1
    var output = destinationEnd
    while left >= start && right >= middle {
      let takeLeft = reversed
        ? engine.teachingCompare(
          left, right, by: (>=),
          stageID: "SynchronousSqrtSort.merge.chooseReversed",
          whenTrue: "The left item is at least the right, so the reversed merge takes it next.",
          whenFalse: "The right item is larger, so the reversed merge takes it next."
        )
        : engine.teachingCompare(
          left, right, by: (>),
          stageID: "SynchronousSqrtSort.merge.choose",
          whenTrue: "The left item is larger, so the backward merge takes it next.",
          whenFalse: "The right item is at least as large, so the backward merge takes it next."
        )
      output -= 1
      if takeLeft {
        engine.setValue(output, engine.readValue(at: left))
        left -= 1
      } else {
        engine.setValue(output, engine.readValue(at: right))
        right -= 1
      }
    }
    return left + 1
  }

  private func blockSelection(_ start: Int, _ end: Int, _ blockLength: Int, _ tagStart: Int, _ tagCount: Int) {
    let available = min(tagCount + 1, tags.count - tagStart)
    if available > 0 {
      for index in 0..<available {
        writeTag(tagStart + index, index + (index <= tagCount / 2 ? 0 : tags.count))
      }
    }
    var vacant = start
    var current = start
    while current < end - blockLength {
      var minimum = vacant == current ? current + blockLength : current
      var candidate = minimum + blockLength
      while candidate < end {
        if candidate != vacant {
          let order = engine.compare(candidate, minimum, by: (<))
          let equal = !order && engine.compare(candidate, minimum, by: (==))
          if order || (equal && readTag(tagStart + (candidate - start) / blockLength) < readTag(tagStart + (minimum - start) / blockLength)) {
            minimum = candidate
          }
        }
        candidate += blockLength
      }
      if minimum > current {
        if vacant == current {
          for offset in 0..<blockLength {
            engine.setValue(current + offset, engine.readValue(at: minimum + offset))
          }
          writeTag(tagStart + (current - start) / blockLength, readTag(tagStart + (minimum - start) / blockLength))
          vacant = minimum
        } else {
          multiSwap(current, minimum, blockLength)
          swapTags(tagStart + (current - start) / blockLength, tagStart + (minimum - start) / blockLength)
        }
      }
      current += blockLength
    }
  }

  private func mergeBlocksBackward(_ start: Int, _ end: Int, _ firstTag: Int, _ pastLastTag: Int, _ blockLength: Int) {
    var tagIndex = pastLastTag - 1
    var frontier = end
    var blockStart = frontier - blockLength
    var reversed = readTag(tagIndex) < tags.count
    while true {
      repeat {
        tagIndex -= 1
        blockStart -= blockLength
      } while tagIndex >= firstTag && ((readTag(tagIndex) < tags.count) == reversed)
      if tagIndex < firstTag {
        shiftBackwardExternal(start, frontier, frontier + blockLength)
        break
      }
      frontier = smartMergeBackward(blockStart, blockStart + blockLength, frontier, frontier + blockLength, reversed)
      reversed.toggle()
    }
  }

  func sort() {
    let length = engine.count
    if length <= 16 {
      binaryInsertion(0, length)
      return
    }
    var blockLength = 1
    while blockLength * blockLength < length { blockLength *= 2 }
    let remainder = length % blockLength
    var start = blockLength + remainder
    var end = length
    let workLength = end - start
    var runLength = 1
    prefix = Array(repeating: 0, count: start)
    tags = Array(repeating: 0, count: (length - 1) / blockLength + 1)
    prefixHandle = engine.createAuxArray(length: prefix.count)
    tagHandle = engine.createAuxArray(length: tags.count)
    binaryInsertion(0, start)
    for index in 0..<start { writePrefix(index, engine.readValue(at: index)) }

    while runLength < blockLength {
      let distance = max(2, runLength)
      var index = start
      while index + 2 * runLength < end {
        mergeForwardExternal(index, index + runLength, index + 2 * runLength, index - distance)
        index += 2 * runLength
      }
      if index + runLength < end {
        mergeForwardExternal(index, index + runLength, end, index - distance)
      } else {
        shiftForwardExternal(index - distance, index, end)
      }
      start -= distance
      end -= distance
      runLength *= 2
    }

    var fragment = workLength % (2 * runLength)
    var index = end - fragment
    if index + runLength < end {
      mergeBackwardExternal(index, index + runLength, end, end + runLength)
    } else {
      shiftBackwardExternal(index, end, end + runLength)
    }
    index -= 2 * runLength
    while index >= start {
      mergeBackwardExternal(index, index + runLength, index + 2 * runLength, index + 3 * runLength)
      index -= 2 * runLength
    }
    start += runLength
    end += runLength
    runLength *= 2

    var tagCount = 4
    while runLength < workLength {
      index = start
      var tagIndex = 0
      while index + 2 * runLength < end {
        blockSelection(index - blockLength, index + 2 * runLength, blockLength, tagIndex, tagCount)
        index += 2 * runLength
        tagIndex += tagCount
      }
      let hasFragment = index + runLength < end
      fragment = (end - index) / blockLength
      if hasFragment {
        blockSelection(index - blockLength, end, blockLength, tagIndex, tagCount)
      }
      start -= blockLength
      end -= blockLength
      index -= blockLength
      if hasFragment {
        mergeBlocksBackward(index, end, tagIndex, tagIndex + fragment, blockLength)
      }
      index -= 2 * runLength
      tagIndex -= tagCount
      while index >= start {
        mergeBlocksBackward(index, index + 2 * runLength, tagIndex, tagIndex + tagCount, blockLength)
        index -= 2 * runLength
        tagIndex -= tagCount
      }
      start += blockLength
      end += blockLength
      runLength *= 2
      tagCount *= 2
    }

    var left = 0
    var right = start
    var output = 0
    while left < start && right < end {
      let prefixValue = readPrefix(left)
      if engine.compareValue(right, against: prefixValue, by: (>=)) {
        engine.setValue(output, prefixValue)
        left += 1
      } else {
        engine.setValue(output, engine.readValue(at: right))
        right += 1
      }
      output += 1
    }
    while left < start {
      engine.setValue(output, readPrefix(left))
      left += 1
      output += 1
    }
    engine.deleteAuxArray(tagHandle!)
    engine.deleteAuxArray(prefixHandle!)
  }
}
