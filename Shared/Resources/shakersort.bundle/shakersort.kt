fun shakerSort(arr: Array<Int>) {
  val n = arr.size
  var swapped = true
  var start = 0
  var end = n - 1
  while (swapped) {
    swapped = false
    for (i in start until end) {
      if (arr[i] > arr[i + 1]) {
        val temp = arr[i]
        arr[i] = arr[i + 1]
        arr[i + 1] = temp
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
        val temp = arr[i]
        arr[i] = arr[i + 1]
        arr[i + 1] = temp
        swapped = true
      }
    }
    start++
  }
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  shakerSort(items)
  println("[%s]".format(items.joinToString(", ")))
}