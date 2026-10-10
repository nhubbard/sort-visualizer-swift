// MIT License
// Copyright (c) 2021 aphitorite
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

data class KeyGroup(
  val start: Int,
  val end: Int,
)

// Five-way stable merge with a one-fifth external buffer.
class FifthMerge(
  private val a: IntArray,
) {
  private val n = a.size
  private val chunk = n / 5
  private val bufferLength = n - 4 * chunk
  private val buffer = IntArray(bufferLength)

  private fun binaryInsertion(first: Int, end: Int) {
    for (i in first + 1 until end) {
      val value = a[i]
      var low = first
      var high = i
      while (low < high) {
        val middle = low + (high - low) / 2
        if (a[middle] > value) high = middle else low = middle + 1
      }
      for (j in i downTo low + 1) a[j] = a[j - 1]
      a[low] = value
    }
  }

  private fun source(index: Int, offset: Int, fromBuffer: Boolean): Int =
    if (fromBuffer) buffer[index - offset] else a[index]

  private fun merge(offset: Int, first: Int, middle: Int, end: Int, fromBuffer: Boolean) {
    var left = first
    var right = middle
    var destination = if (fromBuffer) first else first - offset

    fun write(value: Int) {
      if (fromBuffer) a[destination] = value else buffer[destination] = value
      destination++
    }
    while (left < middle && right < end) {
      if (source(left, offset, fromBuffer) <= source(right, offset, fromBuffer))
        write(source(left++, offset, fromBuffer))
      else write(source(right++, offset, fromBuffer))
    }
    while (left < middle) write(source(left++, offset, fromBuffer))
    while (right < end) write(source(right++, offset, fromBuffer))
  }

  private fun pingPong(first: Int, end: Int) {
    var i = first
    while (i + 8 < end) {
      binaryInsertion(i, i + 8)
      i += 8
    }
    if (end - i > 1) binaryInsertion(i, end)
    val length = end - first
    var fromBuffer = false
    var gap = 8
    while (gap < length) {
      val full = gap * 2
      i = first
      while (i + full < end) {
        merge(first, i, i + gap, i + full, fromBuffer)
        i += full
      }
      if (i + gap < end) {
        merge(first, i, i + gap, end, fromBuffer)
      } else {
        for (j in i until end) {
          if (fromBuffer) a[j] = buffer[j - first]
          else buffer[j - first] = a[j]
        }
      }
      fromBuffer = !fromBuffer
      gap *= 2
    }
    if (fromBuffer) for (j in 0 until length) a[first + j] = buffer[j]
  }

  private fun mergeForward(destinationStart: Int, first: Int, middle: Int, end: Int) {
    var destination = destinationStart
    var left = first
    var right = middle
    while (left < middle && right < end) {
      if (a[left] <= a[right]) a[destination++] = a[left++]
      else a[destination++] = a[right++]
    }
    while (left < middle) a[destination++] = a[left++]
    while (right < end) a[destination++] = a[right++]
  }

  private fun mergeBackward(destinationStart: Int, middle: Int, end: Int): Pair<Int, Int> {
    var destination = destinationStart
    var left = middle - 1
    var right = end - 1
    while (destination > right && right >= middle && left >= 0) {
      if (a[left] > a[right]) a[destination--] = a[left--]
      else a[destination--] = a[right--]
    }
    if (left < 0) {
      while (right >= middle) a[destination--] = a[right--]
    } else if (right == left) {
      while (right >= 0) a[destination--] = a[right--]
    } else if (right < middle) {
      while (left >= 0) a[destination--] = a[left--]
    }
    return Pair(left + 1, right + 1)
  }

  private fun mergeMainPrefix(destinationStart: Int, leftEnd: Int, middle: Int, end: Int) {
    var destination = destinationStart
    var left = 0
    var right = middle
    while (left < leftEnd && right < end) {
      if (a[left] <= a[right]) a[destination++] = a[left++]
      else a[destination++] = a[right++]
    }
    while (left < leftEnd) a[destination++] = a[left++]
  }

  private fun mergeExternal(destinationStart: Int, middle: Int, end: Int) {
    var destination = destinationStart
    var left = 0
    var right = middle
    while (left < bufferLength && right < end) {
      if (buffer[left] <= a[right]) a[destination++] = buffer[left++]
      else a[destination++] = a[right++]
    }
    while (left < bufferLength) a[destination++] = buffer[left++]
  }

  fun sort() {
    if (n <= 1) return
    pingPong(0, bufferLength)
    var first = bufferLength
    repeat(4) {
      pingPong(first, first + chunk)
      first += chunk
    }
    for (i in 0 until bufferLength) buffer[i] = a[i]
    val twoFifths = 2 * chunk
    first = bufferLength
    repeat(2) {
      mergeForward(first - bufferLength, first, first + chunk, first + twoFifths)
      first += twoFifths
    }
    val remaining = mergeBackward(n - 1, twoFifths, 2 * twoFifths)
    if (remaining.second > 0) mergeMainPrefix(bufferLength, remaining.first, twoFifths, n)
    mergeExternal(0, bufferLength, n)
  }
}

class ChaliceSortExample(
  private val values: IntArray,
) {
  private var temp = IntArray(0)

  private fun relation(left: Int, right: Int, op: String): Boolean = when (op) {
    "<" -> {
      left < right
    }

    "<=" -> {
      left <= right
    }

    ">" -> {
      left > right
    }

    ">=" -> {
      left >=
        right
    }

    else -> {
      left == right
    }
  }

  fun read(index: Int): Int = values[index]

  fun write(index: Int, value: Int) {
    values[index] = value
  }

  fun swap(first: Int, second: Int) {
    val held = values[first]
    values[first] = values[second]
    values[second] = held
  }

  fun compare(first: Int, second: Int, predicate: String): Boolean = relation(values[first], values[second], predicate)

  fun compareValues(first: Int, second: Int, predicate: String): Boolean = relation(first, second, predicate)

  fun save(index: Int, value: Int) {
    temp[index] = value
  }

  fun load(index: Int): Int = temp[index]

  fun shiftForwardExternal(destination: Int, source: Int, end: Int) {
    var input = 0
    var output = 0
    output = destination
    run {
      input = source
      while (input < end) {
        write(output, read(input))
        output += 1

        input++
      }
    }
  }

  fun shiftBackwardExternal(start: Int, sourceEnd: Int, destinationEnd: Int) {
    var input = 0
    var output = 0
    input = sourceEnd
    output = destinationEnd
    while ((input > start)) {
      input -= 1
      output -= 1
      write(output, read(input))
    }
  }

  fun rightBinarySearch(start: Int, end: Int, value: Int): Int {
    var lower = 0
    var middle = 0
    var upper = 0
    lower = start
    upper = end
    while ((lower < upper)) {
      middle = (lower + ((upper - lower) / 2))
      if ((read(middle) <= value)) {
        lower = (middle + 1)
      } else {
        upper = middle
      }
    }
    return lower
  }

  fun multiSwap(first: Int, second: Int, length: Int) {
    var offset = 0
    if (!((length > 0))) {
      return
    }
    run {
      offset = 0
      while (offset < length) {
        swap((first + offset), (second + offset))

        offset++
      }
    }
  }

  fun binaryInsertion(start: Int, end: Int) {
    var high = 0
    var index = 0
    var low = 0
    var middle = 0
    var value = 0
    if (!(((end - start) > 1))) {
      return
    }
    run {
      index = (start + 1)
      while (index < end) {
        value = read(index)
        low = start
        high = index
        while ((low < high)) {
          middle = (low + ((high - low) / 2))
          if ((read(middle) > value)) {
            high = middle
          } else {
            low = (middle + 1)
          }
        }
        insertTo(index, low)

        index++
      }
    }
  }

  fun ceilCbrt(value: Int): Int {
    var high = 0
    var low = 0
    var middle = 0
    low = 0
    high = 11
    while ((low < high)) {
      middle = ((low + high) / 2)
      if (((1 shl (3 * middle)) >= value)) {
        high = middle
      } else {
        low = (middle + 1)
      }
    }
    return (1 shl low)
  }

  fun calcKeys(blockLength: Int, count: Int): Int {
    var high = 0
    var low = 0
    var middle = 0
    low = 1
    high = (count / 4)
    while ((low < high)) {
      middle = ((low + high) / 2)
      if ((((((count - (4 * middle)) - 1) / blockLength) - 2) < middle)) {
        high = middle
      } else {
        low = (middle + 1)
      }
    }
    return low
  }

  fun leftBinSearch(startIn: Int, endIn: Int, value: Int): Int {
    var end = 0
    var middle = 0
    var start = 0
    start = startIn
    end = endIn
    while ((start < end)) {
      middle = (start + ((end - start) / 2))
      if ((values[middle] >= value)) {
        end = middle
      } else {
        start = (middle + 1)
      }
    }
    return start
  }

  fun rotate(start: Int, middle: Int, end: Int) {
    var leftLength = 0
    var offset = 0
    var position = 0
    var rightLength = 0
    if (!(((start < middle) && (middle < end)))) {
      return
    }
    position = start
    leftLength = (middle - start)
    rightLength = (end - middle)
    while (((leftLength != 0) && (rightLength != 0))) {
      if ((leftLength <= rightLength)) {
        run {
          offset = 0
          while (offset < leftLength) {
            swap((position + offset), ((position + leftLength) + offset))

            offset++
          }
        }
        position += leftLength
        rightLength -= leftLength
      } else {
        run {
          offset = 0
          while (offset < rightLength) {
            swap((((position + leftLength) - rightLength) + offset), ((position + leftLength) + offset))

            offset++
          }
        }
        leftLength -= rightLength
      }
    }
  }

  fun insertTo(source: Int, destination: Int) {
    var cursor = 0
    var value = 0
    value = read(source)
    cursor = source
    while ((cursor > destination)) {
      write(cursor, read((cursor - 1)))
      cursor -= 1
    }
    write(destination, value)
  }

  fun shiftForward(destination: Int, source: Int, end: Int) {
    var offset = 0
    if (!((source < end))) {
      return
    }
    run {
      offset = 0
      while (offset < (end - source)) {
        swap((destination + offset), (source + offset))

        offset++
      }
    }
  }

  fun shiftBackward(start: Int, sourceEnd: Int, destinationEnd: Int) {
    var destination = 0
    var source = 0
    source = sourceEnd
    destination = destinationEnd
    while ((source > start)) {
      source -= 1
      destination -= 1
      swap(destination, source)
    }
  }

  fun mergeForwardExternal(startIn: Int, middle: Int, end: Int) {
    var left = 0
    var leftLength = 0
    var offset = 0
    var right = 0
    var start = 0
    leftLength = (middle - startIn)
    if (!((leftLength > 0))) {
      return
    }
    run {
      offset = 0
      while (offset < leftLength) {
        save(offset, read((startIn + offset)))

        offset++
      }
    }
    start = startIn
    left = 0
    right = middle
    while (((left < leftLength) && (right < end))) {
      if (compareValues(load(left), read(right), "<=")) {
        write(start, load(left))
        left += 1
      } else {
        write(start, read(right))
        right += 1
      }
      start += 1
    }
    while ((left < leftLength)) {
      write(start, load(left))
      left += 1
      start += 1
    }
  }

  fun mergeBackwardExternal(start: Int, middle: Int, endIn: Int) {
    var end = 0
    var left = 0
    var offset = 0
    var right = 0
    var rightLength = 0
    rightLength = (endIn - middle)
    if (!((rightLength > 0))) {
      return
    }
    run {
      offset = 0
      while (offset < rightLength) {
        save(offset, read((middle + offset)))

        offset++
      }
    }
    end = endIn
    right = (rightLength - 1)
    left = (middle - 1)
    while (((right >= 0) && (left >= start))) {
      end -= 1
      if (compareValues(load(right), read(left), ">=")) {
        write(end, load(right))
        right -= 1
      } else {
        write(end, read(left))
        left -= 1
      }
    }
    while ((right >= 0)) {
      end -= 1
      write(end, load(right))
      right -= 1
    }
  }

  fun mergeWithBufferForward(startIn: Int, middle: Int, end: Int, destinationIn: Int, external: Boolean) {
    var chooseLeft = false
    var destination = 0
    var right = 0
    var source = 0
    var start = 0
    start = startIn
    right = middle
    destination = destinationIn
    while (((start < middle) && (right < end))) {
      chooseLeft = compare(start, right, "<=")
      source = (if (chooseLeft) start else right)
      if (external) {
        write(destination, read(source))
      } else {
        swap(destination, source)
      }
      if (chooseLeft) {
        start += 1
      } else {
        right += 1
      }
      destination += 1
    }
    if ((start > destination)) {
      if (external) {
        shiftForwardExternal(destination, start, middle)
      } else {
        shiftForward(destination, start, middle)
      }
    }
    if (external) {
      shiftForwardExternal(destination, right, end)
    } else {
      shiftForward(destination, right, end)
    }
  }

  fun mergeWithBufferBackward(start: Int, middle: Int, endIn: Int, destinationEndIn: Int, external: Boolean) {
    var destinationEnd = 0
    var left = 0
    var right = 0
    left = (middle - 1)
    right = (endIn - 1)
    destinationEnd = destinationEndIn
    while (((right >= middle) && (left >= start))) {
      destinationEnd -= 1
      if (compare(right, left, ">=")) {
        if (external) {
          write(destinationEnd, read(right))
        } else {
          swap(destinationEnd, right)
        }
        right -= 1
      } else {
        if (external) {
          write(destinationEnd, read(left))
        } else {
          swap(destinationEnd, left)
        }
        left -= 1
      }
    }
    if ((destinationEnd > right)) {
      if (external) {
        shiftBackwardExternal(middle, (right + 1), destinationEnd)
      } else {
        shiftBackward(middle, (right + 1), destinationEnd)
      }
    }
    if (external) {
      shiftBackwardExternal(start, (left + 1), destinationEnd)
    } else {
      shiftBackward(start, (left + 1), destinationEnd)
    }
  }

  fun inPlaceMerge(startIn: Int, middleIn: Int, end: Int) {
    var insertion = 0
    var middle = 0
    var moved = 0
    var start = 0
    start = startIn
    middle = middleIn
    while (((start < middle) && (middle < end))) {
      start = rightBinarySearch(start, middle, read(middle))
      if ((start == middle)) {
        return
      }
      insertion = leftBinSearch(middle, end, read(start))
      rotate(start, middle, insertion)
      moved = (insertion - middle)
      middle = insertion
      start += (moved + 1)
    }
  }

  fun laziestSortExternal(start: Int, end: Int) {
    var cursor = 0
    var next = 0
    cursor = start
    while ((cursor < end)) {
      next = minOf(end, (cursor + temp.size))
      binaryInsertion(cursor, next)
      if ((cursor > start)) {
        mergeBackwardExternal(start, cursor, next)
      }
      cursor = next
    }
  }

  fun findKeysSmall(start: Int, end: Int, otherStart: Int, otherEnd: Int, full: Boolean, needed: Int): KeyGroup {
    var displaced = 0
    var first = 0
    var index = 0
    var last = 0
    var location = 0
    var otherLocation = 0
    first = start
    last = 0
    if (full) {
      last = 0
      while ((first < end)) {
        location = leftBinSearch(otherStart, otherEnd, read(first))
        if (((location == otherEnd) || !(compare(first, location, "==")))) {
          last = (first + 1)
          break
        }
        first += 1
      }
      if ((last != 0)) {
        index = last
        while (((index < end) && ((last - first) < needed))) {
          otherLocation = leftBinSearch(otherStart, otherEnd, read(index))
          if (((otherLocation == otherEnd) || !(compare(index, otherLocation, "==")))) {
            location = leftBinSearch(first, last, read(index))
            if (((location == last) || !(compare(index, location, "==")))) {
              rotate(first, last, index)
              displaced = (index - last)
              first += displaced
              location += displaced
              last = (index + 1)
              insertTo(index, location)
            }
          }
          index += 1
        }
      } else {
        last = first
      }
    } else {
      last = (first + 1)
      index = last
      while (((index < end) && ((last - first) < needed))) {
        location = leftBinSearch(first, last, read(index))
        if (((location == last) || !(compare(index, location, "==")))) {
          rotate(first, last, index)
          displaced = (index - last)
          first += displaced
          location += displaced
          last = (index + 1)
          insertTo(index, location)
        }
        index += 1
      }
    }
    return KeyGroup(first, last)
  }

  fun findKeys(start: Int, end: Int, desired: Int, stride: Int): Int {
    var first = 0
    var found = 0
    var group = KeyGroup(0, 0)
    var last = 0
    var remaining = 0
    var secondStart = 0
    group = findKeysSmall(start, end, 0, 0, false, minOf(desired, stride))
    first = group.start
    last = group.end
    if (((stride < desired) && ((last - first) == stride))) {
      remaining = (desired - stride)
      while (true) {
        group = findKeysSmall(last, end, first, last, true, minOf(stride, remaining))
        found = (group.end - group.start)
        if ((found == 0)) {
          break
        }
        if (((found < stride) || (remaining == stride))) {
          rotate(last, group.start, group.end)
          secondStart = last
          last += found
          mergeBackwardExternal(first, secondStart, last)
          break
        }
        rotate(first, last, group.start)
        first += (group.start - last)
        last = group.end
        mergeBackwardExternal(first, group.start, last)
        remaining -= stride
      }
    }
    rotate(start, first, last)
    return (last - first)
  }

  fun findBitsSmall(start: Int, end: Int, referenceIn: Int, backward: Boolean, needed: Int): KeyGroup {
    var first = 0
    var index = 0
    var last = 0
    var reference = 0
    first = start
    reference = referenceIn
    while (((first < end) && !(compare(first, reference, (if (backward) "<" else ">"))))) {
      first += 1
    }
    reference += 1
    last = 0
    if ((first < end)) {
      last = (first + 1)
      index = last
      while (((index < end) && ((last - first) < needed))) {
        if (compare(index, reference, (if (backward) "<" else ">"))) {
          rotate(first, last, index)
          first += (index - last)
          last = (index + 1)
          reference += 1
        }
        index += 1
      }
    } else {
      last = first
    }
    return KeyGroup(first, last)
  }

  fun findBits(start: Int, end: Int, needed: Int, stride: Int): Int {
    var count = 0
    var first = 0
    var firstCount = 0
    var found = 0
    var group = KeyGroup(0, 0)
    var last = 0
    var phase = 0
    var reference = 0
    var referenceStart = 0
    laziestSortExternal(start, (start + needed))
    referenceStart = start
    reference = (start + needed)
    count = 0
    firstCount = 0
    run {
      phase = 0
      while (phase < 2) {
        if ((count >= needed)) {
          phase++
          continue
        }
        first = reference
        last = first
        while (true) {
          group = findBitsSmall(last, end, (referenceStart + count), (phase == 1), minOf(stride, (needed - count)))
          found = (group.end - group.start)
          if ((found == 0)) {
            break
          }
          count += found
          if (((found < stride) || (count == needed))) {
            rotate(last, group.start, group.end)
            last += found
            break
          }
          rotate(first, last, group.start)
          first += (group.start - last)
          last = group.end
        }
        rotate(reference, first, last)
        reference += (last - first)
        if ((phase == 0)) {
          firstCount = count
        }

        phase++
      }
    }
    if ((count < needed)) {
      return -(1)
    }
    multiSwap((start + firstCount), ((start + needed) + firstCount), (needed - firstCount))
    return firstCount
  }

  fun bitReversal(start: Int, end: Int) {
    var current = 0
    var decrement = 0
    var half = 0
    var index = 0
    var jump = 0
    var length = 0
    var offset = 0
    var threeQuarters = 0
    length = (end - start)
    offset = 0
    half = (length / 2)
    threeQuarters = (half + (half / 2))
    if ((length < 3)) {
      return
    }
    run {
      index = 1
      while (index < (length - 1)) {
        jump = half
        current = index
        decrement = threeQuarters
        while (((current and 1) == 0)) {
          jump -= decrement
          current = current shr 1
          decrement = decrement shr 1
        }
        offset += jump
        if ((offset > index)) {
          swap((start + index), (start + offset))
        }

        index++
      }
    }
  }

  fun unshuffle(start: Int, end: Int) {
    var consumed = 0
    var position = 0
    var remaining = 0
    var width = 0
    remaining = ((end - start) / 2)
    consumed = 0
    width = 2
    while ((remaining > 0)) {
      if (((remaining and 1) == 1)) {
        position = (start + consumed)
        bitReversal(position, (position + width))
        bitReversal(position, (position + (width / 2)))
        bitReversal((position + (width / 2)), (position + width))
        rotate((start + (consumed / 2)), position, (position + (width / 2)))
        consumed += width
      }
      remaining = remaining shr 1
      width *= 2
    }
  }

  fun redistributeBuffer(startIn: Int, middleIn: Int, end: Int) {
    var insertion = 0
    var middle = 0
    var moved = 0
    var size = 0
    var start = 0
    start = startIn
    middle = middleIn
    size = temp.size
    while ((((middle - start) > size) && (middle < end))) {
      insertion = leftBinSearch(middle, end, read((start + size)))
      rotate((start + size), middle, insertion)
      moved = (insertion - middle)
      middle = insertion
      mergeForwardExternal(start, (start + size), middle)
      start += (moved + size)
    }
    if ((middle < end)) {
      mergeForwardExternal(start, middle, end)
    }
  }

  fun copyMain(source: Int, destination: Int, length: Int) {
    var offset = 0
    if (!(((length > 0) && (source != destination)))) {
      return
    }
    if ((destination > source)) {
      run {
        offset = (length - 1)
        while (offset > (0 - 1)) {
          write((destination + offset), read((source + offset)))

          offset += -(1)
        }
      }
    } else {
      run {
        offset = 0
        while (offset < length) {
          write((destination + offset), read((source + offset)))

          offset++
        }
      }
    }
  }

  fun dualMergeBackward(startIn: Int, middleIn: Int, endIn: Int, destinationEndIn: Int, external: Boolean) {
    var chooseLeft = false
    var destinationEnd = 0
    var end = 0
    var left = 0
    var middle = 0
    var right = 0
    var source = 0
    var start = 0
    start = startIn
    middle = middleIn
    end = (endIn - 1)
    destinationEnd = destinationEndIn
    left = (middle - 1)
    while (((destinationEnd > (end + 1)) && (end >= middle))) {
      destinationEnd -= 1
      if (compare(end, left, ">=")) {
        if (external) {
          write(destinationEnd, read(end))
        } else {
          swap(destinationEnd, end)
        }
        end -= 1
      } else {
        if (external) {
          write(destinationEnd, read(left))
        } else {
          swap(destinationEnd, left)
        }
        left -= 1
      }
    }
    if ((end < middle)) {
      if (external) {
        shiftBackwardExternal(start, (left + 1), destinationEnd)
      } else {
        shiftBackward(start, (left + 1), destinationEnd)
      }
    } else {
      left += 1
      end += 1
      destinationEnd = (middle - (left - start))
      right = middle
      while (((start < left) && (right < end))) {
        chooseLeft = compare(start, right, "<=")
        source = (if (chooseLeft) start else right)
        if (external) {
          write(destinationEnd, read(source))
        } else {
          swap(destinationEnd, source)
        }
        if (chooseLeft) {
          start += 1
        } else {
          right += 1
        }
        destinationEnd += 1
      }
      while ((start < left)) {
        if (external) {
          write(destinationEnd, read(start))
        } else {
          swap(destinationEnd, start)
        }
        start += 1
        destinationEnd += 1
      }
    }
  }

  fun smartMerge(destinationIn: Int, startIn: Int, middle: Int, reversed: Boolean): Int {
    var chooseLeft = false
    var destination = 0
    var right = 0
    var start = 0
    destination = destinationIn
    start = startIn
    right = middle
    while ((start < middle)) {
      chooseLeft = (if (reversed) compare(start, right, "<") else compare(start, right, "<="))
      if (chooseLeft) {
        write(destination, read(start))
        start += 1
      } else {
        write(destination, read(right))
        right += 1
      }
      destination += 1
    }
    return right
  }

  fun smartTailMerge(destinationIn: Int, startIn: Int, middle: Int, end: Int) {
    var blockLength = 0
    var bufferIndex = 0
    var destination = 0
    var offset = 0
    var right = 0
    var start = 0
    destination = destinationIn
    start = startIn
    right = middle
    blockLength = temp.size
    while (((start < middle) && (right < end))) {
      if (compare(start, right, "<=")) {
        write(destination, read(start))
        start += 1
      } else {
        write(destination, read(right))
        right += 1
      }
      destination += 1
    }
    if ((start < middle)) {
      if ((start > destination)) {
        shiftForwardExternal(destination, start, middle)
      }
      run {
        offset = 0
        while (offset < blockLength) {
          write(((end - blockLength) + offset), load(offset))

          offset++
        }
      }
    } else {
      bufferIndex = 0
      while (((bufferIndex < blockLength) && (right < end))) {
        if (compareValues(load(bufferIndex), read(right), "<=")) {
          write(destination, load(bufferIndex))
          bufferIndex += 1
        } else {
          write(destination, read(right))
          right += 1
        }
        destination += 1
      }
      while ((bufferIndex < blockLength)) {
        write(destination, load(bufferIndex))
        bufferIndex += 1
        destination += 1
      }
    }
  }

  fun blockCycle(start: Int, tagStart: Int, sortedTags: Int, tagCount: Int, blockLength: Int) {
    var index = 0
    var next = 0
    var position = 0
    if (!((tagCount > 1))) {
      return
    }
    run {
      index = 0
      while (index < (tagCount - 1)) {
        if ((
            compare((tagStart + index), (sortedTags + index), ">") ||
              ((index > 0) && compare((tagStart + index), ((sortedTags + index) - 1), "<"))
          )
        ) {
          copyMain((start + (index * blockLength)), (start - blockLength), blockLength)
          position = index
          next = (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index))) - sortedTags)
          while (true) {
            copyMain((start + (next * blockLength)), (start + (position * blockLength)), blockLength)
            swap((tagStart + index), (tagStart + next))
            position = next
            next = (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index))) - sortedTags)
            if (!((next != index))) {
              break
            }
          }
          copyMain((start - blockLength), (start + (position * blockLength)), blockLength)
        }

        index++
      }
    }
  }

  fun blockCycleEasy(start: Int, tagStart: Int, sortedTags: Int, tagCount: Int, blockLength: Int) {
    var index = 0
    var next = 0
    if (!((tagCount > 1))) {
      return
    }
    run {
      index = 0
      while (index < (tagCount - 1)) {
        if ((
            compare((tagStart + index), (sortedTags + index), ">") ||
              ((index > 0) && compare((tagStart + index), ((sortedTags + index) - 1), "<"))
          )
        ) {
          next = (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index))) - sortedTags)
          while (true) {
            multiSwap((start + (index * blockLength)), (start + (next * blockLength)), blockLength)
            swap((tagStart + index), (tagStart + next))
            next = (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index))) - sortedTags)
            if (!((next != index))) {
              break
            }
          }
        }

        index++
      }
    }
  }

  fun inPlaceMergeBackward(start: Int, middleIn: Int, endIn: Int, reversed: Boolean): Int {
    var end = 0
    var finalEnd = 0
    var insertion = 0
    var middle = 0
    var moved = 0
    middle = middleIn
    end = endIn
    finalEnd = (if (reversed) rightBinarySearch(middle, end, read((middle - 1))) else leftBinSearch(middle, end, read((middle - 1))))
    end = finalEnd
    while (((end > middle) && (middle > start))) {
      insertion = (if (reversed) leftBinSearch(start, middle, read((end - 1))) else rightBinarySearch(start, middle, read((end - 1))))
      rotate(insertion, middle, end)
      moved = (middle - insertion)
      middle = insertion
      end -= (moved + 1)
      if ((middle == start)) {
        break
      }
      end = (if (reversed) rightBinarySearch(middle, end, read((middle - 1))) else leftBinSearch(middle, end, read((middle - 1))))
    }
    return finalEnd
  }

  fun blockMerge(
    start: Int, middle: Int, end: Int, leftTagCount: Int, tagCount: Int,
    tagStartIn: Int, sortedTagsIn: Int, firstBitsIn: Int, secondBitsIn: Int, blockLength: Int,
  ) {
    var bitsEnd = 0
    var firstBits = 0
    var fragment = 0
    var leftBlock = 0
    var leftTag = 0
    var nextBlock = 0
    var offset = 0
    var outputTag = 0
    var reversed = false
    var rightBlock = 0
    var rightTag = 0
    var secondBits = 0
    var sortedTags = 0
    var tagStart = 0
    if (((end - middle) <= blockLength)) {
      mergeBackwardExternal(start, middle, end)
      return
    }
    insertTo(((tagStartIn + leftTagCount) - 1), tagStartIn)
    leftBlock = ((start + blockLength) - 1)
    rightBlock = ((middle + blockLength) - 1)
    leftTag = tagStartIn
    rightTag = (tagStartIn + leftTagCount)
    outputTag = sortedTagsIn
    firstBits = firstBitsIn
    secondBits = secondBitsIn
    while (((leftTag < (tagStartIn + leftTagCount)) && (rightTag < (tagStartIn + tagCount)))) {
      if (compare(leftBlock, rightBlock, "<=")) {
        swap(outputTag, leftTag)
        outputTag += 1
        leftTag += 1
        leftBlock += blockLength
      } else {
        swap(outputTag, rightTag)
        outputTag += 1
        rightTag += 1
        swap(firstBits, secondBits)
        rightBlock += blockLength
      }
      firstBits += 1
      secondBits += 1
    }
    while ((leftTag < (tagStartIn + leftTagCount))) {
      swap(outputTag, leftTag)
      outputTag += 1
      leftTag += 1
      firstBits += 1
      secondBits += 1
    }
    while ((rightTag < (tagStartIn + tagCount))) {
      swap(outputTag, rightTag)
      outputTag += 1
      rightTag += 1
      swap(firstBits, secondBits)
      firstBits += 1
      secondBits += 1
    }
    tagStart = sortedTagsIn
    sortedTags = tagStartIn
    heapSort(sortedTags, (sortedTags + tagCount))
    run {
      offset = 0
      while (offset < blockLength) {
        save(offset, read(((middle - blockLength) + offset)))

        offset++
      }
    }
    copyMain(start, (middle - blockLength), blockLength)
    blockCycle((start + blockLength), tagStart, sortedTags, tagCount, blockLength)
    multiSwap(tagStart, sortedTags, tagCount)
    firstBits -= tagCount
    secondBits -= tagCount
    fragment = (start + blockLength)
    nextBlock = fragment
    bitsEnd = (secondBits + tagCount)
    reversed = compare(firstBits, secondBits, ">")
    while (true) {
      while (true) {
        if (reversed) {
          swap(firstBits, secondBits)
        }
        firstBits += 1
        secondBits += 1
        nextBlock += blockLength
        if (!(((secondBits < bitsEnd) && compare(firstBits, secondBits, (if (reversed) ">" else "<"))))) {
          break
        }
      }
      if ((secondBits == bitsEnd)) {
        smartTailMerge((fragment - blockLength), fragment, (if (reversed) fragment else nextBlock), end)
        return
      }
      fragment = smartMerge((fragment - blockLength), fragment, nextBlock, reversed)
      reversed = !(reversed)
    }
  }

  fun blockMergeEasy(
    start: Int, middle: Int, end: Int, leftTail: Int, rightTail: Int,
    leftTagCount: Int, tagCount: Int, tagStartIn: Int, sortedTagsIn: Int,
    firstBitsIn: Int, secondBitsIn: Int, blockLength: Int,
  ) {
    var ignored = 0
    var bitsEnd = 0
    var dataEnd = 0
    var dataStart = 0
    var firstBits = 0
    var fragment = 0
    var leftBlock = 0
    var leftTag = 0
    var nextBlock = 0
    var outputTag = 0
    var reversed = false
    var rightBlock = 0
    var rightTag = 0
    var secondBits = 0
    var sortedTags = 0
    var tagStart = 0
    if (((end - middle) <= blockLength)) {
      ignored = inPlaceMergeBackward(start, middle, end, false)
      return
    }
    dataStart = (start + leftTail)
    dataEnd = (end - rightTail)
    leftBlock = ((dataStart + blockLength) - 1)
    rightBlock = ((middle + blockLength) - 1)
    leftTag = sortedTagsIn
    rightTag = (sortedTagsIn + leftTagCount)
    outputTag = tagStartIn
    firstBits = firstBitsIn
    secondBits = secondBitsIn
    while (((leftTag < (sortedTagsIn + leftTagCount)) && (rightTag < (sortedTagsIn + tagCount)))) {
      if (compare(leftBlock, rightBlock, "<=")) {
        swap(leftTag, outputTag)
        leftTag += 1
        outputTag += 1
        leftBlock += blockLength
      } else {
        swap(rightTag, outputTag)
        rightTag += 1
        outputTag += 1
        swap(firstBits, secondBits)
        rightBlock += blockLength
      }
      firstBits += 1
      secondBits += 1
    }
    while ((leftTag < (sortedTagsIn + leftTagCount))) {
      swap(leftTag, outputTag)
      leftTag += 1
      outputTag += 1
      firstBits += 1
      secondBits += 1
    }
    while ((rightTag < (sortedTagsIn + tagCount))) {
      swap(rightTag, outputTag)
      rightTag += 1
      outputTag += 1
      swap(firstBits, secondBits)
      firstBits += 1
      secondBits += 1
    }
    tagStart = sortedTagsIn
    sortedTags = tagStartIn
    heapSort(sortedTags, (sortedTags + tagCount))
    blockCycleEasy(dataStart, tagStart, sortedTags, tagCount, blockLength)
    multiSwap(tagStart, sortedTags, tagCount)
    firstBits -= tagCount
    secondBits -= tagCount
    fragment = dataStart
    nextBlock = fragment
    bitsEnd = (secondBits + tagCount)
    reversed = compare(firstBits, secondBits, ">")
    while (true) {
      while (true) {
        if (reversed) {
          swap(firstBits, secondBits)
        }
        firstBits += 1
        secondBits += 1
        nextBlock += blockLength
        if (!(((secondBits < bitsEnd) && compare(firstBits, secondBits, (if (reversed) ">" else "<"))))) {
          break
        }
      }
      if ((secondBits == bitsEnd)) {
        if (!(reversed)) {
          ignored = inPlaceMergeBackward(dataStart, dataEnd, end, false)
        }
        inPlaceMerge(start, dataStart, end)
        return
      }
      fragment = inPlaceMergeBackward(fragment, nextBlock, (nextBlock + blockLength), reversed)
      reversed = !(reversed)
    }
  }

  fun sift(start: Int, rootIn: Int, limit: Int) {
    var child = 0
    var root = 0
    root = rootIn
    while ((((root * 2) + 1) < limit)) {
      child = ((root * 2) + 1)
      if ((((child + 1) < limit) && compare((start + child), ((start + child) + 1), "<"))) {
        child += 1
      }
      if (!(compare((start + root), (start + child), "<"))) {
        return
      }
      swap((start + root), (start + child))
      root = child
    }
  }

  fun heapSort(start: Int, end: Int) {
    var count = 0
    var limit = 0
    var root = 0
    count = (end - start)
    if (!((count > 1))) {
      return
    }
    run {
      root = ((count - 2) / 2)
      while (root > (0 - 1)) {
        sift(start, root, count)

        root += -(1)
      }
    }
    run {
      limit = (count - 1)
      while (limit > (1 - 1)) {
        swap(start, (start + limit))
        sift(start, 0, limit)

        limit += -(1)
      }
    }
  }

  fun sort() {
    var ignored = 0
    var bitEnd = 0
    var bitSeparation = 0
    var blockLength = 0
    var count = 0
    var cubeRoot = 0
    var dataLength = 0
    var dataStart = 0
    var end = 0
    var index = 0
    var keyEnd = 0
    var keyLength = 0
    var keys = 0
    var leftTail = 0
    var limit = 0
    var middle = 0
    var minimumLevel = 0
    var offset = 0
    var runLength = 0
    var start = 0
    var tagCount = 0
    var vacant = 0
    count = values.size
    start = 0
    end = count
    cubeRoot = (2 * ceilCbrt((count / 4)))
    blockLength = (2 * cubeRoot)
    keyLength = calcKeys(blockLength, count)
    temp = IntArray(blockLength)
    keys = findKeys(start, end, (2 * keyLength), cubeRoot)
    if ((keys < 8)) {
      runLength = 1
      while ((runLength < count)) {
        middle = (start + runLength)
        while ((middle < end)) {
          ignored = inPlaceMergeBackward((middle - runLength), middle, minOf((middle + runLength), end), false)
          middle += (2 * runLength)
        }
        runLength *= 2
      }
      return
    }
    if ((keys < (2 * keyLength))) {
      keys -= (keys % 4)
      keyLength = (keys / 2)
    }
    keyEnd = (start + keys)
    bitEnd = (keyEnd + keys)
    bitSeparation = findBits(keyEnd, end, keyLength, cubeRoot)
    if ((bitSeparation == -(1))) {
      laziestSortExternal(start, bitEnd)
      inPlaceMerge(start, bitEnd, end)
      return
    }
    dataStart = (bitEnd + blockLength)
    dataLength = (end - dataStart)
    binaryInsertion(bitEnd, dataStart)
    run {
      offset = 0
      while (offset < blockLength) {
        save(offset, read((bitEnd + offset)))

        offset++
      }
    }
    runLength = 1
    while ((runLength < cubeRoot)) {
      vacant = maxOf(2, runLength)
      index = dataStart
      while (((index + (2 * runLength)) < end)) {
        mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - vacant), true)
        index += (2 * runLength)
      }
      if (((index + runLength) < end)) {
        mergeWithBufferForward(index, (index + runLength), end, (index - vacant), true)
      } else {
        shiftForwardExternal((index - vacant), index, end)
      }
      dataStart -= vacant
      end -= vacant
      runLength *= 2
    }
    index = (end - (dataLength % (2 * runLength)))
    if (((index + runLength) < end)) {
      mergeWithBufferBackward(index, (index + runLength), end, (end + runLength), true)
    } else {
      shiftBackwardExternal(index, end, (end + runLength))
    }
    index -= (2 * runLength)
    while ((index >= dataStart)) {
      mergeWithBufferBackward(index, (index + runLength), (index + (2 * runLength)), (index + (3 * runLength)), true)
      index -= (2 * runLength)
    }
    dataStart += runLength
    end += runLength
    runLength *= 2
    index = dataStart
    while (((index + (2 * runLength)) < end)) {
      mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - runLength), true)
      index += (2 * runLength)
    }
    if (((index + runLength) < end)) {
      mergeWithBufferForward(index, (index + runLength), end, (index - runLength), true)
    } else {
      shiftForwardExternal((index - runLength), index, end)
    }
    dataStart -= runLength
    end -= runLength
    runLength *= 2
    index = (end - (dataLength % (2 * runLength)))
    if (((index + runLength) < end)) {
      dualMergeBackward(index, (index + runLength), end, (end + (runLength / 2)), true)
    } else {
      shiftBackwardExternal(index, end, (end + (runLength / 2)))
    }
    index -= (2 * runLength)
    while ((index >= dataStart)) {
      dualMergeBackward(index, (index + runLength), (index + (2 * runLength)), ((index + (2 * runLength)) + (runLength / 2)), true)
      index -= (2 * runLength)
    }
    dataStart += (runLength / 2)
    end += (runLength / 2)
    runLength *= 2
    if ((keys >= runLength)) {
      rotate(start, keyEnd, dataStart)
      bitEnd = (keyEnd + blockLength)
      if ((keyLength >= runLength)) {
        minimumLevel = (2 * runLength)
        while ((runLength < keyLength)) {
          vacant = maxOf(minimumLevel, runLength)
          index = dataStart
          while (((index + (2 * runLength)) < end)) {
            mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - vacant), false)
            index += (2 * runLength)
          }
          if (((index + runLength) < end)) {
            mergeWithBufferForward(index, (index + runLength), end, (index - vacant), false)
          } else {
            shiftForward((index - vacant), index, end)
          }
          dataStart -= vacant
          end -= vacant
          runLength *= 2
        }
        index = (end - (dataLength % (2 * runLength)))
        if (((index + runLength) < end)) {
          mergeWithBufferBackward(index, (index + runLength), end, (end + runLength), false)
        } else {
          shiftBackward(index, end, (end + runLength))
        }
        index -= (2 * runLength)
        while ((index >= dataStart)) {
          mergeWithBufferBackward(index, (index + runLength), (index + (2 * runLength)), (index + (3 * runLength)), false)
          index -= (2 * runLength)
        }
        dataStart += runLength
        end += runLength
        runLength *= 2
      }
      if ((keys >= runLength)) {
        index = dataStart
        while (((index + (2 * runLength)) < end)) {
          mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - runLength), false)
          index += (2 * runLength)
        }
        if (((index + runLength) < end)) {
          mergeWithBufferForward(index, (index + runLength), end, (index - runLength), false)
        } else {
          shiftForward((index - runLength), index, end)
        }
        dataStart -= runLength
        end -= runLength
        runLength *= 2
        index = (end - (dataLength % (2 * runLength)))
        if (((index + runLength) < end)) {
          dualMergeBackward(index, (index + runLength), end, (end + (runLength / 2)), false)
        } else {
          shiftBackward(index, end, (end + (runLength / 2)))
        }
        index -= (2 * runLength)
        while ((index >= dataStart)) {
          dualMergeBackward(index, (index + runLength), (index + (2 * runLength)), ((index + (2 * runLength)) + (runLength / 2)), false)
          index -= (2 * runLength)
        }
        dataStart += (runLength / 2)
        end += (runLength / 2)
        runLength *= 2
      }
      rotate(start, bitEnd, dataStart)
      bitEnd = (keyEnd + keys)
      heapSort(start, keyEnd)
    }
    run {
      offset = 0
      while (offset < blockLength) {
        write((bitEnd + offset), load(offset))

        offset++
      }
    }
    unshuffle(start, keyEnd)
    limit = (blockLength * (keyLength + 2))
    tagCount = ((runLength / blockLength) - 1)
    while (((runLength < dataLength) && (minOf((2 * runLength), dataLength) <= limit))) {
      index = dataStart
      while (((index + (2 * runLength)) <= end)) {
        blockMerge(
          index, (index + runLength), (index + (2 * runLength)), tagCount, (2 * tagCount), start, (start + keyLength), keyEnd,
          (
            keyEnd +
              keyLength
          ),
          blockLength,
        )
        index += (2 * runLength)
      }
      if (((index + runLength) < end)) {
        blockMerge(
          index, (index + runLength), end, tagCount, ((((end - index) - 1) / blockLength) - 1), start, (start + keyLength), keyEnd,
          (
            keyEnd +
              keyLength
          ),
          blockLength,
        )
      }
      runLength *= 2
      tagCount = ((2 * tagCount) + 1)
    }
    while ((runLength < dataLength)) {
      blockLength = ((2 * runLength) / keyLength)
      leftTail = (runLength % blockLength)
      index = dataStart
      while (((index + (2 * runLength)) <= end)) {
        blockMergeEasy(
          index, (index + runLength), (index + (2 * runLength)), leftTail, leftTail, (keyLength / 2), keyLength, start,
          (
            start +
              keyLength
          ),
          keyEnd, (keyEnd + keyLength), blockLength,
        )
        index += (2 * runLength)
      }
      if (((index + runLength) < end)) {
        blockMergeEasy(
          index, (index + runLength), end, leftTail, (((end - index) - runLength) % blockLength), (keyLength / 2),
          (
            (
              keyLength /
                2
            ) +
              (((end - index) - runLength) / blockLength)
          ),
          start, (start + keyLength), keyEnd, (keyEnd + keyLength), blockLength,
        )
      }
      runLength *= 2
    }
    multiSwap((keyEnd + bitSeparation), ((keyEnd + keyLength) + bitSeparation), (keyLength - bitSeparation))
    laziestSortExternal(start, dataStart)
    redistributeBuffer(start, dataStart, end)
  }
}

fun sort(a: IntArray) {
  if (a.size >= 32 &&
    a.size < 128
  ) {
    FifthMerge(a).sort()
  } else {
    val s = ChaliceSortExample(a)
    if (a.size < 32) s.binaryInsertion(0, a.size) else s.sort()
  }
}

fun main() {
  val a = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(a)
  println(a.joinToString(prefix = "[", postfix = "]"))
}
