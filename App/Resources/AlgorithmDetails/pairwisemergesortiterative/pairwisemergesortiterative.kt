fun compSwap(arr: Array<Int>, a: Int, b: Int, end: Int) {
  if (b < end && arr[a] > arr[b]) {
    arr[a] = arr[b].also { arr[b] = arr[a] }
  }
}

fun sort(arr: Array<Int>) {
  val length = arr.size
  val end = length

  var n = 1
  while (n < length) n = n shl 1

  var k = n shr 1
  while (k > 0) {
    var j = 0
    while (j < length) {
      for (i in 0 until k) {
        compSwap(arr, j + i, j + k + i, end)
      }
      j += k shl 1
    }
    k = k shr 1
  }

  k = 2
  while (k < n) {
    var m = k shr 1
    while (m > 0) {
      var j = 0
      while (j < length) {
        var p = m
        while (p < ((k - m) shl 1)) {
          for (i in 0 until m) {
            compSwap(arr, j + p + i, j + p + m + i, end)
          }
          p += m shl 1
        }
        j += k shl 1
      }
      m = m shr 1
    }
    k = k shl 1
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
