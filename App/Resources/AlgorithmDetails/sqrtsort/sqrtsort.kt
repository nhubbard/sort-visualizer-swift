// MIT License
// Copyright (c) 2014 Andrey Astrelin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

private class SqrtSorter(private val a: Array<Int>) {
  private var buffer = emptyArray<Int>()
  private var tags = IntArray(0)
  private fun read(storage: Int, index: Int) = if (storage == 0) a[index] else buffer[index]
  private fun write(storage: Int, index: Int, value: Int) {
    if (storage == 0) a[index] = value else buffer[index] = value
  }
  private fun compare(firstStorage: Int, first: Int, secondStorage: Int, second: Int): Int =
    read(firstStorage, first).compareTo(read(secondStorage, second))
  private fun copyValues(sourceStorage: Int, source: Int, targetStorage: Int, target: Int, count: Int) {
    if (sourceStorage == targetStorage && source < target && target < source + count) {
      for (i in count - 1 downTo 0) write(targetStorage, target + i, read(sourceStorage, source + i))
    } else {
      for (i in 0 until count) write(targetStorage, target + i, read(sourceStorage, source + i))
    }
  }
  private fun swap(storage: Int, first: Int, second: Int) {
    if (first == second) return
    val value = read(storage, first)
    write(storage, first, read(storage, second))
    write(storage, second, value)
  }
  private fun insertion(storage: Int, position: Int, length: Int) {
    for (index in position + 1 until position + length) {
      val value = read(storage, index)
      var cursor = index
      while (cursor > position && read(storage, cursor - 1) > value) {
        write(storage, cursor, read(storage, cursor - 1)); cursor--
      }
      write(storage, cursor, value)
    }
  }
  private fun mergeRight(storage: Int, position: Int, leftLength: Int, rightLength: Int, distance: Int) {
    var destination = position + leftLength + rightLength + distance - 1
    var right = position + leftLength + rightLength - 1
    var left = position + leftLength - 1
    while (left >= position) {
      if (right < position + leftLength || compare(storage, left, storage, right) > 0)
        write(storage, destination, read(storage, left--))
      else write(storage, destination, read(storage, right--))
      destination--
    }
    if (right != destination) while (right >= position + leftLength)
      write(storage, destination--, read(storage, right--))
  }
  private fun mergeLeft(storage: Int, position: Int, leftLength: Int, rightLength: Int, distance: Int) {
    var left = position
    var right = position + leftLength
    var destination = position + distance
    val leftEnd = right
    val rightEnd = right + rightLength
    while (right < rightEnd) {
      if (left == leftEnd || compare(storage, left, storage, right) > 0)
        write(storage, destination, read(storage, right++))
      else write(storage, destination, read(storage, left++))
      destination++
    }
    if (destination != left) while (left < leftEnd)
      write(storage, destination++, read(storage, left++))
  }
  private fun mergeDown(storage: Int, position: Int, prefix: Int, prefixPosition: Int, leftLength: Int, prefixLength: Int) {
    var left = 0
    var right = 0
    var destination = position - prefixLength
    while (right < prefixLength) {
      if (left == leftLength || compare(storage, position + left, prefix, prefixPosition + right) >= 0)
        write(storage, destination, read(prefix, prefixPosition + right++))
      else write(storage, destination, read(storage, position + left++))
      destination++
    }
    if (destination != position + left) while (left < leftLength)
      write(storage, destination++, read(storage, position + left++))
  }
  private fun smartMerge(storage: Int, position: Int, priorLength: Int, priorFragment: Int, blockLength: Int): Pair<Int, Int> {
    var left = position
    var right = position + priorLength
    var destination = position - blockLength
    var leftEnd = right
    var rightEnd = right + blockLength
    val opposite = 1 - priorFragment
    while (left < leftEnd && right < rightEnd) {
      val order = compare(storage, left, storage, right)
      if (order < 0 || (order == 0 && opposite == 1)) write(storage, destination, read(storage, left++))
      else write(storage, destination, read(storage, right++))
      destination++
    }
    if (left < leftEnd) {
      val remaining = leftEnd - left
      while (left < leftEnd) { leftEnd--; rightEnd--; write(storage, rightEnd, read(storage, leftEnd)) }
      return Pair(remaining, priorFragment)
    }
    return Pair(rightEnd - right, opposite)
  }
  private fun mergeBuffers(storage: Int, position: Int, middleTag: Int, blockCount: Int,
                           blockLength: Int, trailingABlocks: Int, tailLength: Int) {
    if (blockCount == 0) { mergeLeft(storage, position, trailingABlocks * blockLength, tailLength, -blockLength); return }
    var priorLength = blockLength
    var priorFragment = if (tags[0] < middleTag) 0 else 1
    var process = blockLength
    for (tagIndex in 1 until blockCount) {
      var rest = process - priorLength
      val nextFragment = if (tags[tagIndex] < middleTag) 0 else 1
      if (nextFragment == priorFragment) {
        copyValues(storage, position + rest, storage, position + rest - blockLength, priorLength)
        rest = process; priorLength = blockLength
      } else {
        val result = smartMerge(storage, position + rest, priorLength, priorFragment, blockLength)
        priorLength = result.first; priorFragment = result.second
      }
      process += blockLength
    }
    var rest = process - priorLength
    if (tailLength != 0) {
      if (priorFragment != 0) {
        copyValues(storage, position + rest, storage, position + rest - blockLength, priorLength)
        rest = process; priorLength = blockLength * trailingABlocks
      } else priorLength += blockLength * trailingABlocks
      mergeLeft(storage, position + rest, priorLength, tailLength, -blockLength)
    } else copyValues(storage, position + rest, storage, position + rest - blockLength, priorLength)
  }
  private fun buildBlocks(storage: Int, positionIn: Int, length: Int, blockLength: Int) {
    var position = positionIn
    var pair = 1
    while (pair < length) {
      val lower = if (compare(storage, position + pair - 1, storage, position + pair) > 0) 1 else 0
      write(storage, position + pair - 3, read(storage, position + pair - 1 + lower))
      write(storage, position + pair - 2, read(storage, position + pair - lower))
      pair += 2
    }
    if (length % 2 != 0) write(storage, position + length - 3, read(storage, position + length - 1))
    position -= 2
    var part = 2
    while (part < blockLength) {
      var left = 0
      val right = length - 2 * part
      while (left <= right) { mergeLeft(storage, position + left, part, part, -part); left += 2 * part }
      val rest = length - left
      if (rest > part) mergeLeft(storage, position + left, part, rest - part, -part)
      else while (left < length) { write(storage, position + left - part, read(storage, position + left)); left++ }
      position -= part; part *= 2
    }
    val remainder = length % (2 * blockLength)
    var leftover = length - remainder
    if (remainder <= blockLength) copyValues(storage, position + leftover, storage, position + leftover + blockLength, remainder)
    else mergeRight(storage, position + leftover, blockLength, remainder - blockLength, blockLength)
    while (leftover > 0) { leftover -= 2 * blockLength; mergeRight(storage, position + leftover, blockLength, blockLength, blockLength) }
  }
  private fun combineBlocks(storage: Int, position: Int, lengthIn: Int, runLength: Int, blockLength: Int) {
    var length = lengthIn
    val combineCount = length / (2 * runLength)
    var remainder = length % (2 * runLength)
    if (remainder <= runLength) { length -= remainder; remainder = 0 }
    for (group in 0..combineCount) {
      if (group == combineCount && remainder == 0) break
      val groupPosition = position + group * 2 * runLength
      val count = (if (group == combineCount) remainder else 2 * runLength) / blockLength
      val tagEnd = count + if (group == combineCount) 1 else 0
      for (tag in 0..tagEnd) tags[tag] = tag
      val middle = runLength / blockLength
      for (tagIndex in 1 until count) {
        var selected = tagIndex - 1
        for (candidate in tagIndex until count) {
          val order = compare(storage, groupPosition + selected * blockLength,
                              storage, groupPosition + candidate * blockLength)
          if (order > 0 || (order == 0 && tags[selected] > tags[candidate])) selected = candidate
        }
        if (selected != tagIndex - 1) {
          for (offset in 0 until blockLength)
            swap(storage, groupPosition + (tagIndex - 1) * blockLength + offset,
                 groupPosition + selected * blockLength + offset)
          val firstTag = tags[tagIndex - 1]
          tags[tagIndex - 1] = tags[selected]; tags[selected] = firstTag
        }
      }
      var trailingA = 0
      val tail = if (group == combineCount) remainder % blockLength else 0
      if (tail != 0) while (trailingA < count && compare(storage, groupPosition + count * blockLength,
          storage, groupPosition + (count - trailingA - 1) * blockLength) < 0) trailingA++
      mergeBuffers(storage, groupPosition, middle, count - trailingA, blockLength, trailingA, tail)
    }
    if (length > 0) for (index in length - 1 downTo 0)
      write(storage, position + index, read(storage, position + index - blockLength))
  }
  private fun commonSort(storage: Int, position: Int, length: Int, prefix: Int, prefixPosition: Int) {
    if (length <= 16) { insertion(storage, position, length); return }
    var blockLength = 1
    while (blockLength * blockLength < length) blockLength *= 2
    copyValues(storage, position, prefix, prefixPosition, blockLength)
    commonSort(prefix, prefixPosition, blockLength, storage, position)
    buildBlocks(storage, position + blockLength, length - blockLength, blockLength)
    var runLength = blockLength
    while (true) {
      runLength *= 2
      if (length <= runLength) break
      combineBlocks(storage, position + blockLength, length - blockLength, runLength, blockLength)
    }
    mergeDown(storage, position + blockLength, prefix, prefixPosition, length - blockLength, blockLength)
  }
  fun sort() {
    val length = a.size
    if (length < 2) return
    var bufferLength = 1
    while (bufferLength * bufferLength < length) bufferLength *= 2
    buffer = Array(bufferLength) { 0 }
    tags = IntArray((length - 1) / bufferLength + 2)
    commonSort(0, 0, length, 1, 0)
  }
}
fun sort(array: Array<Int>) { SqrtSorter(array).sort() }
fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[${array.joinToString(", ")}]")
}
