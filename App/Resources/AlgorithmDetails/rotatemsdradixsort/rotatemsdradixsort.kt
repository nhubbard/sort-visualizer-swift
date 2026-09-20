fun sort(arr: IntArray) {
  val n = arr.size
  if (n <= 1) return
  val base = 4
  var maxValue = 0
  for (value in arr) if (value > maxValue) maxValue = value
  var q = 0
  var probe = base
  while (probe <= maxValue) { q++; probe *= base }
  var m = 0
  var i = 0
  var b = n
  while (i < n) {
    val p = if (b - i < 1) i else dist(arr, i, b, q, base)
    if (q == 0) {
      m += base
      var t = m / base
      while (t % base == 0) { t /= base; q++ }
      i = b
      while (b < n && shift(arr[b], q + 1, base) == shift(m, q + 1, base)) b++
    } else { b = p; q-- }
  }
}

fun intPow(base: Int, exponent: Int): Int {
  var result = 1
  for (i in 0 until exponent) {
    result *= base
  }
  return result
}

fun getDigit(value: Int, place: Int, base: Int): Int = (value / intPow(base, place)) % base

fun multiSwap(array: IntArray, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    val t = array[a + i]
    array[a + i] = array[b + i]
    array[b + i] = t
  }
}

fun rotate(array: IntArray, a: Int, m: Int, b: Int) {
  var a = a
  var m = m
  var b = b
  var l = m - a
  var r = b - m
  while (l > 0 && r > 0) {
    if (r < l) {
      multiSwap(array, m - r, m, r)
      b -= r
      m -= r
      l -= r
    } else {
      multiSwap(array, a, m, l)
      a += l
      m += l
      r -= l
    }
  }
}

fun binSearchDigit(array: IntArray, a: Int, b: Int, d: Int, place: Int, base: Int): Int {
  var a = a
  var b = b
  while (a < b) {
    val mid = (a + b) / 2
    if (getDigit(array[mid], place, base) >= d) {
      b = mid
    } else {
      a = mid + 1
    }
  }
  return a
}

fun mergeDigit(array: IntArray, a: Int, m: Int, b: Int, da: Int, db: Int, place: Int, base: Int) {
  if (b - a < 2 || db - da < 2) {
    return
  }
  val dm = (da + db) / 2
  val m1 = binSearchDigit(array, a, m, dm, place, base)
  val m2 = binSearchDigit(array, m, b, dm, place, base)
  rotate(array, m1, m, m2)
  val newM = m1 + (m2 - m)
  mergeDigit(array, newM, m2, b, dm, db, place, base)
  mergeDigit(array, a, m1, newM, da, dm, place, base)
}

fun mergeSortDigit(array: IntArray, a: Int, b: Int, place: Int, base: Int) {
  if (b - a < 2) {
    return
  }
  val mid = (a + b) / 2
  mergeSortDigit(array, a, mid, place, base)
  mergeSortDigit(array, mid, b, place, base)
  mergeDigit(array, a, mid, b, 0, base, place, base)
}

// Digit-sorts [a, b) in place by `place` using rotation instead of counting
// buckets, then recurses into every resulting digit bucket one place lower --
// an ordinary MSD radix sort built entirely out of the LSD variant's
// rotate/binary-search machinery.
fun shift(value: Int, places: Int, base: Int): Int {
  var value = value
  var places = places
  while (places > 0) { value /= base; places-- }
  return value
}

fun dist(arr: IntArray, a: Int, b: Int, place: Int, base: Int): Int {
  mergeSortDigit(arr, a, b, place, base)
  return binSearchDigit(arr, a, b, 1, place, base)
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[" + array.joinToString(", ") + "]")
}
