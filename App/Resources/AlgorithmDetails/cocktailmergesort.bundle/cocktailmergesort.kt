fun minRunLength(length: Int): Int {
  var n = length
  var r = 0
  while (n >= 64) {
    r = r or (n and 1)
    n = n shr 1
  }
  return n + r
}

fun cocktailShakerSort(arr: Array<Int>, start: Int, end: Int) {
  val length = end - start
  if (length <= 1) {
    return
  }
  var i = 0
  while (i < length / 2) {
    var isSorted = true
    var j = i
    while (j < length - i - 1) {
      if (arr[start + j] > arr[start + j + 1]) {
        arr[start + j] = arr[start + j + 1].also { arr[start + j + 1] = arr[start + j] }
        isSorted = false
      }
      j++
    }
    j = length - i - 1
    while (j > i) {
      if (arr[start + j - 1] > arr[start + j]) {
        arr[start + j - 1] = arr[start + j].also { arr[start + j] = arr[start + j - 1] }
        isSorted = false
      }
      j--
    }
    if (isSorted) {
      break
    }
    i++
  }
}

fun merge(arr: Array<Int>, start: Int, mid: Int, end: Int) {
  val left = arr.copyOfRange(start, mid)
  val right = arr.copyOfRange(mid, end)
  var i = 0
  var j = 0
  var k = start
  while (i < left.size && j < right.size) {
    if (left[i] <= right[j]) {
      arr[k] = left[i]
      i++
    } else {
      arr[k] = right[j]
      j++
    }
    k++
  }
  while (i < left.size) {
    arr[k] = left[i]
    i++
    k++
  }
  while (j < right.size) {
    arr[k] = right[j]
    j++
    k++
  }
}

fun cocktailMergeSort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) {
    return
  }
  val minRun = minRunLength(n)
  if (n == minRun) {
    cocktailShakerSort(arr, 0, n)
    return
  }
  var i = 0
  while (i <= n - minRun) {
    cocktailShakerSort(arr, i, i + minRun)
    i += minRun
  }
  if (i < n) {
    cocktailShakerSort(arr, i, n)
  }
  var width = minRun
  while (width < n) {
    i = 0
    while (i < n) {
      val mid = minOf(i + width, n)
      val end = minOf(i + 2 * width, n)
      if (mid < end) {
        merge(arr, i, mid, end)
      }
      i += 2 * width
    }
    width *= 2
  }
}

fun sort(arr: Array<Int>) {
  cocktailMergeSort(arr)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
