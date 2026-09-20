fun sort(arr: Array<Int>) {
  recursiveShellSort(arr, 0, arr.size, 1)
}

fun gappedInsertionSort(arr: Array<Int>, a: Int, b: Int, gap: Int) {
  var i = a + gap
  while (i < b) {
    var j = i
    while (j - gap >= a && arr[j] < arr[j - gap]) {
      val temp = arr[j]
      arr[j] = arr[j - gap]
      arr[j - gap] = temp
      j -= gap
    }
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

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
