fun leftBinarySearch(array: IntArray, a: Int, b: Int, `val`: Int): Int {
  var lo = a
  var hi = b
  while (lo < hi) {
    val mid = lo + (hi - lo) / 2
    if (`val` <= array[mid]) {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  return lo
}

fun rightBinarySearch(array: IntArray, a: Int, b: Int, `val`: Int): Int {
  var lo = a
  var hi = b
  while (lo < hi) {
    val mid = lo + (hi - lo) / 2
    if (`val` < array[mid]) {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  return lo
}

fun insertToLeft(array: IntArray, a: Int, b: Int, temp: Int) {
  var a = a
  while (a > b) {
    array[a] = array[a - 1]
    a--
  }
  array[b] = temp
}

fun insertToRight(array: IntArray, a: Int, b: Int, temp: Int) {
  var a = a
  while (a < b) {
    array[a] = array[a + 1]
    a++
  }
  array[a] = temp
}

fun doubleInsertion(array: IntArray, a: Int, b: Int) {
  if (b - a < 2) {
    return
  }

  val j0 = a + (b - a - 2) / 2 + 1
  val i0 = a + (b - a - 1) / 2
  var i = i0
  var j = j0

  if (j > i && array[i] > array[j]) {
    val tmp = array[i]
    array[i] = array[j]
    array[j] = tmp
  }
  i--
  j++

  while (j < b) {
    if (array[i] > array[j]) {
      val l = array[j]
      val r = array[i]
      val m = rightBinarySearch(array, i + 1, j, l)
      insertToRight(array, i, m - 1, l)
      val dest = leftBinarySearch(array, m, j, r)
      insertToLeft(array, j, dest, r)
    } else {
      val l = array[i]
      val r = array[j]
      val m = leftBinarySearch(array, i + 1, j, l)
      insertToRight(array, i, m - 1, l)
      val dest = rightBinarySearch(array, m, j, r)
      insertToLeft(array, j, dest, r)
    }
    i--
    j++
  }
}

fun sort(arr: IntArray) {
  if (arr.size > 1) {
    doubleInsertion(arr, 0, arr.size)
  }
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println(array.joinToString(prefix = "[", postfix = "]"))
}
