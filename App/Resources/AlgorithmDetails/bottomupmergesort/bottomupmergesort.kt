fun merge(arr: Array<Int>, scratch: Array<Int>, n: Int, index: Int, mergeSize: Int): Int {
  val mid = index + mergeSize / 2
  val end = minOf(n, index + mergeSize)
  if (mid >= end) return index
  var left = index
  var right = mid
  var out = index
  while (left < mid && right < end) {
    if (arr[left] <= arr[right]) scratch[out] = arr[left++] else scratch[out] = arr[right++]
    out++
  }
  while (left < mid) scratch[out++] = arr[left++]
  while (right < end) scratch[out++] = arr[right++]
  return -1
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) return
  val scratch = arr.copyOf()
  var mergeSize = 2
  while (mergeSize <= n) {
    var copyLength = n
    var index = 0
    while (index < n) {
      val stop = merge(arr, scratch, n, index, mergeSize)
      if (stop >= 0) copyLength = stop
      index += mergeSize
    }
    for (j in 0 until copyLength) arr[j] = scratch[j]
    mergeSize *= 2
  }
  if (mergeSize / 2 != n) {
    val stop = merge(arr, scratch, n, 0, mergeSize)
    val copyLength = if (stop < 0) n else stop
    for (j in 0 until copyLength) arr[j] = scratch[j]
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
