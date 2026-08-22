fun stoogeSort(arr: Array<Int>, i: Int, j: Int) {
  if (arr[j] < arr[i]) {
    arr[i] = arr[j].also { arr[j] = arr[i] }
  }
  if (j - i > 1) {
    val t = (j - i + 1) / 3
    stoogeSort(arr, i, j - t)
    stoogeSort(arr, i + t, j)
    stoogeSort(arr, i, j - t)
  }
}

fun sort(arr: Array<Int>) {
  stoogeSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
