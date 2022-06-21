fun gnomeSort(arr: Array<Int>) {
  val n = arr.size
  var index = 0
  while (index < n) {
    if (index == 0) {
      index++
    }
    if (arr[index] >= arr[index - 1]) {
      index++
    } else {
      arr[index] = arr[index - 1].also { arr[index - 1] = arr[index] }
      index--
    }
  }
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  gnomeSort(items)
  println("[%s]".format(items.joinToString(", ")))
}
