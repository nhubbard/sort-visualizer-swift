fun compSwap(arr: Array<Int>, a: Int, b: Int, end: Int) {
  if (b < end && arr[a] > arr[b]) {
    arr[a] = arr[b].also { arr[b] = arr[a] }
  }
}

fun halver(arr: Array<Int>, low: Int, high: Int, end: Int) {
  var lo = low
  var hi = high
  while (lo < hi) {
    compSwap(arr, lo, hi, end)
    lo++
    hi--
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var ceilLog = 1
  while ((1 shl ceilLog) < n) ceilLog++
  val end = n
  val size2 = 1 shl ceilLog

  var k = size2 shr 1
  while (k > 0) {
    var i = size2
    while (i >= k) {
      var j = 0
      while (j < end) {
        halver(arr, j, j + i - 1, end)
        j += i
      }
      i = i shr 1
    }
    k = k shr 1
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