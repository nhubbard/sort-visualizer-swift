fun reverseRun(arr: Array<Int>, loIn: Int, hiIn: Int) {
  var lo = loIn
  var hi = hiIn
  while (lo < hi) {
    val t = arr[lo]
    arr[lo] = arr[hi]
    arr[hi] = t
    lo++
    hi--
  }
}

// Finds the maximal run starting at indexIn (every adjacent step in the same
// direction), reversing it in place if that direction was descending.
// Returns the index where the next run starts, or -1 if this was the last
// run.
fun identifyRun(arr: Array<Int>, indexIn: Int, n: Int): Int {
  if (indexIn >= n - 1) {
    return -1
  }
  val startIndex = indexIn
  var index = indexIn
  val ascending = arr[index] <= arr[index + 1]
  index++
  while (index < n - 1) {
    val stepAscending = arr[index] <= arr[index + 1]
    if (stepAscending != ascending) {
      break
    }
    index++
  }
  if (!ascending) {
    reverseRun(arr, startIndex, index)
  }
  return if (index >= n - 1) -1 else index + 1
}

// Merges arr[start..mid) with arr[mid..end) by copying the left run into a
// scratch buffer and merging forward from the low end.
fun mergeUp(arr: Array<Int>, start: Int, mid: Int, end: Int, buffer: Array<Int>) {
  for (i in 0 until mid - start) {
    buffer[i] = arr[start + i]
  }
  var bufferPointer = 0
  var left = start
  var right = mid
  while (left < right && right < end) {
    if (buffer[bufferPointer] <= arr[right]) {
      arr[left] = buffer[bufferPointer]
      bufferPointer++
    } else {
      arr[left] = arr[right]
      right++
    }
    left++
  }
  while (left < right) {
    arr[left] = buffer[bufferPointer]
    bufferPointer++
    left++
  }
}

// Merges arr[start..mid) with arr[mid..end) by copying the right run into a
// scratch buffer and merging backward from the high end.
fun mergeDown(arr: Array<Int>, start: Int, mid: Int, end: Int, buffer: Array<Int>) {
  for (i in 0 until end - mid) {
    buffer[i] = arr[mid + i]
  }
  var bufferPointer = end - mid - 1
  var left = mid - 1
  var right = end - 1
  while (right > left && left >= start) {
    if (buffer[bufferPointer] >= arr[left]) {
      arr[right] = buffer[bufferPointer]
      bufferPointer--
    } else {
      arr[right] = arr[left]
      left--
    }
    right--
  }
  while (right > left) {
    arr[right] = buffer[bufferPointer]
    bufferPointer--
    right--
  }
}

// Picks whichever of mergeUp/mergeDown needs the smaller scratch copy.
fun mergeRuns(arr: Array<Int>, leftStart: Int, rightStart: Int, end: Int, buffer: Array<Int>) {
  if (end - rightStart < rightStart - leftStart) {
    mergeDown(arr, leftStart, rightStart, end, buffer)
  } else {
    mergeUp(arr, leftStart, rightStart, end, buffer)
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) {
    return
  }

  var runs = mutableListOf<Int>()
  var lastRun = 0
  while (lastRun != -1) {
    runs.add(lastRun)
    lastRun = identifyRun(arr, lastRun, n)
  }

  val buffer = Array(n) { 0 }
  var runCount = runs.size
  while (runCount > 1) {
    var i = 0
    while (i < runCount - 1) {
      val end = if (i + 2 >= runCount) n else runs[i + 2]
      mergeRuns(arr, runs[i], runs[i + 1], end, buffer)
      i += 2
    }

    val compacted = mutableListOf<Int>()
    var j = 0
    while (j < runCount) {
      compacted.add(runs[j])
      j += 2
    }
    runs = compacted
    runCount = runs.size
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
