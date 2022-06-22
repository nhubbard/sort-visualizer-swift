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
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}