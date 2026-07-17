fun binarySearch(arr: Array<Int>, item: Int, start: Int, end: Int): Int {
  var low = start
  var high = end
  while (low < high) {
    val mid = low + (high - low) / 2
    if (item < arr[mid]) {
      high = mid
    } else {
      low = mid + 1
    }
  }
  return low
}

fun sort(arr: Array<Int>) {
  for (i in 1 until arr.size) {
    val item = arr[i]
    val pos = binarySearch(arr, item, 0, i)
    var j = i
    while (j > pos) {
      arr[j] = arr[j - 1].also { arr[j - 1] = arr[j] }
      j--
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
