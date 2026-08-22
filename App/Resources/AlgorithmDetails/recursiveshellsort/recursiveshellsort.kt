fun gappedInsertionSort(arr: Array<Int>, a: Int, b: Int, gap: Int) {
  var i = a + gap
  while (i < b) {
    val key = arr[i]
    var j = i - gap
    while (j >= a && key < arr[j]) {
      arr[j + gap] = arr[j]
      j -= gap
    }
    arr[j + gap] = key
    i += gap
  }
}

fun recursiveShellSort(arr: Array<Int>, start: Int, end: Int, g: Int) {
  if (start + g <= end) {
    recursiveShellSort(arr, start, end, 3 * g)
    recursiveShellSort(arr, start + g, end, 3 * g)
    recursiveShellSort(arr, start + (2 * g), end, 3 * g)
    gappedInsertionSort(arr, start, end, g)
  }
}

fun sort(arr: Array<Int>) {
  recursiveShellSort(arr, 0, arr.size, 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
