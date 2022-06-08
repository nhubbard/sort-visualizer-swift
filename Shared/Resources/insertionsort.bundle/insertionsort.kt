fun insertionSort(arr: Array<Int>) {
  val n = arr.size
  for (i in 1 until n) {
    val key = arr[i]
    var j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j]
      j = j - 1
    }
    arr[j + 1] = key
  }
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  insertionSort(items)
  println("[%s]".format(items.joinToString(", ")))
}