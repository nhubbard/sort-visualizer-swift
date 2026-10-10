// Copyright (C) 2008 The Android Open Source Project
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

private class TimSort(private val a: IntArray) {
    private val n = a.size
    private val capacity = if (n < 120) 5 else if (n < 1542) 10 else if (n < 119151) 19 else 40
    private val base = IntArray(capacity)
    private val length = IntArray(capacity)
    private var stackSize = 0
    private var temp = IntArray(0)
    private var minGallop = 7

    private fun ensureCapacity(needed: Int) {
        if (temp.size >= needed) return
        var size = maxOf(1, temp.size)
        while (size < needed) size *= 2
        size = minOf(size, maxOf(1, n / 2))
        temp = IntArray(size)
    }
    private fun minRunLength(value: Int): Int {
        var size = value
        var remainder = 0
        while (size >= 32) {
            remainder = remainder or (size and 1)
            size = size shr 1
        }
        return size + remainder
    }
    private fun countRun(first: Int, end: Int): Int {
        if (first + 1 >= end) return 1
        var cursor = first + 2
        if (a[first + 1] < a[first]) {
            while (cursor < end && a[cursor] < a[cursor - 1]) cursor++
            var left = first
            var right = cursor - 1
            while (left < right) {
                val value = a[left]
                a[left++] = a[right]
                a[right--] = value
            }
        } else {
            while (cursor < end && a[cursor] >= a[cursor - 1]) cursor++
        }
        return cursor - first
    }
    private fun binaryInsertion(first: Int, end: Int, sortedEnd: Int) {
        var cursor = maxOf(first + 1, sortedEnd)
        while (cursor < end) {
            val pivot = a[cursor]
            var low = first
            var high = cursor
            while (low < high) {
                val middle = low + (high - low) / 2
                if (a[middle] <= pivot) low = middle + 1 else high = middle
            }
            for (shift in cursor downTo low + 1) a[shift] = a[shift - 1]
            a[low] = pivot
            cursor++
        }
    }
    private fun gallop(first: Int, end: Int, key: Int, upper: Boolean,
                       fromEnd: Boolean, useTemp: Boolean): Int {
        if (first >= end) return first
        val source = if (useTemp) temp else a
        fun before(index: Int): Boolean =
            if (upper) source[index] <= key else source[index] < key
        var low: Int
        var high: Int
        if (fromEnd) {
            high = end
            low = end - 1
            var step = 1
            while (!before(low)) {
                high = low
                if (low == first) break
                step = minOf(end - first, step * 2)
                low = maxOf(first, end - step)
            }
        } else {
            low = first
            high = first + 1
            while (before(high - 1) && high < end) {
                low = high
                high = minOf(end, first + (high - first) * 2)
            }
        }
        while (low < high) {
            val middle = low + (high - low) / 2
            if (before(middle)) low = middle + 1 else high = middle
        }
        return low
    }
    private fun mergeLow(first: Int, leftLength: Int, rightStart: Int, rightLength: Int) {
        ensureCapacity(leftLength)
        for (i in 0 until leftLength) temp[i] = a[first + i]
        var left = 0
        var right = rightStart
        var destination = first
        val rightEnd = rightStart + rightLength
        var leftWins = 0
        var rightWins = 0
        var galloped = false
        while (left < leftLength && right < rightEnd) {
            if (a[right] < temp[left]) {
                a[destination] = a[right++]; rightWins++; leftWins = 0
            } else {
                a[destination] = temp[left++]; leftWins++; rightWins = 0
            }
            destination++
            if (left >= leftLength || right >= rightEnd) break
            if (maxOf(leftWins, rightWins) < minGallop) continue
            galloped = true
            val leftStop = gallop(left, leftLength, a[right], true, false, true)
            while (left < leftStop) a[destination++] = temp[left++]
            if (left == leftLength) break
            a[destination++] = a[right++]
            if (right == rightEnd) break
            val rightStop = gallop(right, rightEnd, temp[left], false, false, false)
            while (right < rightStop) a[destination++] = a[right++]
            if (right == rightEnd) break
            a[destination++] = temp[left++]
            minGallop = maxOf(1, minGallop - 1)
            leftWins = 0; rightWins = 0
        }
        while (left < leftLength) a[destination++] = temp[left++]
        if (galloped) minGallop += 2
    }
    private fun mergeHigh(first: Int, leftLength: Int, rightStart: Int, rightLength: Int) {
        ensureCapacity(rightLength)
        for (i in 0 until rightLength) temp[i] = a[rightStart + i]
        var left = rightStart - 1
        var right = rightLength - 1
        var destination = rightStart + rightLength - 1
        var leftWins = 0
        var rightWins = 0
        var galloped = false
        while (left >= first && right >= 0) {
            if (temp[right] < a[left]) {
                a[destination] = a[left--]; leftWins++; rightWins = 0
            } else {
                a[destination] = temp[right--]; rightWins++; leftWins = 0
            }
            destination--
            if (left < first || right < 0) break
            if (maxOf(leftWins, rightWins) < minGallop) continue
            galloped = true
            val leftStop = gallop(first, left + 1, temp[right], true, true, false)
            while (left >= leftStop) a[destination--] = a[left--]
            if (left < first) break
            a[destination--] = temp[right--]
            if (right < 0) break
            val rightStop = gallop(0, right + 1, a[left], false, true, true)
            while (right >= rightStop) a[destination--] = temp[right--]
            if (right < 0) break
            a[destination--] = a[left--]
            minGallop = maxOf(1, minGallop - 1)
            leftWins = 0; rightWins = 0
        }
        while (right >= 0) a[destination--] = temp[right--]
        if (galloped) minGallop += 2
    }
    private fun mergeAt(index: Int) {
        var leftStart = base[index]
        var leftLength = length[index]
        val rightStart = base[index + 1]
        var rightLength = length[index + 1]
        length[index] = leftLength + rightLength
        if (index == stackSize - 3) {
            base[index + 1] = base[index + 2]
            length[index + 1] = length[index + 2]
        }
        stackSize--
        val skipped = gallop(leftStart, rightStart, a[rightStart], true, false, false)
        leftLength -= skipped - leftStart
        leftStart = skipped
        if (leftLength == 0) return
        rightLength = gallop(rightStart, rightStart + rightLength,
                             a[rightStart - 1], false, false, false) - rightStart
        if (rightLength == 0) return
        if (leftLength <= rightLength) mergeLow(leftStart, leftLength, rightStart, rightLength)
        else mergeHigh(leftStart, leftLength, rightStart, rightLength)
    }
    private fun collapse() {
        while (stackSize > 1) {
            var index = stackSize - 2
            if ((index >= 1 && length[index - 1] <= length[index] + length[index + 1]) ||
                (index >= 2 && length[index - 2] <= length[index] + length[index - 1])) {
                if (length[index - 1] < length[index + 1]) index--
            } else if (length[index] > length[index + 1]) break
            mergeAt(index)
        }
    }
    private fun forceCollapse() {
        while (stackSize > 1) {
            var index = stackSize - 2
            if (index > 0 && length[index - 1] < length[index + 1]) index--
            mergeAt(index)
        }
    }
    fun sort() {
        if (n < 32) {
            binaryInsertion(0, n, countRun(0, n))
            return
        }
        val minRun = minRunLength(n)
        var cursor = 0
        while (cursor < n) {
            var run = countRun(cursor, n)
            if (run < minRun) {
                val forced = minOf(minRun, n - cursor)
                binaryInsertion(cursor, cursor + forced, cursor + run)
                run = forced
            }
            base[stackSize] = cursor
            length[stackSize] = run
            stackSize++
            collapse()
            cursor += run
        }
        forceCollapse()
    }
}

fun sort(a: IntArray) {
    if (a.size > 1) TimSort(a).sort()
}
fun main() {
    val a = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
    sort(a)
    println(a.joinToString(", ", "[", "]"))
}
