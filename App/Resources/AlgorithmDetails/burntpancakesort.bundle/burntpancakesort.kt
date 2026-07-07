fun flip(arr: Array<Int>, end: Int) {
  var start = 0
  var e = end
  while (start < e) {
    arr[start] = arr[e].also { arr[e] = arr[start] }
    start++
    e--
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  for (i in n - 1 downTo 1) {
    var max = 0
    for (j in max + 1..i) {
      if (arr[j] > arr[max]) {
        max = j
      }
    }
    if (max != i) {
      flip(arr, max)
      flip(arr, i)
      flip(arr, i - 1)
      flip(arr, max - 1)
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}