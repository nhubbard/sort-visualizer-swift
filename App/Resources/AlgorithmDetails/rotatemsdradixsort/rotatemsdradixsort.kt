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
fun msdRotateSort(array: IntArray, a: Int, b: Int, place: Int, base: Int) {
  if (b - a < 2 || place < 0) {
    return
  }
  mergeSortDigit(array, a, b, place, base)
  var start = a
  for (d in 0 until base) {
    val end = binSearchDigit(array, start, b, d + 1, place, base)
    msdRotateSort(array, start, end, place - 1, base)
    start = end
  }
}

fun sort(arr: IntArray) {
  if (arr.size <= 1) {
    return
  }
  val base = 4
  var maxValue = arr[0]
  for (value in arr) {
    if (value > maxValue) {
      maxValue = value
    }
  }
  var highestPlace = 0
  var probe = base
  while (probe <= maxValue) {
    highestPlace++
    probe *= base
  }
  msdRotateSort(arr, 0, arr.size, highestPlace, base)
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[" + array.joinToString(", ") + "]")
}
