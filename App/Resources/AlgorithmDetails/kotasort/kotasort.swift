// MIT License
// Copyright (c) 2020 aphitorite
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

final class KotaSortExample {
  var values: [Int]
  private var bufPos = 0
  private var blockLen = 0
  private var bufLen = 0
  private var tagLen = 0

  init(_ input: [Int]) { values = input }

  private func read(_ index: Int) -> Int { values[index] }
  private func swap(_ left: Int, _ right: Int) { values.swapAt(left, right) }
  private func less(_ left: Int, _ right: Int) -> Bool { values[left] < values[right] }
  private func greater(_ left: Int, _ right: Int) -> Bool { values[left] > values[right] }
  private func atMost(_ left: Int, _ right: Int) -> Bool { values[left] <= values[right] }
  private func atLeast(_ left: Int, _ right: Int) -> Bool { values[left] >= values[right] }
  private func equalValues(_ left: Int, _ right: Int) -> Bool { left == right }

  private func rotate(_ start: Int, _ middle: Int, _ end: Int) {
    guard start < middle && middle < end else { return }
    var position = start
    var leftLength = middle - start
    var rightLength = end - middle
    while leftLength != 0 && rightLength != 0 {
      if leftLength <= rightLength {
        for offset in 0..<leftLength { values.swapAt(position + offset, position + leftLength + offset) }
        position += leftLength
        rightLength -= leftLength
      } else {
        for offset in 0..<rightLength {
          values.swapAt(position + leftLength - rightLength + offset, position + leftLength + offset)
        }
        leftLength -= rightLength
      }
    }
  }

  private func binarySearch(_ start: Int, _ end: Int, _ value: Int, left: Bool) -> Int {
    var a = start
    var b = end
    while a < b {
      let middle = a + (b - a) / 2
      if left ? values[middle] >= value : values[middle] > value { b = middle }
      else { a = middle + 1 }
    }
    return a
  }

  private func findKeys(_ start: Int, _ end: Int, _ target: Int) -> Int {
    var count = 1
    var pos = start
    var posEnd = start + 1
    var index = start + 1
    while index < end && count < target {
      let value = read(index)
      var loc = binarySearch(pos, posEnd, value, left: true)
      if index == loc || !equalValues(value, read(loc)) {
        rotate(pos, posEnd, index)
        let increase = index - posEnd
        loc += increase
        pos += increase
        posEnd += increase
        rotate(loc, posEnd, posEnd + 1)
        count += 1
        posEnd += 1
      }
      index += 1
    }
    rotate(start, pos, posEnd)
    return count
  }

  private func swapToTags(_ position: Int, _ tag: Int) { swap(bufPos + tag, position) }

  private func shift(_ aIn: Int, _ middleIn: Int, _ bIn: Int, left: Bool) {
    var a = aIn
    var middle = middleIn
    var b = bIn
    if left {
      while middle > a { b -= 1; middle -= 1; swap(b, middle) }
    } else {
      while middle < b { swap(a, middle); a += 1; middle += 1 }
    }
  }

  private func multiSwap(_ a: Int, _ b: Int, _ length: Int) {
    guard length > 0 else { return }
    for offset in 0..<length { swap(a + offset, b + offset) }
  }

  private func multiSwapBackward(_ a: Int, _ b: Int, _ length: Int) {
    guard length > 0 else { return }
    for offset in 0..<length { swap(a - offset, b - offset) }
  }

  private func blockSelect(_ position: Int, _ count: Int) {
    guard count > 0 else { return }
    for tag in 0..<count {
      let start = position + tag * blockLen
      var minimum = start
      if tag + 1 < count {
        for index in (tag + 1)..<count {
          let candidate = position + index * blockLen
          if less(candidate, minimum) { minimum = candidate }
        }
      }
      if start != minimum { multiSwap(start, minimum, blockLen) }
      swapToTags(start, tag)
    }
  }

  private func blockSelectBackward(_ position: Int, _ count: Int) {
    guard count > 0 else { return }
    for tag in 0..<count {
      let start = position - tag * blockLen
      var minimum = start
      if tag + 1 < count {
        for index in (tag + 1)..<count {
          let candidate = position - index * blockLen
          if less(candidate, minimum) { minimum = candidate }
        }
      }
      if start != minimum { multiSwapBackward(start, minimum, blockLen) }
      swapToTags(start, tag)
    }
  }

  private func inPlaceMerge(_ a: Int, _ middle: Int, _ b: Int) {
    var i = a
    var j = middle
    while i < j && j < b {
      if greater(i, j) {
        let k = binarySearch(j, b, read(i), left: true)
        rotate(i, j, k)
        i += k - j
        j = k
      } else { i += 1 }
    }
  }

  private func inPlaceMergeBackward(_ a: Int, _ middle: Int, _ b: Int) {
    var i = middle - 1
    var j = b - 1
    while j > i && i >= a {
      if atLeast(i, j) {
        let k = binarySearch(a, i + 1, read(j), left: true)
        rotate(k, i + 1, j + 1)
        j -= i + 1 - k
        i = k - 1
      } else { j -= 1 }
    }
  }

  private func inPlaceMerge2(_ start: Int, _ middle: Int, _ end: Int) {
    var i = start
    var m = middle
    var k = middle
    while m < end {
      if atMost(m - 1, m) { return }
      while i < m - 1 && atMost(i, m) { i += 1 }
      swap(i, k)
      i += 1
      k += 1
      while i < m {
        while i < m && k < end && greater(m, k) {
          swap(i, k)
          i += 1
          k += 1
        }
        if i >= m { break }
        if k >= end { rotate(i, m, end); return }
        if k - m >= m - i { rotate(i, m, k); break }
        var q = m
        while i < m && q < k && atMost(q, k) {
          swap(i, q)
          i += 1
          q += 1
        }
        rotate(m, q, k)
      }
      m = k
    }
  }

  private func inPlaceMergeSort2(_ start: Int, _ end: Int) {
    var width = 1
    while width < end - start {
      var position = start
      while position + 2 * width < end {
        inPlaceMerge2(position, position + width, position + 2 * width)
        position += 2 * width
      }
      if position + width < end { inPlaceMerge2(position, position + width, end) }
      width *= 2
    }
  }

  private func mergeWithBuf(_ a: Int, _ middle: Int, _ b: Int, _ length: Int) {
    var i = a
    var j = middle
    var k = a - length
    while i < middle && j < b {
      if atMost(i, j) { swap(k, i); i += 1 }
      else { swap(k, j); j += 1 }
      k += 1
    }
    while j < b { swap(k, j); k += 1; j += 1 }
    shift(k, i, middle, left: false)
  }

  private func dualMerge(_ a: Int, _ middle: Int, _ b: Int, _ length: Int) {
    if b - middle <= length { mergeWithBuf(a, middle, b, length); return }
    var i = a
    var j = middle
    var k = a - length
    while k < i && i < middle {
      if atMost(i, j) { swap(k, i); i += 1 }
      else { swap(k, j); j += 1 }
      k += 1
    }
    if k < i { shift(j - length, j, b, left: false) }
    else {
      var i2 = middle - 1
      var j2 = b - 1
      k = middle - 1 + b - j
      while i2 >= i && j2 >= j {
        if greater(i2, j2) { swap(k, i2); i2 -= 1 }
        else { swap(k, j2); j2 -= 1 }
        k -= 1
      }
      while j2 >= j { swap(k, j2); k -= 1; j2 -= 1 }
    }
  }

  private func dualMergeBackward(_ a: Int, _ middle: Int, _ b: Int, _ length: Int) {
    var i = middle - 1
    var j = b - 1
    var k = b - 1 + length
    while k > j && j >= middle {
      if greater(i, j) { swap(k, i); i -= 1 }
      else { swap(k, j); j -= 1 }
      k -= 1
    }
    if j < middle { shift(a, i + 1, i + 1 + length, left: true) }
    else {
      let firstEnd = i + 1
      let secondEnd = j + 1
      var i2 = a
      var j2 = middle
      k = middle - (firstEnd - a)
      while i2 < firstEnd && j2 < secondEnd {
        if atMost(i2, j2) { swap(k, i2); i2 += 1 }
        else { swap(k, j2); j2 += 1 }
        k += 1
      }
      while i2 < firstEnd { swap(k, i2); k += 1; i2 += 1 }
    }
  }

  private func mergeWithBufStatic(_ a: Int, _ middle: Int, _ b: Int, _ p: Int, backward: Bool) {
    guard middle - a > 0 && b - middle > 0 else { return }
    if backward {
      var i = b - middle - 1
      var j = middle - 1
      var k = b - 1
      while i >= 0 && j >= a {
        if read(j) >= read(p + i) {
          let q = binarySearch(a, j + 1, read(p + i), left: true)
          while j >= q { swap(k, j); k -= 1; j -= 1 }
        }
        swap(k, p + i); k -= 1; i -= 1
      }
      while i >= 0 { swap(k, p + i); k -= 1; i -= 1 }
    } else {
      var i = 0
      var j = middle
      var k = a
      while i < middle - a && j < b {
        if read(j) < read(p + i) {
          let q = binarySearch(j, b, read(p + i), left: true)
          while j < q { swap(k, j); k += 1; j += 1 }
        }
        swap(k, p + i); k += 1; i += 1
      }
      while i < middle - a { swap(k, p + i); k += 1; i += 1 }
    }
  }

  private func blockMerge(_ a: Int, _ middle: Int, _ b: Int) {
    if b - middle <= 2 * bufLen { dualMerge(a, middle, b, bufLen); return }
    var i = a
    var j = middle
    var leftAvailable = bufLen
    var rightAvailable = 0
    var left = i - bufLen
    var right = j
    var tagCount = 0

    while i < middle && leftAvailable >= rightAvailable {
      var count = 0
      while i < middle && count < blockLen {
        if atMost(i, j) { swap(left, i); i += 1 }
        else { swap(left, j); j += 1; rightAvailable += 1; leftAvailable -= 1 }
        left += 1
        count += 1
      }
    }

    let selectionStart = left
    while i < middle && j < b {
      while i < middle && j < b && rightAvailable > leftAvailable {
        let first = right
        var count = 0
        while i < middle && j < b && count < blockLen {
          if atMost(i, j) { swap(right, i); i += 1; rightAvailable -= 1; leftAvailable += 1 }
          else { swap(right, j); j += 1 }
          right += 1
          count += 1
        }
        while i < middle && count < blockLen {
          swap(right, i); right += 1; i += 1
          rightAvailable -= 1; leftAvailable += 1; count += 1
        }
        while j < b && count < blockLen { swap(right, j); right += 1; j += 1; count += 1 }
        if count == blockLen { swapToTags(first, tagCount); tagCount += 1 }
        else { shift(first, first + count, b, left: true); j = b - count; right = first }
      }

      while i < middle && j < b && leftAvailable >= rightAvailable {
        let first = left
        var count = 0
        while i < middle && j < b && count < blockLen {
          if atMost(i, j) { swap(left, i); i += 1 }
          else { swap(left, j); j += 1; rightAvailable += 1; leftAvailable -= 1 }
          left += 1
          count += 1
        }
        while i < middle && count < blockLen { swap(left, i); left += 1; i += 1; count += 1 }
        while j < b && count < blockLen {
          swap(left, j); left += 1; j += 1
          rightAvailable += 1; leftAvailable -= 1; count += 1
        }
        if count == blockLen { swapToTags(first, tagCount); tagCount += 1 }
        else { rotate(first, middle, right); left += right - middle; leftAvailable = 0 }
      }
    }

    if i >= middle && leftAvailable == blockLen && tagCount > 0 {
      multiSwap(left, right - blockLen, blockLen)
    } else {
      if i < middle { rotate(left, middle, right); left += right - middle }
      shift(left, left + leftAvailable, right, left: false)
    }
    if j < b { shift(j - bufLen, j, b, left: false) }
    blockSelect(selectionStart, tagCount)
  }

  private func blockMergeBackward(_ a: Int, _ middle: Int, _ b: Int) {
    var i = middle - 1
    var j = b - 1
    var leftAvailable = 0
    var rightAvailable = bufLen
    var left = i
    var right = j + bufLen
    var tagCount = 0

    while j >= middle && rightAvailable >= leftAvailable {
      var count = 0
      while j >= middle && count < blockLen {
        if greater(i, j) { swap(right, i); i -= 1; leftAvailable += 1; rightAvailable -= 1 }
        else { swap(right, j); j -= 1 }
        right -= 1
        count += 1
      }
    }

    let selectionStart = right
    while j >= middle && i >= a {
      while j >= middle && i >= a && leftAvailable > rightAvailable {
        let first = left
        var count = 0
        while j >= middle && i >= a && count < blockLen {
          if greater(i, j) { swap(left, i); i -= 1 }
          else { swap(left, j); j -= 1; rightAvailable += 1; leftAvailable -= 1 }
          left -= 1
          count += 1
        }
        while j >= middle && count < blockLen {
          swap(left, j); left -= 1; j -= 1
          rightAvailable += 1; leftAvailable -= 1; count += 1
        }
        while i >= a && count < blockLen { swap(left, i); left -= 1; i -= 1; count += 1 }
        if count == blockLen { swapToTags(first, tagCount); tagCount += 1 }
        else { shift(a, first + 1 - count, first + 1, left: false); i = a - 1 + count; left = first }
      }

      while j >= middle && i >= a && rightAvailable >= leftAvailable {
        let first = right
        var count = 0
        while j >= middle && i >= a && count < blockLen {
          if greater(i, j) { swap(right, i); i -= 1; leftAvailable += 1; rightAvailable -= 1 }
          else { swap(right, j); j -= 1 }
          right -= 1
          count += 1
        }
        while j >= middle && count < blockLen { swap(right, j); right -= 1; j -= 1; count += 1 }
        while i >= a && count < blockLen {
          swap(right, i); right -= 1; i -= 1
          leftAvailable += 1; rightAvailable -= 1; count += 1
        }
        if count == blockLen { swapToTags(first, tagCount); tagCount += 1 }
        else { rotate(left + 1, middle, first + 1); right -= middle - (left + 1); rightAvailable = 0 }
      }
    }

    if j < middle && rightAvailable == blockLen && tagCount > 0 {
      multiSwapBackward(right, left + blockLen, blockLen)
    } else {
      if j >= middle { rotate(left + 1, middle, right + 1); right -= middle - (left + 1) }
      shift(left + 1, right + 1 - rightAvailable, right + 1, left: true)
    }
    if i >= a { shift(a, i + 1, i + 1 + bufLen, left: true) }
    blockSelectBackward(selectionStart, tagCount)
  }

  private func kotaIterator(_ start: Int, _ end: Int) -> Bool {
    var width = 1
    let effectiveStart = start + bufLen
    let length = end - effectiveStart

    while width < 16 {
      var position = effectiveStart
      while position + 2 * width < end {
        inPlaceMerge2(position, position + width, position + 2 * width)
        position += 2 * width
      }
      if position + width < end { inPlaceMerge2(position, position + width, end) }
      width *= 2
    }

    while width <= bufLen {
      let length = width
      var position = effectiveStart
      while position + 2 * width < end {
        mergeWithBuf(position, position + width, position + 2 * width, length)
        position += 2 * width
      }
      if position + width < end { mergeWithBuf(position, position + width, end, length) }
      else { shift(position - length, position, end, left: false) }
      width *= 2

      position = effectiveStart - length
      while position + 2 * width < end - length { position += 2 * width }
      if position + width < end - length {
        dualMergeBackward(position, position + width, end - length, length)
      } else { shift(position, end - length, end, left: true) }
      position -= 2 * width
      while position >= effectiveStart - length {
        dualMergeBackward(position, position + width, position + 2 * width, length)
        position -= 2 * width
      }
      width *= 2
    }

    while width < length {
      var position = effectiveStart
      while position + 2 * width < end {
        blockMerge(position, position + width, position + 2 * width)
        position += 2 * width
      }
      if position + width < end { blockMerge(position, position + width, end) }
      else { shift(position - bufLen, position, end, left: false) }
      width *= 2
      if width >= length { return true }

      position = start
      while position + 2 * width < end - bufLen { position += 2 * width }
      if position + width < end - bufLen {
        blockMergeBackward(position, position + width, end - bufLen)
      } else { shift(position, end - bufLen, end, left: true) }
      position -= 2 * width
      while position >= start {
        blockMergeBackward(position, position + width, position + 2 * width)
        position -= 2 * width
      }
      width *= 2
    }
    return false
  }

  func sort() {
    let length = values.count
    if length <= 128 { inPlaceMergeSort2(0, length); return }
    bufPos = 0
    blockLen = 1
    while blockLen * blockLen < length { blockLen *= 2 }

    let bufferTarget = blockLen * 2
    bufLen = findKeys(0, length, bufferTarget)
    if bufLen < bufferTarget {
      if bufLen > 1 { inPlaceMergeSort2(0, length) }
      return
    }

    let tagTarget = length / blockLen
    tagLen = findKeys(bufLen, length, tagTarget)
    if tagLen < tagTarget { inPlaceMergeSort2(0, length); return }

    let bufferStart = tagLen
    let effectiveStart = bufferStart + bufLen
    let bufferEnd = bufLen
    shift(0, bufferEnd, effectiveStart, left: false)
    let backward = kotaIterator(bufferStart, length)

    if backward {
      let endStart = length - bufLen
      multiSwap(0, endStart, tagLen)
      mergeWithBufStatic(0, bufferStart, endStart, endStart, backward: false)
      inPlaceMergeSort2(endStart, length)

      let middle = endStart + blockLen
      var position = binarySearch(0, endStart, read(middle - 1), left: true)
      rotate(position, endStart, middle)
      position += blockLen

      multiSwapBackward(length - 1, position - 1, blockLen)
      mergeWithBufStatic(0, position - blockLen, position, middle, backward: true)
      inPlaceMergeSort2(middle, length)
      inPlaceMergeBackward(position, middle, length)
      // The source leaves the first tagged block ahead of smaller restored keys when the
      // insertion point is the beginning of the run. Join that block with the restored suffix.
      inPlaceMerge(0, position, length)
    } else {
      mergeWithBufStatic(bufferEnd, effectiveStart, length, 0, backward: false)
      inPlaceMergeSort2(0, bufferEnd)

      let middle = blockLen
      var position = binarySearch(bufferEnd, length, read(middle), left: true)
      rotate(middle, bufferEnd, position)
      position -= blockLen

      multiSwap(0, position, blockLen)
      mergeWithBufStatic(position, position + blockLen, length, 0, backward: false)
      inPlaceMergeSort2(0, middle)
      inPlaceMerge(0, middle, position)
      // The symmetric final boundary can leave two restored blocks transposed.
      inPlaceMerge2(length - 2 * blockLen, length - blockLen, length)
      // The preceding tagged block may still cross the restored suffix.
      inPlaceMerge(0, length - 2 * blockLen, length)
    }
  }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
let sorter = KotaSortExample(array)
sorter.sort()
array = sorter.values
print(array)
