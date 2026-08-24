fun circleSortRoutine(arr: Array<Int>, lo: Int, hi: Int, end: Int): Int {
  if (lo == hi) return 0
  val low = lo
  val high = hi
  val mid = (hi - lo) / 2
  var swapCount = 0
  var lowCursor = lo
  var highCursor = hi
  while (lowCursor < highCursor) {
    if (highCursor < end && arr[lowCursor] > arr[highCursor]) {
      arr[lowCursor] = arr[highCursor].also { arr[highCursor] = arr[lowCursor] }
      swapCount++
    }
    lowCursor++
    highCursor--
  }
  swapCount += circleSortRoutine(arr, low, low + mid, end)
  if (low + mid + 1 < end) {
    swapCount += circleSortRoutine(arr, low + mid + 1, high, end)
  }
  return swapCount
}

fun binaryInsertionSort(arr: Array<Int>, end: Int) {
  for (i in 1 until end) {
    val value = arr[i]
    var lo = 0
    var hi = i
    while (lo < hi) {
      val mid = lo + (hi - lo) / 2
      if (value < arr[mid]) {
        hi = mid
      } else {
        lo = mid + 1
      }
    }
    var j = i
    while (j > lo) {
      arr[j] = arr[j - 1]
      j--
    }
    arr[lo] = value
  }
}

fun sort(arr: Array<Int>) {
  val end = arr.size
  if (end <= 1) return
  var n = 1
  var threshold = 0
  while (n < end) {
    n = n shl 1
    threshold++
  }
  threshold /= 2

  var iterations = 0
  while (true) {
    iterations++
    if (iterations >= threshold) {
      binaryInsertionSort(arr, end)
      return
    }
    if (circleSortRoutine(arr, 0, n - 1, end) == 0) {
      return
    }
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
