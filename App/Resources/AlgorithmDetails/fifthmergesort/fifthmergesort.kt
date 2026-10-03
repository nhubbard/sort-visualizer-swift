// Five-way stable merge with a one-fifth external buffer.
private class FifthMerge(private val a: IntArray) {
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
            if (i + gap < end) merge(first, i, i + gap, end, fromBuffer)
            else {
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

fun sort(a: IntArray) = FifthMerge(a).sort()

fun main() {
    val a = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
    sort(a)
    println(a.joinToString(", ", "[", "]"))
}
