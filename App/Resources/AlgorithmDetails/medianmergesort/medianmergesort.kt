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

private fun partition(a: IntArray, first: Int, end: Int, pivot: Int): Int {
    var i = first - 1
    var j = end
    while (true) {
        do { i++ } while (i < j && a[i] < a[pivot])
        do { j-- } while (j >= i && a[j] > a[pivot])
        if (i >= j) return j
        exchange(a, i, j)
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

fun sort(a: IntArray) {
    var first = 0
    var end = a.size
    var badSplit = false
    var usedMedians = false
    while (end - first > 16) {
        if (badSplit) {
            medianMedians(a, first, end)
            usedMedians = true
        } else medianThree(a, first, end)
        val pivot = partition(a, first + 1, end, first)
        exchange(a, first, pivot)
        val left = pivot - first
        val right = end - pivot - 1
        badSplit = !usedMedians &&
            (left == 0 || right == 0 ||
                (left > 0 && right > 0 && (left / right >= 16 || right / left >= 16)))
        if (left <= right) {
            mergeSort(a, first, pivot, pivot + 1)
            first = pivot + 1
        } else {
            mergeSort(a, pivot + 1, end, 2 * pivot + 1 - end)
            end = pivot
        }
    }
    binaryInsertion(a, first, end)
}

fun main() {
    val a = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
        68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38)
    sort(a)
    println(a.joinToString(", ", "[", "]"))
}
