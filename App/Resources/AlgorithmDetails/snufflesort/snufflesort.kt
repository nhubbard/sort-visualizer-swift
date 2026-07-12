fun snuffleSort(arr: Array<Int>, start: Int, stop: Int) {
  if (stop - start + 1 >= 2) {
    if (arr[start] > arr[stop]) {
      arr[start] = arr[stop].also { arr[stop] = arr[start] }
    }
    if (stop - start + 1 >= 3) {
      val mid = (stop - start) / 2 + start
      val iterations = (stop - start + 1) / 2
      for (i in 0 until iterations) {
        snuffleSort(arr, start, mid)
        snuffleSort(arr, mid, stop)
      }
    }
  }
}

fun sort(arr: Array<Int>) {
  snuffleSort(arr, 0, arr.size - 1)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
