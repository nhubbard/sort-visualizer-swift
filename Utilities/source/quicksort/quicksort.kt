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
      val swapTemp = arr[i]
      arr[i] = arr[j]
      arr[j] = swapTemp
    }
  }
  val swapTemp = arr[i + 1]
  arr[i + 1] = arr[end]
  arr[end] = swapTemp
  return i + 1
}

fun main() {
  var items = arrayOf<Int>(1, 5, 2, 3, 7, 4, 8, 9)
  quickSort(items, 0, items.size - 1)
  println("[%s]".format(items.joinToString(", ")))
}