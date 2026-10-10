// MIT License
// Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
// Copyright (c) 2020-2021 aphitorite
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

// Synchronous square-root block merge by aphitorite. MIT License.
private class SynchronousSqrt(private val a: IntArray) {
    private val n = a.size
    private lateinit var prefix: IntArray
    private lateinit var tags: IntArray

    private fun binaryInsertion(first: Int, end: Int) {
        for (i in first + 1 until end) {
            val value = a[i]
            var low = first
            var high = i
            while (low < high) {
                val middle = low + (high - low) / 2
                if (a[middle] <= value) low = middle + 1 else high = middle
            }
            for (j in i downTo low + 1) a[j] = a[j - 1]
            if (low != i) a[low] = value
        }
    }
    private fun shiftForward(destinationStart: Int, sourceStart: Int, end: Int) {
        var destination = destinationStart
        var source = sourceStart
        while (source < end) a[destination++] = a[source++]
    }
    private fun shiftBackward(first: Int, sourceEndStart: Int, destinationEndStart: Int) {
        var sourceEnd = sourceEndStart
        var destinationEnd = destinationEndStart
        while (sourceEnd > first) a[--destinationEnd] = a[--sourceEnd]
    }
    private fun mergeForward(first: Int, middle: Int, end: Int, outputStart: Int) {
        var left = first
        var right = middle
        var output = outputStart
        while (left < middle && right < end) {
            if (a[left] <= a[right]) a[output++] = a[left++]
            else a[output++] = a[right++]
        }
        if (left > output) shiftForward(output, left, middle)
        shiftForward(output, right, end)
    }
    private fun mergeBackward(first: Int, middle: Int, end: Int, outputStart: Int) {
        var left = middle - 1
        var right = end - 1
        var output = outputStart
        while (right >= middle && left >= first) {
            if (a[right] >= a[left]) a[--output] = a[right--]
            else a[--output] = a[left--]
        }
        if (output > right) shiftBackward(middle, right + 1, output)
        shiftBackward(first, left + 1, output)
    }
    private fun smartMergeBackward(first: Int, middle: Int, end: Int,
                                   outputStart: Int, reversed: Boolean): Int {
        var left = middle - 1
        var right = end - 1
        var output = outputStart
        while (left >= first && right >= middle) {
            val takeLeft = if (reversed) a[left] >= a[right] else a[left] > a[right]
            if (takeLeft) a[--output] = a[left--]
            else a[--output] = a[right--]
        }
        return left + 1
    }
    private fun blockSelection(first: Int, end: Int, block: Int, tagStart: Int, tagCount: Int) {
        val available = minOf(tagCount + 1, tags.size - tagStart)
        for (i in 0 until available)
            tags[tagStart + i] = i + (if (i <= tagCount / 2) 0 else tags.size)
        var vacant = first
        var current = first
        while (current < end - block) {
            var minimum = if (vacant == current) current + block else current
            var candidate = minimum + block
            while (candidate < end) {
                if (candidate != vacant &&
                    (a[candidate] < a[minimum] ||
                     (a[candidate] == a[minimum] &&
                      tags[tagStart + (candidate - first) / block] <
                      tags[tagStart + (minimum - first) / block]))) minimum = candidate
                candidate += block
            }
            if (minimum > current) {
                if (vacant == current) {
                    for (i in 0 until block) a[current + i] = a[minimum + i]
                    tags[tagStart + (current - first) / block] =
                        tags[tagStart + (minimum - first) / block]
                    vacant = minimum
                } else {
                    for (i in 0 until block) {
                        val value = a[current + i]
                        a[current + i] = a[minimum + i]
                        a[minimum + i] = value
                    }
                    val i = tagStart + (current - first) / block
                    val j = tagStart + (minimum - first) / block
                    val value = tags[i]
                    tags[i] = tags[j]
                    tags[j] = value
                }
            }
            current += block
        }
    }
    private fun mergeBlocksBackward(first: Int, end: Int, firstTag: Int,
                                    pastLastTag: Int, block: Int) {
        var tag = pastLastTag - 1
        var frontier = end
        var blockStart = end - block
        var reversed = tags[tag] < tags.size
        while (true) {
            do { tag--; blockStart -= block }
            while (tag >= firstTag && (tags[tag] < tags.size) == reversed)
            if (tag < firstTag) {
                shiftBackward(first, frontier, frontier + block)
                break
            }
            frontier = smartMergeBackward(blockStart, blockStart + block,
                                          frontier, frontier + block, reversed)
            reversed = !reversed
        }
    }

    fun sort() {
        if (n <= 16) { binaryInsertion(0, n); return }
        var block = 1
        while (block * block < n) block *= 2
        var first = block + n % block
        var end = n
        val workLength = end - first
        var run = 1
        prefix = IntArray(first)
        tags = IntArray((n - 1) / block + 1)
        binaryInsertion(0, first)
        for (i in 0 until first) prefix[i] = a[i]

        while (run < block) {
            val distance = maxOf(2, run)
            var index = first
            while (index + 2 * run < end) {
                mergeForward(index, index + run, index + 2 * run, index - distance)
                index += 2 * run
            }
            if (index + run < end) mergeForward(index, index + run, end, index - distance)
            else shiftForward(index - distance, index, end)
            first -= distance
            end -= distance
            run *= 2
        }

        var fragment = workLength % (2 * run)
        var index = end - fragment
        if (index + run < end) mergeBackward(index, index + run, end, end + run)
        else shiftBackward(index, end, end + run)
        index -= 2 * run
        while (index >= first) {
            mergeBackward(index, index + run, index + 2 * run, index + 3 * run)
            index -= 2 * run
        }
        first += run
        end += run
        run *= 2

        var tagCount = 4
        while (run < workLength) {
            index = first
            var tagIndex = 0
            while (index + 2 * run < end) {
                blockSelection(index - block, index + 2 * run, block, tagIndex, tagCount)
                index += 2 * run
                tagIndex += tagCount
            }
            val hasFragment = index + run < end
            fragment = (end - index) / block
            if (hasFragment) blockSelection(index - block, end, block, tagIndex, tagCount)
            first -= block
            end -= block
            index -= block
            if (hasFragment) mergeBlocksBackward(index, end, tagIndex, tagIndex + fragment, block)
            index -= 2 * run
            tagIndex -= tagCount
            while (index >= first) {
                mergeBlocksBackward(index, index + 2 * run, tagIndex, tagIndex + tagCount, block)
                index -= 2 * run
                tagIndex -= tagCount
            }
            first += block
            end += block
            run *= 2
            tagCount *= 2
        }

        var left = 0
        var right = first
        var output = 0
        while (left < first && right < end) {
            if (prefix[left] <= a[right]) a[output++] = prefix[left++]
            else a[output++] = a[right++]
        }
        while (left < first) a[output++] = prefix[left++]
    }
}

fun sort(a: IntArray) = SynchronousSqrt(a).sort()

fun main() {
    val a = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
    sort(a)
    println(a.joinToString(", ", "[", "]"))
}
