fun compositeLess(arr: Array<Int>, key: Array<Int>, mid: Int, i: Int): Boolean {
  if (arr[mid] < arr[i]) return true
  if (arr[mid] == arr[i]) return key[mid] < key[i]
  return false
}

fun binarySearch(arr: Array<Int>, key: Array<Int>, n: Int, i: Int): Int {
  var start = 0
  var end = n - 1
  while (start < end) {
    val mid = (start + end) / 2
    if (compositeLess(arr, key, mid, i)) {
      start = mid + 1
    } else {
      end = mid
    }
  }
  return start
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  val key = Array(n) { it }

  for (i in 1 until n) {
    var done = false
    while (!done) {
      val pos = binarySearch(arr, key, n, i)
      if (pos == i) {
        done = true
      } else if (i < pos - 1) {
        arr[i] = arr[pos - 1].also { arr[pos - 1] = arr[i] }
        key[i] = key[pos - 1].also { key[pos - 1] = key[i] }
      } else {
        arr[i] = arr[pos].also { arr[pos] = arr[i] }
        key[i] = key[pos].also { key[pos] = key[i] }
      }
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