fun circleSortRoutine(arr: Array<Int>, length: Int, end: Int): Int {
  var swapCount = 0
  var gap = length / 2
  while (gap > 0) {
    var start = 0
    while (start + gap < end) {
      var low = start
      var high = start + 2 * gap - 1
      while (low < high) {
        if (high < end && arr[low] > arr[high]) {
          arr[low] = arr[high].also { arr[high] = arr[low] }
          swapCount++
        }
        low++
        high--
      }
      start += 2 * gap
    }
    gap /= 2
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
    if (circleSortRoutine(arr, n, end) == 0) {
      return
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
