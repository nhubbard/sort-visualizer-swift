fun compSwap(arr: Array<Int>, a: Int, b: Int, end: Int) {
  if (b < end && arr[a] > arr[b]) {
    arr[a] = arr[b].also { arr[b] = arr[a] }
  }
}

fun pairwiseMerge(arr: Array<Int>, a: Int, b: Int, end: Int) {
  val m = (a + b) / 2
  val m1 = (a + m) / 2
  val g = m - m1

  for (i in 0 until (m - m1)) {
    var j = m1
    var k = g
    while (k > 0) {
      compSwap(arr, j + i, j + i + k, end)
      k = k shr 1
      j -= (k - (i and k))
    }
  }
  if (b - a > 4) {
    pairwiseMerge(arr, m, b, end)
  }
}

fun pairwiseMergeSort(arr: Array<Int>, a: Int, b: Int, end: Int) {
  val m = (a + b) / 2
  var i = a
  var j = m
  while (i < m) {
    compSwap(arr, i, j, end)
    i++
    j++
  }
  if (b - a > 2) {
    pairwiseMergeSort(arr, a, m, end)
    pairwiseMergeSort(arr, m, b, end)
    pairwiseMerge(arr, a, b, end)
  }
}

fun sort(arr: Array<Int>) {
  val length = arr.size
  val end = length

  var n = 1
  while (n < length) n = n shl 1

  pairwiseMergeSort(arr, 0, n, end)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
