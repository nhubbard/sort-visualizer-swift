fun partition(arr: Array<Int>, lo: Int, hi: Int): Int {
  val pivot = arr[hi]
  var i = lo
  for (j in lo until hi) {
    if (arr[j] < pivot) {
      arr[i] = arr[j].also { arr[j] = arr[i] }
      i++
    }
  }
  arr[i] = arr[hi].also { arr[hi] = arr[i] }
  return i
}

fun quickSort(arr: Array<Int>, lo: Int, hi: Int) {
  if (lo < hi) {
    val p = partition(arr, lo, hi)
    quickSort(arr, lo, p - 1)
    quickSort(arr, p + 1, hi)
  }
}

fun sort(arr: Array<Int>) {
  quickSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
