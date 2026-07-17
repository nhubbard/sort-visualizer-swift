fun sort(arr: Array<Int>) {
  var i = arr.size - 1
  while (i > 0) {
    var consecSorted = 1
    for (j in 0 until i) {
      if (arr[j] > arr[j + 1]) {
        arr[j] = arr[j + 1].also { arr[j + 1] = arr[j] }
        consecSorted = 1
      } else {
        consecSorted++
      }
    }
    i -= consecSorted
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
