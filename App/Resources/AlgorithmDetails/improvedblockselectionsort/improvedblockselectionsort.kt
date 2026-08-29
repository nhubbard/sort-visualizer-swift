fun blockRoot(n: Int): Int {
  var i = 1
  while (i * i < n) {
    i *= 2
  }
  return i
}

fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    val temp = arr[a + i]
    arr[a + i] = arr[b + i]
    arr[b + i] = temp
  }
}

fun rotate(arr: Array<Int>, a: Int, m: Int, b: Int) {
  var a = a
  var m = m
  var b = b
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

fun selectRange(arr: Array<Int>, start: Int, end: Int, bLen: Int): Int {
  var minIndex = start
  var a = start + bLen
  while (a < end) {
    if (arr[a] < arr[minIndex]) {
      minIndex = a
    } else if (arr[a] == arr[minIndex] && arr[a + bLen - 1] < arr[minIndex + bLen - 1]) {
      minIndex = a
    }
    a += bLen
  }
  return minIndex
}

fun blockSelect(arr: Array<Int>, a: Int, m: Int, b: Int, bLen: Int) {
  var k = a
  var j = m
  while (k < m && arr[k] <= arr[m]) {
    k += bLen
  }
  if (k == m) return

  var i = m
  multiSwap(arr, k, j, bLen)
  k += bLen
  j += bLen

  while (k < j && j < b) {
    if (arr[i] <= arr[j]) {
      if (k != i) multiSwap(arr, k, i, bLen)
      k += bLen
      i = selectRange(arr, maxOf(m, k), j, bLen)
    } else {
      if (i == k) i = j
      if (k != j) multiSwap(arr, k, j, bLen)
      k += bLen
      j += bLen
    }
  }

  while (k < j) {
    i = selectRange(arr, k, b, bLen)
    if (k != i) multiSwap(arr, k, i, bLen)
    k += bLen
  }
}

fun inPlaceMerge(arr: Array<Int>, a: Int, m: Int, b: Int): Int {
  var i = a
  var j = m
  while (i < j && j < b) {
    if (arr[i] > arr[j]) {
      var k = j + 1
      while (k < b && arr[i] > arr[k]) {
        k++
      }
      rotate(arr, i, j, k)
      i += k - j
      j = k
    } else {
      i++
    }
  }
  return i
}

fun inPlaceMergeBW(arr: Array<Int>, a: Int, m: Int, b: Int) {
  var i = m - 1
  var j = b - 1
  while (j > i && i >= a) {
    if (arr[i] > arr[j]) {
      var k = i - 1
      while (k >= a && arr[k] > arr[j]) {
        k--
      }
      rotate(arr, k + 1, i + 1, j + 1)
      j -= i - k
      i = k
    } else {
      j--
    }
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return
  var j = 1
  while (j < n) {
    var bLen = blockRoot(j)
    var runLength = j
    val b = n - n % bLen

    while (runLength > 16) {
      var i = 0
      while (i + j < b) {
        var k = i
        while (k + runLength < minOf(i + 2 * j, b)) {
          blockSelect(arr, k, k + runLength, minOf(k + 2 * runLength, b), bLen)
          k += runLength
        }
        i += 2 * j
      }
      runLength = bLen
      bLen = blockRoot(bLen)
    }

    var i = 0
    while (i + j < b) {
      var k = i
      var f = i
      while (k + runLength < minOf(i + 2 * j, b)) {
        f = inPlaceMerge(arr, f, k + runLength, minOf(k + 2 * runLength, b))
        k += runLength
      }
      i += 2 * j
    }

    inPlaceMergeBW(arr, n - n % (2 * j), b, n)
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
