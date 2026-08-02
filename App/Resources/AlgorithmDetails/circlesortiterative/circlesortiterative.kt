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

fun sort(arr: Array<Int>) {
  val end = arr.size
  if (end <= 1) return
  var n = 1
  while (n < end) {
    n = n shl 1
  }

  var numberOfSwaps = 1
  while (numberOfSwaps != 0) {
    numberOfSwaps = circleSortRoutine(arr, n, end)
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
