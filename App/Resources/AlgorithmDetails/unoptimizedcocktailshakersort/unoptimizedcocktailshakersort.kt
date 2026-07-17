fun sort(arr: Array<Int>) {
  val n = arr.size
  var i = 0
  while (i < n / 2) {
    for (j in i..(n - i - 2)) {
      if (arr[j] > arr[j + 1]) {
        arr[j] = arr[j + 1].also { arr[j + 1] = arr[j] }
      }
    }
    for (j in (n - i - 1) downTo (i + 1)) {
      if (arr[j] < arr[j - 1]) {
        arr[j] = arr[j - 1].also { arr[j - 1] = arr[j] }
      }
    }
    i++
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
