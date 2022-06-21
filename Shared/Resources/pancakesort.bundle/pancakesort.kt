fun flip(arr: Array<Int>, k: Int) {
  var n = k
  var left = 0
  while (left < n) {
    arr[left] = arr[n].also { arr[n] = arr[left] }
    n--
    left++
  }
}

fun maxIndex(arr: Array<Int>, n: Int): Int {
  var index = 0
  for (i in 0 until n) {
    if (arr[i] > arr[index]) {
      index = i
    }
  }
  return index
}

fun sort(arr: Array<Int>) {
  var n = arr.size
  while (n > 1) {
    val max = maxIndex(arr, n)
    if (max != n) {
      flip(arr, max)
      flip(arr, n - 1)
    }
    n--
  }
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  sort(items)
  println("[%s]".format(items.joinToString(", ")))
}
