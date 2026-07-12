fun sort(arr: Array<Int>) {
  for (i in 1 until arr.size) {
    var pos = i
    while (pos > 0 && arr[pos - 1] > arr[pos]) {
      arr[pos - 1] = arr[pos].also { arr[pos] = arr[pos - 1] }
      pos--
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
