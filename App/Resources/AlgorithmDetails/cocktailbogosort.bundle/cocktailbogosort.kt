fun isMinimum(arr: Array<Int>, start: Int, end: Int): Boolean {
  for (k in start + 1 until end) {
    if (arr[start] > arr[k]) return false
  }
  return true
}

fun isMaximum(arr: Array<Int>, start: Int, end: Int): Boolean {
  for (k in start until end - 1) {
    if (arr[k] > arr[end - 1]) return false
  }
  return true
}

fun shuffleRange(arr: Array<Int>, start: Int, end: Int) {
  for (i in start until end - 1) {
    val j = (i until end).random()
    val t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
  }
}

fun sort(arr: Array<Int>): Array<Int> {
  var lo = 0
  var hi = arr.size
  while (lo < hi - 1) {
    if (isMinimum(arr, lo, hi)) {
      lo++
    } else if (isMaximum(arr, lo, hi)) {
      hi--
    } else {
      shuffleRange(arr, lo, hi)
    }
  }
  return arr
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23)
  array = sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
