fun sort(arr: Array<Int>) {
  val end = arr.size
  var i = 0
  while (i < end - 1) {
    if (arr[i] > arr[i + 1]) {
      for (f in i until end - 1) {
        arr[f] = arr[f + 1].also { arr[f + 1] = arr[f] }
      }
      if (i > 0) i--
      continue
    }
    i++
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
