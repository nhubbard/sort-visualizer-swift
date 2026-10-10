// MIT License
// Copyright (c) 2020-2021 aphitorite
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

private class Ecta(private val a: Array<Int>) {
  private val n = a.size
  private var block = 0
  private var bufferLength = 0
  private var buffer = emptyArray<Int>()
  private var tags = IntArray(0)

  private fun minRun(value: Int): Int {
    var size = value
    while (size >= 32) size = (size + 1) / 2
    return size
  }
  private fun insertion(start: Int, end: Int) {
    for (index in start + 1 until end) {
      val value = a[index]
      var low = start
      var high = index
      while (low < high) {
        val middle = (low + high) / 2
        if (a[middle] > value) high = middle else low = middle + 1
      }
      for (cursor in index downTo low + 1) a[cursor] = a[cursor - 1]
      a[low] = value
    }
  }
  private fun copy(source: Int, destination: Int, count: Int) {
    if (count > 0) System.arraycopy(a, source, a, destination, count)
  }
  private fun mergeTo(start: Int, middle: Int, end: Int, destination: Int) {
    var left = start
    var right = middle
    var output = destination
    while (left < middle && right < end) {
      if (a[left] <= a[right]) a[output] = a[left++] else a[output] = a[right++]
      output++
    }
    while (left < middle) a[output++] = a[left++]
    while (right < end) a[output++] = a[right++]
  }
  private fun pingPong(start: Int, m1: Int, m2: Int, m3: Int, end: Int, workspace: Int) {
    val second = workspace + m2 - start
    mergeTo(start, m1, m2, workspace)
    mergeTo(m2, m3, end, second)
    mergeTo(workspace, second, workspace + end - start, start)
  }
  private fun mergeBackward(start: Int, middle: Int, end: Int, workspace: Int) {
    val count = end - middle
    copy(middle, workspace, count)
    var left = middle - 1
    var right = workspace + count - 1
    var output = end
    while (left >= start && right >= workspace) {
      --output
      if (a[left] > a[right]) a[output] = a[left--] else a[output] = a[right--]
    }
    while (right >= workspace) a[--output] = a[right--]
  }
  private fun mergeFromBuffer(start: Int, middle: Int, end: Int, count: Int) {
    var index = 0
    var right = middle
    var output = start
    while (index < count && right < end) {
      if (a[right] >= buffer[index]) a[output] = buffer[index++] else a[output] = a[right++]
      output++
    }
    while (index < count) a[output++] = buffer[index++]
  }
  private fun dualMergeBackward(start: Int, first: Int, middle: Int, end: Int, count: Int) {
    var index = count - 1
    val split = count - (end - middle)
    var left = middle - 1
    var output = end
    while (index >= split && left >= first) {
      --output
      if (a[left] < buffer[index]) a[output] = buffer[index--] else a[output] = a[left--]
    }
    if (left < first) while (index >= 0) a[--output] = buffer[index--]
    else mergeFromBuffer(start, first, output, split)
  }
  private fun mergeSort(start: Int, end: Int, workspace: Int, initialRun: Int, capacity: Int): Int {
    var run = initialRun
    var index = start
    while (index + run <= end) { insertion(index, index + run); index += run }
    insertion(index, end)
    while (4 * run <= capacity) {
      index = start
      while (index + 4 * run <= end) {
        pingPong(index, index + run, index + 2 * run, index + 3 * run, index + 4 * run, workspace)
        index += 4 * run
      }
      if (index + 3 * run < end) pingPong(index, index + run, index + 2 * run, index + 3 * run, end, workspace)
      else if (index + 2 * run < end) pingPong(index, index + run, index + 2 * run, end, end, workspace)
      else if (index + run < end) mergeBackward(index, index + run, end, workspace)
      run *= 4
    }
    while (run <= capacity) {
      index = start
      while (index + 2 * run <= end) { mergeBackward(index, index + run, index + 2 * run, workspace); index += 2 * run }
      if (index + run < end) mergeBackward(index, index + run, end, workspace)
      run *= 2
    }
    return run
  }
  private fun toBuffer(source: Int, count: Int) { for (i in 0 until count) buffer[i] = a[source + i] }
  private fun fromBuffer(destination: Int, count: Int) { for (i in 0 until count) a[destination + i] = buffer[i] }
  private fun blockCycle(start: Int, count: Int, workspace: Int, excludeLast: Boolean, forward: Boolean) {
    val stride = if (forward) block else -block
    for (index in 0 until count) {
      var next = tags[index]
      if (index == next) continue
      copy(start + index * stride, workspace, block)
      var current = index
      while (true) {
        if (!(excludeLast && current == count - 1)) copy(start + next * stride, start + current * stride, block)
        tags[current] = current
        current = next
        next = tags[next]
        if (next == index) break
      }
      copy(workspace, start + current * stride, block)
      tags[current] = current
    }
  }
  private fun ectaForward(start: Int, middle: Int, end: Int) {
    var left = start; var right = middle; var tag = 0; var tagCount = 0
    var saved = 2 * block; var other = 0
    var savedPosition = start - 2 * block; var otherPosition = middle
    do {
      val choice = if (saved < block) 1 else 0
      for (offset in 0 until block) {
        val destination = (if (choice == 0) savedPosition else otherPosition) + offset
        if (left < middle && right < end) {
          if (a[left] <= a[right]) { a[destination] = a[left++]; saved++ }
          else { a[destination] = a[right++]; other++ }
        } else if (left < middle) { a[destination] = a[left++]; saved++ }
        else { a[destination] = a[right++]; other++ }
      }
      if (choice == 0) { savedPosition += block; saved -= block }
      else { otherPosition += block; other -= block }
      tags[tagCount++] = if (choice == 0) tag++ else -1
    } while (left < middle || right < end)
    if (saved > 0) tags[tagCount] = tag++
    for (index in 2 until tagCount) if (tags[index] == -1) tags[index] = tag++
    blockCycle(start - 2 * block, tag, end - block, saved > 0, true)
  }
  private fun ectaBackward(start: Int, middle: Int, end: Int) {
    var right = end - 1; var left = middle - 1; var tag = 0; var tagCount = 0
    var saved = 2 * block; var other = 0
    var savedPosition = end + 2 * block; var otherPosition = middle
    do {
      val choice = if (saved < block) 1 else 0
      for (offset in 1..block) {
        val destination = (if (choice == 0) savedPosition else otherPosition) - offset
        if (right >= middle && left >= start) {
          if (a[right] >= a[left]) { a[destination] = a[right--]; saved++ }
          else { a[destination] = a[left--]; other++ }
        } else if (right >= middle) { a[destination] = a[right--]; saved++ }
        else { a[destination] = a[left--]; other++ }
      }
      if (choice == 0) { savedPosition -= block; saved -= block }
      else { otherPosition -= block; other -= block }
      tags[tagCount++] = if (choice == 0) tag++ else -1
    } while (right >= middle || left >= start)
    if (saved > 0) tags[tagCount] = tag++
    for (index in 2 until tagCount) if (tags[index] == -1) tags[index] = tag++
    blockCycle(end + block, tag, start, saved > 0, false)
  }
  fun sort() {
    if (n < 2) return
    if (n <= 32) { insertion(0, n); return }
    if (n < 256) bufferLength = n / 2
    else {
      block = minRun(n)
      while (block * block < n / 2) block *= 2
      bufferLength = 2 * block + n % block
    }
    buffer = Array(bufferLength) { 0 }
    tags = IntArray(if (block == 0) 0 else (n - bufferLength) / block + 1)
    if (n < 256) {
      toBuffer(bufferLength, bufferLength)
      mergeSort(0, bufferLength, bufferLength, minRun(n), bufferLength)
      fromBuffer(bufferLength, bufferLength)
      toBuffer(0, bufferLength)
      mergeSort(bufferLength, n, 0, minRun(n), bufferLength)
      mergeFromBuffer(0, bufferLength, n, bufferLength)
      return
    }
    var start = bufferLength; var end = n
    val dataLength = end - start
    toBuffer(start, bufferLength)
    mergeSort(0, start, start, minRun(bufferLength), bufferLength)
    fromBuffer(start, bufferLength)
    toBuffer(0, bufferLength)
    var run = mergeSort(start, end, 0, minRun(n), bufferLength)
    var backward = false
    while (run < dataLength) {
      var index = start
      while (index + 2 * run <= end) { ectaForward(index, index + run, index + 2 * run); index += 2 * run }
      if (index + run < end) ectaForward(index, index + run, end)
      else copy(index, index - 2 * block, end - index)
      run *= 2; start -= 2 * block; end -= 2 * block
      if (run >= dataLength) { backward = true; break }
      index = start
      while (index + 2 * run <= end) index += 2 * run
      if (index + run < end) ectaBackward(index, index + run, end)
      else copy(index, index + 2 * block, end - index)
      index -= 2 * run
      while (index >= start) { ectaBackward(index, index + run, index + 2 * run); index -= 2 * run }
      run *= 2; start += 2 * block; end += 2 * block
    }
    if (backward) dualMergeBackward(0, start, end, n, bufferLength)
    else mergeFromBuffer(0, start, end, bufferLength)
  }
}
fun sort(array: Array<Int>) { Ecta(array).sort() }
fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[${array.joinToString(", ")}]")
}
