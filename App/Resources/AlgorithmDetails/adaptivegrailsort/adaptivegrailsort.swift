// MIT License
// Copyright (c) 2013 Andrey Astrelin
// Copyright (c) 2020 The Holy Grail Sort Project
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

final class AdaptiveGrailExample {
  enum Fragment { case left, right }
  var values: [Int]
  private var minRun = 16

  init(_ input: [Int]) { values = input }

  private func read(_ index: Int) -> Int { values[index] }
  private func write(_ index: Int, _ value: Int) { values[index] = value }
  private func swap(_ first: Int, _ second: Int) { values.swapAt(first, second) }

  private func compare(_ first: Int, _ second: Int) -> Int {
    if values[first] < values[second] { return -1 }
    if values[first] > values[second] { return 1 }
    return 0
  }

  private func compareValue(_ index: Int, _ value: Int) -> Int {
    if values[index] < value { return -1 }
    if values[index] > value { return 1 }
    return 0
  }

  private func reverse(_ start: Int, _ end: Int) {
    var left = start
    var right = end - 1
    while left < right { values.swapAt(left, right); left += 1; right -= 1 }
  }

  private func multiSwap(_ first: Int, _ second: Int, _ count: Int) {
    guard count > 0 else { return }
    for offset in 0..<count { swap(first + offset, second + offset) }
  }

  private func multiTriSwap(_ first: Int, _ second: Int, _ third: Int, _ count: Int) {
    guard count > 0 else { return }
    for offset in 0..<count {
      let value = read(first + offset)
      write(first + offset, read(second + offset))
      write(second + offset, read(third + offset))
      write(third + offset, value)
    }
  }

  private func insertTo(_ source: Int, _ destination: Int) {
    let value = read(source)
    var cursor = source
    while cursor > destination {
      write(cursor, read(cursor - 1))
      cursor -= 1
    }
    write(destination, value)
  }

  private func insertToBackward(_ source: Int, _ destination: Int) {
    let value = read(source)
    var cursor = source
    while cursor < destination {
      write(cursor, read(cursor + 1))
      cursor += 1
    }
    write(cursor, value)
  }

  private func shift(_ destination: Int, _ source: Int, _ end: Int) {
    guard source < end else { return }
    for offset in 0..<(end - source) { swap(destination + offset, source + offset) }
  }

  private func rotate(_ startIn: Int, _ middleIn: Int, _ endIn: Int) {
    var start = startIn
    var middle = middleIn
    var end = endIn
    var left = middle - start
    var right = end - middle
    while left > 1 && right > 1 {
      if right < left {
        multiSwap(middle - right, middle, right)
        end -= right
        middle -= right
        left -= right
      } else {
        multiSwap(start, middle, left)
        start += left
        middle += left
        right -= left
      }
    }
    if right == 1 {
      insertTo(middle, start)
    } else if left == 1 {
      insertToBackward(start, end - 1)
    }
  }

  private func leftBinarySearch(_ start: Int, _ end: Int, _ value: Int) -> Int {
    var lower = start
    var upper = end
    while lower < upper {
      let middle = lower + (upper - lower) / 2
      if values[middle] >= value { upper = middle }
      else { lower = middle + 1 }
    }
    return lower
  }

  private func rightBinarySearch(_ start: Int, _ end: Int, _ value: Int) -> Int {
    var lower = start
    var upper = end
    while lower < upper {
      let middle = lower + (upper - lower) / 2
      if values[middle] > value { upper = middle }
      else { lower = middle + 1 }
    }
    return lower
  }

  private func buildUniqueRun(_ start: Int, _ limit: Int) -> Int {
    var count = 1
    var index = start + 1
    let order = compare(index - 1, index)
    if order < 0 {
      index += 1
      count += 1
      while count < limit && compare(index - 1, index) < 0 { index += 1; count += 1 }
    } else if order > 0 {
      index += 1
      count += 1
      while count < limit && compare(index - 1, index) > 0 { index += 1; count += 1 }
      reverse(start, index)
    }
    return count
  }

  private func buildUniqueRunBackward(_ end: Int, _ limit: Int) -> Int {
    var count = 1
    var index = end - 1
    let order = compare(index - 1, index)
    if order < 0 {
      index -= 1
      count += 1
      while count < limit && compare(index - 1, index) < 0 { index -= 1; count += 1 }
    } else if order > 0 {
      index -= 1
      count += 1
      while count < limit && compare(index - 1, index) > 0 { index -= 1; count += 1 }
      reverse(index, end)
    }
    return count
  }

  private func findKeys(_ start: Int, _ end: Int, _ initial: Int, _ needed: Int) -> Int {
    var count = initial
    var keyStart = start
    var keyEnd = start + count
    var index = keyEnd
    while index < end && count < needed {
      let candidate = read(index)
      var location = leftBinarySearch(keyStart, keyEnd, candidate)
      if location == keyEnd || compareValue(location, candidate) != 0 {
        rotate(keyStart, keyEnd, index)
        let distance = index - keyEnd
        location += distance
        keyStart += distance
        keyEnd += distance
        insertTo(keyEnd, location)
        count += 1
        keyEnd += 1
      }
      index += 1
    }
    rotate(start, keyStart, keyEnd)
    return count
  }

  private func findKeysBackward(_ start: Int, _ end: Int, _ initial: Int, _ needed: Int) -> Int {
    var count = initial
    var keyStart = end - count
    var keyEnd = end
    var index = keyStart - 1
    while index >= start && count < needed {
      let candidate = read(index)
      var location = leftBinarySearch(keyStart, keyEnd, candidate)
      if location == keyEnd || compareValue(location, candidate) != 0 {
        rotate(index + 1, keyStart, keyEnd)
        let distance = keyStart - (index + 1)
        location -= distance
        keyEnd -= distance
        keyStart -= distance + 1
        count += 1
        insertToBackward(index, location - 1)
      }
      index -= 1
    }
    rotate(keyStart, keyEnd, end)
    return count
  }

  private func buildRuns(_ start: Int, _ end: Int) {
    var index = start + 1
    var runStart = start
    while index < end {
      if compare(index - 1, index) > 0 {
        index += 1
        while index < end && compare(index - 1, index) > 0 { index += 1 }
        reverse(runStart, index)
      } else {
        index += 1
        while index < end && compare(index - 1, index) <= 0 { index += 1 }
      }
      if index < end { runStart = index - (index - runStart - 1) % minRun - 1 }
      while index - runStart < minRun && index < end {
        insertTo(index, rightBinarySearch(runStart, index, read(index)))
        index += 1
      }
      runStart = index
      index += 1
    }
  }

  private func binaryInsertion(_ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for index in (start + 1)..<end { insertTo(index, rightBinarySearch(start, index, read(index))) }
  }

  private func mergeWithBufferRest(_ start: Int, _ middle: Int, _ end: Int, _ buffer: Int, _ length: Int) {
    var left = 0
    var right = middle
    var output = start
    while left < length && right < end {
      if compare(buffer + left, right) <= 0 { swap(output, buffer + left); left += 1 }
      else { swap(output, right); right += 1 }
      output += 1
    }
    while left < length { swap(output, buffer + left); output += 1; left += 1 }
  }

  private func mergeWithBuffer(_ start: Int, _ middle: Int, _ end: Int, _ buffer: Int) {
    let length = middle - start
    multiSwap(buffer, start, length)
    mergeWithBufferRest(start, middle, end, buffer, length)
  }

  private func mergeWithBufferBackward(_ start: Int, _ middle: Int, _ end: Int, _ buffer: Int) {
    let length = end - middle
    multiSwap(middle, buffer, length)
    var left = length - 1
    var right = middle - 1
    var output = end - 1
    while left >= 0 && right >= start {
      if compare(buffer + left, right) >= 0 { swap(output, buffer + left); left -= 1 }
      else { swap(output, right); right -= 1 }
      output -= 1
    }
    while left >= 0 { swap(output, buffer + left); output -= 1; left -= 1 }
  }

  private func inPlaceMerge(_ start: Int, _ middle: Int, _ end: Int) {
    var left = start
    var right = middle
    while left < right && right < end {
      if compare(left, right) > 0 {
        let next = leftBinarySearch(right + 1, end, read(left))
        rotate(left, right, next)
        left += next - right
        right = next
      } else { left += 1 }
    }
  }

  private func inPlaceMergeBackward(_ start: Int, _ middle: Int, _ end: Int) {
    var left = middle - 1
    var right = end - 1
    while right > left && left >= start {
      if compare(left, right) > 0 {
        let next = rightBinarySearch(start, left, read(right))
        rotate(next, left + 1, right + 1)
        right -= (left + 1) - next
        left = next - 1
      } else { right -= 1 }
    }
  }

  private func mergeWithoutBuffer(_ start: Int, _ middle: Int, _ end: Int) {
    if middle - start > end - middle { inPlaceMergeBackward(start, middle, end) }
    else { inPlaceMerge(start, middle, end) }
  }

  private func checkSorted(_ middle: Int) -> Bool { compare(middle - 1, middle) > 0 }

  private func checkReverseBounds(_ start: Int, _ middle: Int, _ end: Int) -> Bool {
    if compare(start, end - 1) > 0 {
      rotate(start, middle, end)
      return false
    }
    return true
  }

  private func checkBounds(_ start: Int, _ middle: Int, _ end: Int) -> Bool {
    checkSorted(middle) && checkReverseBounds(start, middle, end)
  }

  private func subarray(_ tag: Int, _ middleKey: Int) -> Fragment {
    compare(tag, middleKey) < 0 ? .left : .right
  }

  private func blockSelectSort(_ position: Int, _ tags: Int, _ offset: Int, _ distance: Int, _ leftCount: Int, _ blockCount: Int, _ blockLength: Int) -> Int {
    var middleKey = leftCount
    var index = 0
    var limit = leftCount + 1
    while index < limit - 1 {
      var minimum = index
      var candidate = max(leftCount - offset, index + 1)
      while candidate < limit {
        let order = compare(position + distance + candidate * blockLength, position + distance + minimum * blockLength)
        if order < 0 || (order == 0 && compare(tags + candidate, tags + minimum) < 0) {
          minimum = candidate
        }
        candidate += 1
      }
      if minimum != index {
        multiSwap(position + index * blockLength, position + minimum * blockLength, blockLength)
        swap(tags + index, tags + minimum)
        if limit < blockCount && minimum == limit - 1 { limit += 1 }
      }
      if minimum == middleKey { middleKey = index }
      index += 1
    }
    return tags + middleKey
  }

  private func sortKeys(_ end: Int, _ buffer: Int, _ middleKey: Int) {
    swap(buffer, middleKey)
    var left = middleKey
    var index = left + 1
    var right = buffer + 1
    while index < end {
      if compare(index, buffer) < 0 { swap(left, index); left += 1 }
      else { swap(right, index); right += 1 }
      index += 1
    }
    multiSwap(left, buffer, end - left)
  }

  private func sortKeysWithoutBuffer(_ end: Int, _ middleKey: Int) {
    var left = middleKey
    var index = left + 1
    while index < end {
      if compare(index, left) < 0 { insertTo(index, left); left += 1 }
      index += 1
    }
  }

  private func mergeBlocks(_ start: Int, _ middle: Int, _ end: Int, _ destination: Int, _ reverseEqual: Bool) -> Int {
    var left = start
    var right = middle
    var output = destination
    while left < middle && right < end {
      let order = compare(left, right)
      if order < 0 || (order == 0 && !reverseEqual) {
        swap(output, left)
        left += 1
      } else {
        swap(output, right)
        right += 1
      }
      output += 1
    }
    if left > output {
      while left < middle { swap(output, left); output += 1; left += 1 }
    }
    return right
  }

  private func blockMerge(_ start: Int, _ middle: Int, _ end: Int, _ tags: Int, _ buffer: Int, _ blockLength: Int) {
    let lastFull = end - (end - middle - 1) % blockLength - 1
    var left = start + blockLength
    var group = start
    var key = tags - 1
    let leftCount = (middle - left) / blockLength
    let blockCount = (lastFull - left) / blockLength
    var leftBlocks = -1
    var rightBlocks = leftCount - 1
    multiTriSwap(buffer, middle - blockLength, start, blockLength)
    insertToBackward(tags, tags + leftCount - 1)
    let middleKey = blockSelectSort(left, tags, 1, blockLength - 1, leftCount, blockCount, blockLength)
    var fragment = Fragment.left
    while leftBlocks < leftCount && rightBlocks < blockCount {
      if fragment == .left {
        repeat {
          group += blockLength
          leftBlocks += 1
          key += 1
        } while leftBlocks < leftCount && subarray(key, middleKey) == .left
        if leftBlocks == leftCount {
          left = mergeBlocks(left, group, end, left - blockLength, false)
          mergeWithBufferRest(left - blockLength, left, end, buffer, blockLength)
        } else {
          left = mergeBlocks(left, group, group + blockLength - 1, left - blockLength, false)
        }
        fragment = .right
      } else {
        repeat {
          group += blockLength
          rightBlocks += 1
          key += 1
        } while rightBlocks < blockCount && subarray(key, middleKey) == .right
        if rightBlocks == blockCount {
          shift(left - blockLength, left, end)
          multiSwap(buffer, end - blockLength, blockLength)
        } else {
          left = mergeBlocks(left, group, group + blockLength - 1, left - blockLength, true)
        }
        fragment = .left
      }
    }
    sortKeys(tags + blockCount, buffer, middleKey)
  }

  private func blockMergeWithoutBuffer(_ start: Int, _ middle: Int, _ end: Int, _ tags: Int, _ blockLength: Int) {
    let firstFull = start + (middle - start) % blockLength
    let lastFull = end - (end - middle) % blockLength
    var left = start
    var group = firstFull
    var key = tags
    let leftCount = (middle - group) / blockLength + 1
    let blockCount = (lastFull - group) / blockLength + 1
    var leftBlocks = 0
    var rightBlocks = leftCount
    let middleKey = blockSelectSort(group, tags, 0, 0, leftCount - 1, blockCount - 1, blockLength)
    var fragment = Fragment.left
    while leftBlocks < leftCount && rightBlocks < blockCount {
      let next = subarray(key, middleKey)
      key += 1
      if next == fragment {
        if fragment == .left { leftBlocks += 1 } else { rightBlocks += 1 }
        left = group
      } else {
        var middle2 = group
        let end2 = group + blockLength
        if fragment == .left {
          while left < middle2 && middle2 < end2 {
            if compare(left, middle2) > 0 {
              let nextPosition = leftBinarySearch(middle2 + 1, end2, read(left))
              rotate(left, middle2, nextPosition)
              left += nextPosition - middle2
              middle2 = nextPosition
            } else { left += 1 }
          }
        } else {
          while left < middle2 && middle2 < end2 {
            if compare(left, middle2) >= 0 {
              let nextPosition = rightBinarySearch(middle2 + 1, end2, read(left))
              rotate(left, middle2, nextPosition)
              left += nextPosition - middle2
              middle2 = nextPosition
            } else { left += 1 }
          }
        }
        if left < middle2 {
          if next == .left { leftBlocks += 1 } else { rightBlocks += 1 }
        } else {
          if fragment == .left { leftBlocks += 1 } else { rightBlocks += 1 }
          fragment = next
        }
      }
      group += blockLength
    }
    if leftBlocks < leftCount { inPlaceMergeBackward(start, lastFull, end) }
    sortKeysWithoutBuffer(tags + blockCount - 1, middleKey)
  }

  private func smartMerge(_ start: Int, _ middle: Int, _ end: Int, _ buffer: Int) {
    if checkBounds(start, middle, end) {
      let trimmed = rightBinarySearch(start, middle - 1, read(middle))
      mergeWithBuffer(trimmed, middle, end, buffer)
    }
  }

  private func smartMergeBackward(_ start: Int, _ middle: Int, _ end: Int, _ buffer: Int) {
    if checkBounds(start, middle, end) {
      let trimmed = leftBinarySearch(middle + 1, end, read(middle - 1))
      mergeWithBufferBackward(start, middle, trimmed, buffer)
    }
  }

  private func smartBlockMerge(_ start: Int, _ middle: Int, _ end: Int, _ tags: Int, _ buffer: Int, _ blockLength: Int) {
    if checkBounds(start, middle, end) {
      var trimmedStart = rightBinarySearch(start, middle - 1, read(middle))
      let trimmedEnd = leftBinarySearch(middle + 1, end, read(middle - 1))
      if checkReverseBounds(trimmedStart, middle, trimmedEnd) {
        if middle - trimmedStart <= blockLength || trimmedEnd - middle <= blockLength {
          if trimmedEnd - middle < middle - trimmedStart {
            mergeWithBufferBackward(trimmedStart, middle, trimmedEnd, buffer)
          } else {
            mergeWithBuffer(trimmedStart, middle, trimmedEnd, buffer)
          }
        } else {
          trimmedStart -= (trimmedStart - start) % blockLength
          blockMerge(trimmedStart, middle, trimmedEnd, tags, buffer, blockLength)
        }
      }
    }
  }

  private func smartBlockMergeWithoutBuffer(_ start: Int, _ middle: Int, _ end: Int, _ tags: Int, _ blockLength: Int) {
    if checkBounds(start, middle, end) {
      let trimmedStart = rightBinarySearch(start, middle - 1, read(middle))
      if middle - trimmedStart <= blockLength { inPlaceMerge(trimmedStart, middle, end) }
      else { blockMergeWithoutBuffer(trimmedStart, middle, end, tags, blockLength) }
    }
  }

  private func smartInPlaceMerge(_ start: Int, _ middle: Int, _ end: Int) {
    if checkSorted(middle) { inPlaceMergeBackward(start, middle, end) }
  }

  private func redistributeBuffer(_ startIn: Int, _ middleIn: Int, _ end: Int) {
    var start = startIn
    var middle = middleIn
    var right = leftBinarySearch(middle, end, read(start))
    rotate(start, middle, right)
    var distance = right - middle
    start += distance
    middle += distance
    var leftMiddle = start + (middle - start) / 2
    right = leftBinarySearch(middle, end, read(leftMiddle))
    rotate(leftMiddle, middle, right)
    distance = right - middle
    leftMiddle += distance
    middle += distance
    mergeWithoutBuffer(start, leftMiddle - distance, leftMiddle)
    mergeWithoutBuffer(leftMiddle, middle, end)
  }

  private func redistributeBufferBackward(_ start: Int, _ middleIn: Int, _ endIn: Int) {
    var middle = middleIn
    var end = endIn
    var right = rightBinarySearch(start, middle, read(end - 1))
    rotate(right, middle, end)
    var distance = middle - right
    end -= distance
    middle -= distance
    var rightMiddle = middle + (end - middle) / 2
    right = rightBinarySearch(start, middle, read(rightMiddle - 1))
    rotate(right, middle, rightMiddle)
    distance = middle - right
    rightMiddle -= distance
    middle -= distance
    mergeWithoutBuffer(rightMiddle, rightMiddle + distance, end)
    mergeWithoutBuffer(start, middle, rightMiddle)
  }

  private func inPlaceMergeSort(_ start: Int, _ end: Int) {
    buildRuns(start, end)
    var run = minRun
    while run < end - start {
      var index = start
      while index + 2 * run <= end {
        smartInPlaceMerge(index, index + run, index + 2 * run)
        index += 2 * run
      }
      if index + run < end { smartInPlaceMerge(index, index + run, end) }
      run *= 2
    }
  }

  private func adaptiveSortWithoutBuffer(_ startIn: Int, _ endIn: Int, _ keys: Int, _ ideal: Int, _ backwardBuffer: Bool) {
    var start = startIn
    var end = endIn
    let length = end - start
    var blockLength = min(keys, minRun)
    while 2 * blockLength <= keys { blockLength *= 2 }
    var tagLength = keys - blockLength
    var runLength = minRun
    var tags: Int
    var buffer: Int
    var dataStart: Int
    var dataEnd: Int
    if backwardBuffer {
      buffer = end - blockLength
      dataStart = start
      dataEnd = buffer - tagLength
      tags = dataEnd
    } else {
      buffer = start + tagLength
      dataStart = buffer + blockLength
      dataEnd = end
      tags = start
    }
    buildRuns(dataStart, dataEnd)
    while runLength <= blockLength && runLength < length {
      var index = dataStart
      while index + 2 * runLength <= dataEnd {
        smartMerge(index, index + runLength, index + 2 * runLength, buffer)
        index += 2 * runLength
      }
      if index + runLength < dataEnd { smartMergeBackward(index, index + runLength, dataEnd, buffer) }
      runLength *= 2
    }
    if blockLength / 2 >= minRun && blockLength / 2 >= (keys + 1) / 2 {
      binaryInsertion(buffer, buffer + blockLength)
      blockLength /= 2
      tagLength = keys - blockLength
      buffer += blockLength
    }
    while tagLength >= 2 * runLength / blockLength - 1 && runLength < length {
      var index = dataStart
      while index + 2 * runLength <= dataEnd {
        smartBlockMerge(index, index + runLength, index + 2 * runLength, tags, buffer, blockLength)
        index += 2 * runLength
      }
      if index + runLength < dataEnd {
        if dataEnd - (index + runLength) > blockLength {
          smartBlockMerge(index, index + runLength, dataEnd, tags, buffer, blockLength)
        } else {
          smartMergeBackward(index, index + runLength, dataEnd, buffer)
        }
      }
      runLength *= 2
    }
    binaryInsertion(buffer, buffer + blockLength)
    tagLength = keys - keys % 2
    while runLength < length {
      blockLength = 2 * runLength / tagLength
      var index = dataStart
      while index + 2 * runLength <= dataEnd {
        smartBlockMergeWithoutBuffer(index, index + runLength, index + 2 * runLength, tags, blockLength)
        index += 2 * runLength
      }
      if index + runLength < dataEnd {
        if dataEnd - (index + runLength) > blockLength {
          smartBlockMergeWithoutBuffer(index, index + runLength, dataEnd, tags, blockLength)
        } else {
          smartInPlaceMerge(index, index + runLength, dataEnd)
        }
      }
      runLength *= 2
    }
    if backwardBuffer {
      start = rightBinarySearch(start, dataEnd, read(dataEnd))
      if keys >= ideal / 2 { redistributeBufferBackward(start, dataEnd, end) }
      else { mergeWithoutBuffer(start, dataEnd, end) }
    } else {
      end = leftBinarySearch(dataStart, end, read(dataStart - 1))
      if keys >= ideal / 2 { redistributeBuffer(start, dataStart, end) }
      else { mergeWithoutBuffer(start, dataStart, end) }
    }
  }

  func sort(_ startIn: Int, _ endIn: Int) {
    var start = startIn
    var end = endIn
    let length = end - start
    if length < 31 {
      binaryInsertion(start, end)
      return
    }
    if length < 63 {
      minRun = (length + 1) / 2
      buildRuns(start, end)
      let middle = start + minRun
      if checkBounds(start, middle, end) { redistributeBufferBackward(start, middle, end) }
      return
    }
    minRun = length
    while minRun >= 32 { minRun = (minRun + 1) / 2 }
    var blockLength = minRun
    while blockLength * blockLength < length { blockLength *= 2 }
    let tagLength = length / blockLength - 2
    let ideal = tagLength + blockLength
    let rightRun = buildUniqueRunBackward(end, ideal)
    var leftRun = 0
    let backwardBuffer: Bool
    if rightRun == ideal {
      backwardBuffer = true
    } else {
      leftRun = buildUniqueRun(start, ideal)
      if leftRun == ideal { backwardBuffer = false }
      else { backwardBuffer = (rightRun < 16 && leftRun < 16) || rightRun >= leftRun }
    }
    let keys = backwardBuffer ? findKeysBackward(start, end, rightRun, ideal) : findKeys(start, end, leftRun, ideal)
    if keys < ideal {
      if keys == 1 { return }
      if keys <= 4 { inPlaceMergeSort(start, end) }
      else { adaptiveSortWithoutBuffer(start, end, keys, ideal, backwardBuffer) }
      return
    }
    let buffer: Int
    let dataStart: Int
    let dataEnd: Int
    let tags: Int
    if backwardBuffer {
      buffer = end - blockLength
      dataStart = start
      dataEnd = buffer - tagLength
      tags = dataEnd
    } else {
      buffer = start + tagLength
      dataStart = buffer + blockLength
      dataEnd = end
      tags = start
    }
    buildRuns(dataStart, dataEnd)
    var runLength = minRun
    while runLength <= blockLength && runLength < length {
      var index = dataStart
      while index + 2 * runLength <= dataEnd {
        smartMerge(index, index + runLength, index + 2 * runLength, buffer)
        index += 2 * runLength
      }
      if index + runLength < dataEnd { smartMergeBackward(index, index + runLength, dataEnd, buffer) }
      runLength *= 2
    }
    while runLength < length {
      var index = dataStart
      while index + 2 * runLength <= dataEnd {
        smartBlockMerge(index, index + runLength, index + 2 * runLength, tags, buffer, blockLength)
        index += 2 * runLength
      }
      if index + runLength < dataEnd {
        if dataEnd - (index + runLength) > blockLength {
          smartBlockMerge(index, index + runLength, dataEnd, tags, buffer, blockLength)
        } else {
          smartMergeBackward(index, index + runLength, dataEnd, buffer)
        }
      }
      runLength *= 2
    }
    binaryInsertion(buffer, buffer + blockLength)
    if backwardBuffer {
      start = rightBinarySearch(start, dataEnd, read(dataEnd))
      redistributeBufferBackward(start, dataEnd, end)
    } else {
      end = leftBinarySearch(dataStart, end, read(dataStart - 1))
      redistributeBuffer(start, dataStart, end)
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
let sorter = AdaptiveGrailExample(array)
sorter.sort(0, array.count)
array = sorter.values
print(array)
