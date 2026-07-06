fun sort(arr: Array<Int>) {
  val n = arr.size
  var swapped = true
  var start = 0
  var end = n - 1
  while (swapped) {
    swapped = false
    for (i in start until end) {
      if (arr[i] > arr[i + 1]) {
        arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
        swapped = true
      }
    }
    if (!swapped) {
      break
    }
    swapped = false
    end--
    for (i in (end - 1) downTo start) {
      if (arr[i] > arr[i + 1]) {
        arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
        swapped = true
      }
    }
    start++
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}