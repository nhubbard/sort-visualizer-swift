fun quickSort(arr: Array<Int>, p: Int, r: Int) {
  var left = p
  var right = r
  while (left < right) {
    val pivot = arr[left + (right - left + 1) / 2]
    var i = left
    var j = right
    while (i <= j) {
      while (arr[i] < pivot) i++
      while (arr[j] > pivot) j--
      if (i <= j) {
        arr[i] = arr[j].also { arr[j] = arr[i] }
        i++
        j--
      }
    }
    if (j - left < right - i) {
      if (left < j) quickSort(arr, left, j)
      left = i
    } else {
      if (i < right) quickSort(arr, i, right)
      right = j
    }
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
