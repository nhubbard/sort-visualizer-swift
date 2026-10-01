data class Run(
  val base: Int,
  val length: Int,
)

fun minRunLength(value: Int): Int {
  var n = value
  var remainder = 0
  while (n >= 32) {
    remainder = remainder or (n and 1)
    n = n shr 1
  }
  return n + remainder
}

fun countRun(values: Array<Int>, start: Int): Int {
  var end = start + 1
  if (end == values.size) return 1
  val descending = values[end] < values[start]
  end++
  if (descending) {
    while (end < values.size && values[end] < values[end - 1]) end++
    var left = start
    var right = end - 1
    while (left < right) {
      val value = values[left]
      values[left] = values[right]
      values[right] = value
      left++
      right--
    }
  } else {
    while (end < values.size && values[end] >= values[end - 1]) end++
  }
  return end - start
}

fun binaryInsertion(values: Array<Int>, start: Int, end: Int, sortedEnd: Int) {
  for (index in sortedEnd until end) {
    val pivot = values[index]
    var low = start
    var high = index
    while (low < high) {
      val middle = low + (high - low) / 2
      if (values[middle] <= pivot) low = middle + 1 else high = middle
    }
    for (shift in index downTo low + 1) values[shift] = values[shift - 1]
    values[low] = pivot
  }
}

fun merge(values: Array<Int>, runs: MutableList<Run>, index: Int) {
  val first = runs[index]
  val second = runs[index + 1]
  val left = values.sliceArray(first.base until second.base)
  val right = values.sliceArray(second.base until second.base + second.length)
  var i = 0
  var j = 0
  var destination = first.base
  while (i < left.size && j < right.size) {
    if (left[i] <= right[j]) values[destination++] = left[i++]
    else values[destination++] = right[j++]
  }
  while (i < left.size) values[destination++] = left[i++]
  while (j < right.size) values[destination++] = right[j++]
  runs[index] = Run(first.base, first.length + second.length)
  runs.removeAt(index + 1)
}

fun sort(values: Array<Int>) {
  val n = values.size
  if (n < 2) return
  val minimum = minRunLength(n)
  val runs = mutableListOf<Run>()
  var cursor = 0
  while (cursor < n) {
    var length = countRun(values, cursor)
    val forced = minOf(minimum, n - cursor)
    if (length < forced) {
      binaryInsertion(values, cursor, cursor + forced, cursor + length)
      length = forced
    }
    runs.add(Run(cursor, length))
    while (runs.size > 1) {
      var index = runs.size - 2
      if ((index >= 1 && runs[index - 1].length <= runs[index].length + runs[index + 1].length) ||
        (index >= 2 && runs[index - 2].length <= runs[index].length + runs[index - 1].length)
      ) {
        if (runs[index - 1].length < runs[index + 1].length) index--
      } else if (runs[index].length > runs[index + 1].length) break
      merge(values, runs, index)
    }
    cursor += length
  }
  while (runs.size > 1) {
    var index = runs.size - 2
    if (index > 0 && runs[index - 1].length < runs[index + 1].length) index--
    merge(values, runs, index)
  }
}

fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[${array.joinToString(", ")}]")
}
