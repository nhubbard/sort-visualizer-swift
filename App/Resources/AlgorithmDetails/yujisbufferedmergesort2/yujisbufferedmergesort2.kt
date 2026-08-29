fun ceilLog(n: Int): Int {
  var i = 0
  while ((1 shl i) < n) i++
  return i
}

fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    arr[a + i] = arr[b + i].also { arr[b + i] = arr[a + i] }
  }
}

fun insertTo(arr: Array<Int>, aInit: Int, b: Int) {
  var a = aInit
  val temp = arr[a]
  while (a > b) {
    a--
    arr[a + 1] = arr[a]
  }
  arr[b] = temp
}

fun binarySearch(arr: Array<Int>, start: Int, end: Int, value: Int, left: Boolean): Int {
  var a = start
  var b = end
  while (a < b) {
    val m = a + (b - a) / 2
    val comp = if (left) value <= arr[m] else value < arr[m]
    if (comp) {
      b = m
    } else {
      a = m + 1
    }
  }
  return a
}

fun binaryInsertion(arr: Array<Int>, a: Int, b: Int) {
  var i = a + 1
  while (i < b) {
    val value = arr[i]
    insertTo(arr, i, binarySearch(arr, a, i, value, false))
    i++
  }
}

fun merge(arr: Array<Int>, a: Int, m: Int, b: Int, pInit: Int): Int {
  var i = a
  var j = m
  var p = pInit
  while (i < m && j < b) {
    if (arr[i] <= arr[j]) {
      arr[p] = arr[i].also { arr[i] = arr[p] }
      p++
      i++
    } else {
      arr[p] = arr[j].also { arr[j] = arr[p] }
      p++
      j++
    }
  }
  var leftover = 0
  while (i < m) {
    arr[p] = arr[i].also { arr[i] = arr[p] }
    p++
    i++
  }
  while (j < b) {
    arr[p] = arr[j].also { arr[j] = arr[p] }
    p++
    j++
    leftover++
  }
  return leftover
}

fun mergeWithBufStatic(arr: Array<Int>, a: Int, m: Int, b: Int, p: Int, useBinarySearch: Boolean) {
  var i = 0
  var j = m
  var k = a
  if (useBinarySearch) {
    while (i < m - a && j < b) {
      if (arr[j] < arr[p + i]) {
        val value = arr[p + i]
        val q = binarySearch(arr, j, b, value, true)
        while (j < q) {
          arr[k] = arr[j].also { arr[j] = arr[k] }
          k++
          j++
        }
      }
      arr[k] = arr[p + i].also { arr[p + i] = arr[k] }
      k++
      i++
    }
    while (i < m - a) {
      arr[k] = arr[p + i].also { arr[p + i] = arr[k] }
      k++
      i++
    }
  } else {
    while (i < m - a && j < b) {
      if (arr[p + i] <= arr[j]) {
        arr[k] = arr[p + i].also { arr[p + i] = arr[k] }
        k++
        i++
      } else {
        arr[k] = arr[j].also { arr[j] = arr[k] }
        k++
        j++
      }
    }
    while (i < m - a) {
      arr[k] = arr[p + i].also { arr[p + i] = arr[k] }
      k++
      i++
    }
  }
}

fun mergeSort(arr: Array<Int>, a: Int, p: Int, length: Int) {
  var j = 16
  val ceilLogValue = ceilLog(length)
  var pos = if (length > 16 && (ceilLogValue and 1) == 1) p else a

  var i = pos
  while (i + 16 <= pos + length) {
    binaryInsertion(arr, i, i + 16)
    i += 16
  }
  binaryInsertion(arr, i, pos + length)

  var nxt = pos
  while (j < length) {
    pos = nxt
    nxt = nxt xor a xor p
    var posNext = nxt

    i = pos
    while (i + 2 * j <= pos + length) {
      merge(arr, i, i + j, i + 2 * j, posNext)
      i += 2 * j
      posNext += 2 * j
    }
    if (i + j < pos + length) {
      merge(arr, i, i + j, pos + length, posNext)
    } else {
      while (i < pos + length) {
        arr[i] = arr[posNext].also { arr[posNext] = arr[i] }
        i++
        posNext++
      }
    }
    j *= 2
  }
}

fun bufferedMerge(arr: Array<Int>, a: Int, b: Int) {
  if (b - a <= 16) {
    binaryInsertion(arr, a, b)
    return
  }

  var m = (a + b + 1) / 2
  mergeSort(arr, m, 2 * m - b, b - m)

  var n = (a + m + 1) / 2
  val limit = (b - a) / 16
  while (m - a > limit) {
    mergeSort(arr, 2 * n - m, n, m - n)
    mergeWithBufStatic(arr, n, m, b, 2 * n - m, (b - m) / (m - n) >= ceilLog(n - a))
    m = n
    n = (a + m + 1) / 2
  }

  bufferedMerge(arr, a, m)
  multiSwap(arr, a, b - (m - a), m - a)
  val s = merge(arr, m, b - (m - a), b, a)
  bufferedMerge(arr, b - (m - a) - s, b)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return
  bufferedMerge(arr, 0, n)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
