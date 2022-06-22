fun partition(arr: Array<Int>, begin: Int, end: Int): Int {
  val pivot = arr[end]
  var i = begin - 1
  for (j in begin..(end - 1)) {
    if (arr[j] <= pivot) {
      i++
      arr[i] = arr[j].also { arr[j] = arr[i] }
    }
  }
  arr[i + 1] = arr[end].also { arr[end] = arr[i + 1] }
  return i + 1
}

fun quickSort(arr: Array<Int>, begin: Int, end: Int) {
  if (begin < end) {
    val partitionIndex = partition(arr, begin, end)
    quickSort(arr, begin, partitionIndex - 1)
    quickSort(arr, partitionIndex + 1, end)
  }
}

fun sort(arr: Array<Int>) {
  quickSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}