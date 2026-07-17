fun slowSort(arr: Array<Int>, i: Int, j: Int) {
  if (i >= j) {
    return
  }
  val m = i + (j - i) / 2
  slowSort(arr, i, m)
  slowSort(arr, m + 1, j)
  if (arr[m] > arr[j]) {
    arr[m] = arr[j].also { arr[j] = arr[m] }
  }
  slowSort(arr, i, j - 1)
}

fun sort(arr: Array<Int>) {
  slowSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
