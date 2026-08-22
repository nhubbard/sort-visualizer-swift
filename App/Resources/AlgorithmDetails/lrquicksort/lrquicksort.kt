fun quickSort(arr: Array<Int>, p: Int, r: Int) {
  if (p >= r) {
    return
  }

  val pivot = arr[p + (r - p + 1) / 2]
  var i = p
  var j = r

  while (i <= j) {
    while (arr[i] < pivot) {
      i++
    }
    while (arr[j] > pivot) {
      j--
    }
    if (i <= j) {
      arr[i] = arr[j].also { arr[j] = arr[i] }
      i++
      j--
    }
  }

  if (p < j) {
    quickSort(arr, p, j)
  }
  if (i < r) {
    quickSort(arr, i, r)
  }
}

fun sort(arr: Array<Int>) {
  quickSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
