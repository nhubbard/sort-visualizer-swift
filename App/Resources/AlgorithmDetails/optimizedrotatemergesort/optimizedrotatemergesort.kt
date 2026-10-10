private class OptimizedRotateMergeExample(private val values: Array<Int>) {
  private val buffer = Array(64) { 0 }
  private fun lowerBound(startIn: Int, endIn: Int, value: Int): Int {
    var start = startIn; var end = endIn
    while (start < end) {
      val middle = start + (end - start) / 2
      if (values[middle] < value) start = middle + 1 else end = middle
    }
    return start
  }
  private fun upperBound(startIn: Int, endIn: Int, value: Int): Int {
    var start = startIn; var end = endIn
    while (start < end) {
      val middle = start + (end - start) / 2
      if (values[middle] <= value) start = middle + 1 else end = middle
    }
    return start
  }
  private fun reverse(startIn: Int, endIn: Int) {
    var start = startIn; var end = endIn - 1
    while (start < end) {
      val value = values[start]; values[start++] = values[end]; values[end--] = value
    }
  }
  private fun rotate(start: Int, middle: Int, end: Int) {
    if (start >= middle || middle >= end) return
    val left = middle - start; val right = end - middle
    if (left <= 64) {
      for (i in 0 until left) buffer[i] = values[start + i]
      for (i in middle until end) values[i - left] = values[i]
      for (i in 0 until left) values[end - left + i] = buffer[i]
    } else if (right <= 64) {
      for (i in 0 until right) buffer[i] = values[middle + i]
      for (i in middle - 1 downTo start) values[i + right] = values[i]
      for (i in 0 until right) values[start + i] = buffer[i]
    } else {
      reverse(start, middle); reverse(middle, end); reverse(start, end)
    }
  }
  private fun bufferedMerge(start: Int, middle: Int, end: Int) {
    val leftLength = middle - start; val rightLength = end - middle
    if (leftLength <= rightLength) {
      for (i in 0 until leftLength) buffer[i] = values[start + i]
      var left = 0; var right = middle; var destination = start
      while (left < leftLength && right < end) {
        if (values[right] < buffer[left]) values[destination] = values[right++]
        else values[destination] = buffer[left++]
        destination++
      }
      while (left < leftLength) values[destination++] = buffer[left++]
    } else {
      for (i in 0 until rightLength) buffer[i] = values[middle + i]
      var left = middle - 1; var right = rightLength - 1; var destination = end - 1
      while (left >= start && right >= 0) {
        if (values[left] > buffer[right]) values[destination] = values[left--]
        else values[destination] = buffer[right--]
        destination--
      }
      while (right >= 0) values[destination--] = buffer[right--]
    }
  }
  private fun merge(start: Int, middle: Int, end: Int) {
    if (start >= middle || middle >= end || values[middle - 1] <= values[middle]) return
    val leftLength = middle - start; val rightLength = end - middle
    if (minOf(leftLength, rightLength) <= 64) { bufferedMerge(start, middle, end); return }
    val leftSplit: Int; val rightSplit: Int
    if (leftLength >= rightLength) {
      leftSplit = start + leftLength / 2
      rightSplit = lowerBound(middle, end, values[leftSplit])
    } else {
      rightSplit = middle + rightLength / 2
      leftSplit = upperBound(start, middle, values[rightSplit])
    }
    rotate(leftSplit, middle, rightSplit)
    val newMiddle = leftSplit + rightSplit - middle
    merge(start, leftSplit, newMiddle)
    merge(newMiddle, rightSplit, end)
  }
  private fun insertion(start: Int, end: Int) {
    for (index in start + 1 until end) {
      val value = values[index]
      val destination = upperBound(start, index, value)
      for (cursor in index downTo destination + 1) values[cursor] = values[cursor - 1]
      values[destination] = value
    }
  }
  fun sort() {
    val count = values.size
    if (count < 2) return
    var start = 0
    while (start < count) { insertion(start, minOf(start + 32, count)); start += 32 }
    var run = 32
    while (run < count) {
      start = 0
      while (start + run < count) {
        merge(start, start + run, minOf(start + 2 * run, count))
        start += 2 * run
      }
      run *= 2
    }
  }
}
fun sort(values: Array<Int>) { OptimizedRotateMergeExample(values).sort() }
fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[${array.joinToString(", ")}]")
}
