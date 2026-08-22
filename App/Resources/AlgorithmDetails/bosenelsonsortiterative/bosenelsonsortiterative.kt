fun compSwap(arr: Array<Int>, a: Int, b: Int, end: Int) {
  if (b >= end) return
  if (arr[a] > arr[b]) {
    arr[a] = arr[b].also { arr[b] = arr[a] }
  }
}

fun rangeComp(arr: Array<Int>, a: Int, b: Int, offset: Int, end: Int) {
  val half = (b - a) / 2
  val m = a + half
  val base = a + offset
  for (i in 0 until (half - offset)) {
    if ((i and offset.inv()) == i) {
      compSwap(arr, base + i, m + i, end)
    }
  }
}

fun sort(arr: Array<Int>) {
  val end = arr.size
  if (end <= 1) return
  var paddedLength = 1
  while (paddedLength < end) paddedLength = paddedLength shl 1

  var k = 2
  while (k <= paddedLength) {
    var j = 0
    while (j < k / 2) {
      var i = 0
      while (i + j < end) {
        rangeComp(arr, i, i + k, j, end)
        i += k
      }
      j++
    }
    k *= 2
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
