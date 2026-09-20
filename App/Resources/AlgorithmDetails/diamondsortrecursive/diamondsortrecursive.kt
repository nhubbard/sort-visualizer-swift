// [start, stop) is the half-open range being sorted. merge selects whether
// the two halves are recursively pre-sorted before the fixed diamond
// comparison pattern below merges them together.
fun sort(arr: Array<Int>, start: Int, stop: Int, merge: Boolean) {
  if (stop - start == 2) {
    if (stop <= arr.size && arr[start] > arr[stop - 1]) {
      arr[start] = arr[stop - 1].also { arr[stop - 1] = arr[start] }
    }
  } else if (stop - start >= 3) {
    val div = (stop - start) / 4.0
    val mid = (stop - start) / 2 + start
    val quarter = div.toInt() + start
    val threeQuarters = (div * 3).toInt() + start

    if (merge) {
      sort(arr, start, mid, true)
      sort(arr, mid, stop, true)
    }
    sort(arr, quarter, threeQuarters, false)
    sort(arr, start, mid, false)
    sort(arr, mid, stop, false)
    sort(arr, quarter, threeQuarters, false)
  }
}

fun sortArray(arr: Array<Int>) {
  if (arr.size < 2) return
  var paddedLength = 1
  while (paddedLength < arr.size) paddedLength *= 2
  sort(arr, 0, paddedLength, true)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sortArray(array)
  println("[%s]".format(array.joinToString(", ")))
}
