fun compSwap(arr: Array<Int>, a: Int, b: Int): Boolean {
  if (arr[a] > arr[b]) {
    arr[a] = arr[b].also { arr[b] = arr[a] }
    return true
  }
  return false
}

fun stoogeSort(arr: Array<Int>, a: Int, m: Int, b: Int, merge: Boolean): Boolean {
  if (a >= m) return false
  if (b - a == 2) return compSwap(arr, a, m)

  var lChange = false
  var rChange = false

  val a2 = (a + a + b) / 3
  val b2 = (a + b + b + 2) / 3

  if (m < b2) {
    lChange = stoogeSort(arr, a, m, b2, merge)
    if (merge) {
      rChange = stoogeSort(arr, maxOf(a + b2 - m, a2), b2, b, true)
      if (rChange) {
        stoogeSort(arr, a + b2 - m, a2, 2 * a2 - a, true)
      }
    } else {
      rChange = stoogeSort(arr, a2, b2, b, false)
      if (rChange) {
        stoogeSort(arr, a, a2, 2 * a2 - a, true)
      }
    }
  } else {
    rChange = stoogeSort(arr, a2, m, b, merge)
    if (rChange) {
      stoogeSort(arr, a, a2, a2 + b - m, true)
    }
  }

  return lChange || rChange
}

fun sort(arr: Array<Int>) {
  stoogeSort(arr, 0, 1, arr.size, false)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
