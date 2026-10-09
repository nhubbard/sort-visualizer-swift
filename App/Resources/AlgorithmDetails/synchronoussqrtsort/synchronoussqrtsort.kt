private var blockSize = 1

fun sort(arr: Array<Int>) {
  blockSize = 1
  while (blockSize * blockSize < arr.size) blockSize *= 2
  synchronousSort(arr, 0, arr.size)
}

fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    val t = arr[a + i]
    arr[a + i] = arr[b + i]
    arr[b + i] = t
  }
}

fun rotate(arr: Array<Int>, a0: Int, m0: Int, b0: Int) {
  var a = a0
  var m = m0
  var b = b0
  var l = m - a
  var r = b - m
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(arr, m - r, m, r)
      b -= r
      m -= r
      l -= r
    } else {
      multiSwap(arr, a, m, l)
      a += l
      m += l
      r -= l
    }
  }
}

fun binarySearch(arr: Array<Int>, a0: Int, b0: Int, value: Int, left: Boolean): Int {
  var a = a0
  var b = b0
  while (a < b) {
    val mid = a + (b - a) / 2
    val comp = if (left) value <= arr[mid] else value < arr[mid]
    if (comp) {
      b = mid
    } else {
      a = mid + 1
    }
  }
  return a
}

fun synchronousMerge(arr: Array<Int>, a: Int, m: Int, b: Int) {
  if (m - a <= blockSize && b - m <= blockSize) {
    val temp = arr.sliceArray(a until b)
    var i = 0
    var j = m - a
    for (k in a until b) {
      if (i < m - a && (j == b - a || temp[i] <= temp[j])) arr[k] = temp[i++]
      else arr[k] = temp[j++]
    }
    return
  }
  val m1: Int
  val m3: Int
  var m2: Int
  if (m - a >= b - m) {
    m1 = a + (m - a) / 2
    val value = arr[m1]
    m2 = binarySearch(arr, m, b, value, true)
    m3 = m1 + (m2 - m)
  } else {
    m2 = m + (b - m) / 2
    val value = arr[m2]
    m1 = binarySearch(arr, a, m, value, false)
    m3 = m2 - (m - m1)
    m2 += 1
  }
  rotate(arr, m1, m, m2)
  if (m2 - (m3 + 1) > 0 && b - m2 > 0) {
    synchronousMerge(arr, m3 + 1, m2, b)
  }
  if (m1 - a > 0 && m3 - m1 > 0) {
    synchronousMerge(arr, a, m1, m3)
  }
}

fun synchronousSort(arr: Array<Int>, a: Int, b: Int) {
  val len = b - a
  var start = a
  while (start < b) {
    val end = minOf(start + 16, b)
    for (i in start + 1 until end) {
      val value = arr[i]
      var cursor = i
      while (cursor > start && arr[cursor - 1] > value) {
        arr[cursor] = arr[cursor - 1]
        cursor--
      }
      arr[cursor] = value
    }
    start += 16
  }
  var j = 16
  while (j < len) {
    var i = a
    while (i + 2 * j <= b) {
      synchronousMerge(arr, i, i + j, i + 2 * j)
      i += 2 * j
    }
    if (i + j < b) {
      synchronousMerge(arr, i, i + j, b)
    }
    j *= 2
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
