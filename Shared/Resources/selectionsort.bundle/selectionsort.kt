fun selectionSort(arr: Array<Int>) {
  val n = arr.size
  for (i in 0..(n - 2)) {
    var minIdx = i
    for (j in (i + 1)..(n - 1)) {
      if (arr[j] < arr[minIdx]) {
        minIdx = j
      }
    }
    arr[minIdx] = arr[i].also { arr[i] = arr[minIdx] }
  }
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  selectionSort(items)
  println("[%s]".format(items.joinToString(", ")))
}
