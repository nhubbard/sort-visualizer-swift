fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    val t = arr[a + i]
    arr[a + i] = arr[b + i]
    arr[b + i] = t
  }
}

fun binarySearchMid(arr: Array<Int>, start: Int, mid: Int, end: Int): Int {
  var a = 0
  var b = minOf(mid - start, end - mid)
  var m = a + (b - a) / 2
  while (b > a) {
    if (arr[mid - m - 1] > arr[mid + m]) {
      a = m + 1
    } else {
      b = m
    }
    m = a + (b - a) / 2
  }
  return m
}

fun multiSwapMerge(arr: Array<Int>, start: Int, mid0: Int, end0: Int) {
  var mid = mid0
  var end = end0
  var m = binarySearchMid(arr, start, mid, end)
  while (m > 0) {
    multiSwap(arr, mid - m, mid, m)
    multiSwapMerge(arr, mid, mid + m, end)
    end = mid
    mid -= m
    m = binarySearchMid(arr, start, mid, end)
  }
}

fun multiSwapMergeSort(arr: Array<Int>, a: Int, b: Int) {
  val len = b - a
  var j = 1
  while (j < len) {
    var i = a
    while (i + 2 * j <= b) {
      multiSwapMerge(arr, i, i + j, i + 2 * j)
      i += 2 * j
    }
    if (i + j < b) {
      multiSwapMerge(arr, i, i + j, b)
    }
    j *= 2
  }
}

fun sort(arr: Array<Int>) {
  multiSwapMergeSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
