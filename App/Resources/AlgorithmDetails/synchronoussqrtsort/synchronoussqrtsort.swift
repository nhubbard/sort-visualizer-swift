// MIT License
// Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
// Copyright (c) 2020-2021 aphitorite
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

final class SynchronousSqrtExample {
  var values: [Int]
  init(_ input: [Int]) { values = input }

  func shiftForwardExternal(_ destination: Int, _ source: Int, _ end: Int) {
    var output = destination
    var input = source
    while input < end {
      values[output] = values[input]
      output += 1
      input += 1
    }
  }

  func shiftBackwardExternal(_ start: Int, _ sourceEnd: Int, _ destinationEnd: Int) {
    var input = sourceEnd
    var output = destinationEnd
    while input > start {
      input -= 1
      output -= 1
      values[output] = values[input]
    }
  }

  func rightBinarySearch(_ start: Int, _ end: Int, _ value: Int) -> Int {
    var lower = start
    var upper = end
    while lower < upper {
      let middle = lower + (upper - lower) / 2
      if (values[middle] <= value) {
        lower = middle + 1
      } else {
        upper = middle
      }
    }
    return lower
  }

  func binaryInsertion(_ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for index in (start + 1)..<end {
      let value = values[index]
      let position = rightBinarySearch(start, index, value)
      var cursor = index
      while cursor > position {
        values[cursor] = values[cursor - 1]
        cursor -= 1
      }
      if position != index { values[position] = value }
    }
  }

  func multiSwap(_ first: Int, _ second: Int, _ length: Int) {
    guard length > 0 else { return }
    for offset in 0..<length { values.swapAt(first + offset, second + offset) }
  }

  func mergeForwardExternal(_ start: Int, _ middle: Int, _ end: Int, _ destination: Int) {
    var left = start
    var right = middle
    var output = destination
    while left < middle && right < end {
      if (values[left] <= values[right]) {
        values[output] = values[left]
        left += 1
      } else {
        values[output] = values[right]
        right += 1
      }
      output += 1
    }
    if left > output { shiftForwardExternal(output, left, middle) }
    shiftForwardExternal(output, right, end)
  }

  func mergeBackwardExternal(_ start: Int, _ middle: Int, _ end: Int, _ destinationEnd: Int) {
    var left = middle - 1
    var right = end - 1
    var output = destinationEnd
    while right >= middle && left >= start {
      output -= 1
      if (values[right] >= values[left]) {
        values[output] = values[right]
        right -= 1
      } else {
        values[output] = values[left]
        left -= 1
      }
    }
    if output > right { shiftBackwardExternal(middle, right + 1, output) }
    shiftBackwardExternal(start, left + 1, output)
  }

  private var prefix: [Int] = []
  private var tags: [Int] = []

  private func readPrefix(_ index: Int) -> Int {
    return prefix[index]
  }

  private func writePrefix(_ index: Int, _ value: Int) {
    prefix[index] = value
  }

  private func readTag(_ index: Int) -> Int {
    return tags[index]
  }

  private func writeTag(_ index: Int, _ value: Int) {
    tags[index] = value
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
      let takeLeft = reversed ? (values[left] >= values[right]) : (values[left] > values[right])
      output -= 1
      if takeLeft {
        values[output] = values[left]
        left -= 1
      } else {
        values[output] = values[right]
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
          let order = (values[candidate] < values[minimum])
          let equal = !order && (values[candidate] == values[minimum])
          if order || (equal && readTag(tagStart + (candidate - start) / blockLength) < readTag(tagStart + (minimum - start) / blockLength)) {
            minimum = candidate
          }
        }
        candidate += blockLength
      }
      if minimum > current {
        if vacant == current {
          for offset in 0..<blockLength {
            values[current + offset] = values[minimum + offset]
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
    let length = values.count
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
    binaryInsertion(0, start)
    for index in 0..<start { writePrefix(index, values[index]) }

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
      if (values[right] >= prefixValue) {
        values[output] = prefixValue
        left += 1
      } else {
        values[output] = values[right]
        right += 1
      }
      output += 1
    }
    while left < start {
      values[output] = readPrefix(left)
      left += 1
      output += 1
    }
  }
}

var example = SynchronousSqrtExample([0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
                                      68, 83, 32, 56])
example.sort()
print(example.values)
