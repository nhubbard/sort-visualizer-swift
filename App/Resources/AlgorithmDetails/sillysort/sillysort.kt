fun sillySort(arr: Array<Int>, i: Int, j: Int) {
  if (i < j) {
    val m = i + (j - i) / 2
    sillySort(arr, i, m)
    sillySort(arr, m + 1, j)
    if (arr[i] >= arr[m + 1]) {
      arr[i] = arr[m + 1].also { arr[m + 1] = arr[i] }
    }
    sillySort(arr, i + 1, j)
  }
}

fun sort(arr: Array<Int>) {
  sillySort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
