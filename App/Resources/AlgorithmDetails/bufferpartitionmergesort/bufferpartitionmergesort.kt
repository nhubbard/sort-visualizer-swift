// ArrayV median-merge: the larger partition is an in-array swap buffer.
private fun exchange(a: IntArray, i: Int, j: Int) {
    val value = a[i]
    a[i] = a[j]
    a[j] = value
}

private fun insertion(a: IntArray, first: Int, end: Int) {
    for (i in first + 1 until end) {
        var j = i
        while (j > first && a[j - 1] > a[j]) {
            exchange(a, j - 1, j)
            j--
        }
    }
}

private fun binaryInsertion(a: IntArray, first: Int, end: Int) {
    for (i in first + 1 until end) {
        val value = a[i]
        var low = first
        var high = i
        while (low < high) {
            val middle = low + (high - low) / 2
            if (value < a[middle]) high = middle else low = middle + 1
        }
        for (j in i downTo low + 1) a[j] = a[j - 1]
        a[low] = value
    }
}

private fun medianThree(a: IntArray, first: Int, end: Int) {
    val middle = first + (end - 1 - first) / 2
    if (a[first] > a[middle]) exchange(a, first, middle)
    if (a[middle] > a[end - 1]) {
        exchange(a, middle, end - 1)
        if (a[first] > a[middle]) return
    }
    exchange(a, first, middle)
}

private fun medianMedians(a: IntArray, first: Int, initialEnd: Int) {
    var end = initialEnd
    var alternate = true
    while (end - first > 1) {
        var write = first
        var i = first
        while (i + 10 <= end) {
            insertion(a, i, i + 5)
            exchange(a, write++, i + 2)
            i += 5
        }
        if (i < end) {
            insertion(a, i, end)
            exchange(a, write++, i + (end - (if (alternate) 1 else 0) - i) / 2)
            if ((end - i) % 2 == 0) alternate = !alternate
        }
        end = write
    }
}

private fun shiftBackward(a: IntArray, first: Int, middleStart: Int, endStart: Int) {
    var middle = middleStart
    var end = endStart
    while (middle > first) exchange(a, --middle, --end)
}
private fun multiSwap(a: IntArray, first: Int, second: Int, length: Int) {
    for (offset in 0 until length) exchange(a, first + offset, second + offset)
}
private fun rotate(a: IntArray, firstStart: Int, middleStart: Int, endStart: Int) {
    var first = firstStart
    var middle = middleStart
    var end = endStart
    var left = middle - first
    var right = end - middle
    while (left > 0 && right > 0) {
        if (right < left) {
            multiSwap(a, middle - right, middle, right)
            end -= right; middle -= right; left -= right
        } else {
            multiSwap(a, first, middle, left)
            first += left; middle += left; right -= left
        }
    }
}
private fun inPlaceMerge(a: IntArray, first: Int, middleStart: Int, end: Int) {
    var left = first
    var right = middleStart
    while (left < right && right < end) {
        if (a[left] > a[right]) {
            var upper = right + 1
            while (upper < end && a[left] > a[upper]) upper++
            rotate(a, left, right, upper)
            left += upper - right
            right = upper
        } else left++
    }
}
private fun partition(a: IntArray, first: Int, end: Int): Int {
    var left = first
    var right = end
    while (true) {
        do { left++ } while (left < right && a[left] > a[first])
        do { right-- } while (right >= left && a[right] < a[first])
        if (left >= right) return right
        exchange(a, left, right)
    }
}
private fun quickSelect(a: IntArray, initialLower: Int, initialUpper: Int, target: Int): Int {
    var lower = initialLower
    var upper = initialUpper
    var badSplit = false
    var usedMedians = false
    val targetUpper = (target + upper + 1) / 2
    while (true) {
        if (badSplit) { medianMedians(a, lower, upper); usedMedians = true }
        else medianThree(a, lower, upper)
        val pivot = partition(a, lower, upper)
        exchange(a, lower, pivot)
        val left = maxOf(1, pivot - lower)
        val right = maxOf(1, upper - pivot - 1)
        badSplit = !usedMedians && (left / right >= 16 || right / left >= 16)
        if (pivot >= target && pivot < targetUpper) return pivot
        if (pivot < target) lower = pivot + 1 else upper = pivot
    }
}
private fun merge(a: IntArray, first: Int, middle: Int, end: Int, startDestination: Int) {
    var i = first
    var j = middle
    var destination = startDestination
    while (i < middle && j < end) {
        if (a[i] <= a[j]) exchange(a, destination++, i++)
        else exchange(a, destination++, j++)
    }
    while (i < middle) exchange(a, destination++, i++)
    while (j < end) exchange(a, destination++, j++)
}

private fun mergeSort(a: IntArray, first: Int, end: Int, buffer: Int) {
    val length = end - first
    if (length <= 1) return
    var width = length
    while (width >= 32) width = (width + 3) / 4
    var i = first
    while (i + width <= end) {
        binaryInsertion(a, i, i + width)
        i += width
    }
    binaryInsertion(a, i, end)
    while (width < length) {
        var destination = buffer
        i = first
        while (i + 2 * width <= end) {
            merge(a, i, i + width, i + 2 * width, destination)
            i += 2 * width
            destination += 2 * width
        }
        if (i + width < end) merge(a, i, i + width, end, destination)
        else while (i < end) exchange(a, i++, destination++)
        width *= 2

        destination = first
        i = buffer
        while (i + 2 * width <= buffer + length) {
            merge(a, i, i + width, i + 2 * width, destination)
            i += 2 * width
            destination += 2 * width
        }
        if (i + width < buffer + length) merge(a, i, i + width, buffer + length, destination)
        else while (i < buffer + length) exchange(a, i++, destination++)
        width *= 2
    }
}

private fun mergeForward(a: IntArray, destinationStart: Int, first: Int, middle: Int, end: Int): Int {
    var destination = destinationStart
    var left = first
    var right = middle
    while (left < middle && right < end) {
        if (a[left] <= a[right]) exchange(a, destination++, left++)
        else exchange(a, destination++, right++)
    }
    return if (left < middle) left else right
}
fun sort(a: IntArray) {
    val n = a.size
    if (n <= 1) return
    var first = 0
    var middle = (n + 1) / 2
    val minimum = kotlin.math.sqrt(n.toDouble()).toInt()
    mergeSort(a, middle, n, first)
    while (middle - first > minimum) {
        var selected = quickSelect(a, first, middle, (first + middle + 1) / 2)
        mergeSort(a, selected, middle, first)
        val bufferLength = selected - first
        var mergeEnd = minOf(selected + bufferLength, n)
        selected = mergeForward(a, first, selected, middle, mergeEnd)
        while (selected < middle) {
            shiftBackward(a, selected, middle, mergeEnd)
            selected = mergeEnd - (middle - selected)
            first = selected - bufferLength
            middle = mergeEnd
            if (middle == n) break
            mergeEnd = minOf(mergeEnd + bufferLength, n)
            selected = mergeForward(a, first, selected, middle, mergeEnd)
        }
        middle = selected
        first = selected - bufferLength
    }
    binaryInsertion(a, first, middle)
    inPlaceMerge(a, first, middle, n)
}
fun main() {
    val a = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
    sort(a)
    println(a.joinToString(", ", "[", "]"))
}
