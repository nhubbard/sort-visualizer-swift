fun sort(arr: Array<Int>) {
  for (i in 0..(arr.size - 2)) {
    var min = i
    for (j in (i + 1) until arr.size) {
      if (arr[j] < arr[min]) {
        min = j
      }
    }
    val tmp = arr[min]
    var pos = min
    while (pos > i) {
      arr[pos] = arr[pos - 1]
      pos--
    }
    arr[pos] = tmp
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
