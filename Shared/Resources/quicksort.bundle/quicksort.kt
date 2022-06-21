fun quickSort(arr: Array<Int>, begin: Int, end: Int) {
  if (begin < end) {
    val partitionIndex = partition(arr, begin, end)
    quickSort(arr, begin, partitionIndex - 1)
    quickSort(arr, partitionIndex + 1, end)
  }
}

fun partition(arr: Array<Int>, begin: Int, end: Int): Int {
  val pivot = arr[end]
  var i = begin - 1
  for (j in begin..(end - 1)) {
    if (arr[j] <= pivot) {
      i++
      arr[i] = arr[j].also { arr[j] = arr[i] }
    }
  }
  val swapTemp = arr[i + 1]
  arr[i + 1] = arr[end]
  arr[end] = swapTemp
  return i + 1
}

fun main() {
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  quickSort(items, 0, items.size - 1)
  println("[%s]".format(items.joinToString(", ")))
}
