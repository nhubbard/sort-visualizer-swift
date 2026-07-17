fun partition(arr: Array<Int>, low: Int, high: Int): Pair<Int, Int> {
  if (arr[low] > arr[high]) {
    arr[low] = arr[high].also { arr[high] = arr[low] }
  }
  var j = low + 1
  var g = high - 1
  var k = low + 1
  val p = arr[low]
  val q = arr[high]
  while (k <= g) {
    if (arr[k] < p) {
      arr[k] = arr[j].also { arr[j] = arr[k] }
      j++
    } else if (arr[k] >= q) {
      while (arr[g] > q && k < g) {
        g--
      }
      arr[k] = arr[g].also { arr[g] = arr[k] }
      g--
      if (arr[k] < p) {
        arr[k] = arr[j].also { arr[j] = arr[k] }
        j++
      }
    }
    k++
  }
  j--
  g++
  arr[low] = arr[j].also { arr[j] = arr[low] }
  arr[high] = arr[g].also { arr[g] = arr[high] }
  return Pair(j, g)
}

fun dualPivotQuickSort(arr: Array<Int>, low: Int, high: Int) {
  if (low < high) {
    val (j, g) = partition(arr, low, high)
    dualPivotQuickSort(arr, low, j - 1)
    dualPivotQuickSort(arr, j + 1, g - 1)
    dualPivotQuickSort(arr, g + 1, high)
  }
}

fun sort(arr: Array<Int>) {
  dualPivotQuickSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
