fun sort(arr: Array<Int>) {
  quickSort(arr, 0, arr.size - 1)
}

fun partition(arr: Array<Int>, begin: Int, end: Int): Int {
  var i = begin
  var j = end
  while (i < j) {
    while (i < j && arr[i] <= arr[begin]) i++
    while (arr[j] > arr[begin]) j--
    if (i < j) arr[i] = arr[j].also { arr[j] = arr[i] }
  }
  arr[begin] = arr[j].also { arr[j] = arr[begin] }
  return j
}

fun quickSort(arr: Array<Int>, begin: Int, end: Int) {
  if (begin < end) {
    val partitionIndex = partition(arr, begin, end)
    quickSort(arr, begin, partitionIndex - 1)
    quickSort(arr, partitionIndex + 1, end)
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
