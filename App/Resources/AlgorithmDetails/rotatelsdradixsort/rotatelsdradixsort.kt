const val RADIX_BASE = 10

// Extracts the digit at `place` (0 = ones place) from `value`, in RADIX_BASE.
fun digitAt(value: Int, place: Int): Int {
  var divisor = 1
  for (i in 0 until place) {
    divisor *= RADIX_BASE
  }
  return (value / divisor) % RADIX_BASE
}

// Swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
fun multiSwap(arr: Array<Int>, a: Int, b: Int, len: Int) {
  for (i in 0 until len) {
    val t = arr[a + i]
    arr[a + i] = arr[b + i]
    arr[b + i] = t
  }
}

// Rotates the adjacent blocks [a, m) and [m, b) into swapped order in place,
// using only block-swaps -- no auxiliary buffer.
fun rotateBlock(arr: Array<Int>, a: Int, m: Int, b: Int) {
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

// Finds the leftmost index in [a, b) whose digit-`place` value is >= d,
// assuming [a, b) is already sorted by that digit.
fun digitLowerBound(arr: Array<Int>, a: Int, b: Int, d: Int, place: Int): Int {
  var a = a
  var b = b
  while (a < b) {
    val mid = (a + b) / 2
    if (digitAt(arr[mid], place) >= d) {
      b = mid
    } else {
      a = mid + 1
    }
  }
  return a
}

// Merges the two adjacent digit-sorted runs [a, m) and [m, b), whose digit-`place`
// values are known to lie in [da, db), by rotating the below-threshold prefixes of
// both runs together and recursing into the two halves that produces.
fun mergeByDigit(arr: Array<Int>, a: Int, m: Int, b: Int, da: Int, db: Int, place: Int) {
  if (b - a < 2 || db - da < 2) {
    return
  }
  val dm = (da + db) / 2
  val m1 = digitLowerBound(arr, a, m, dm, place)
  val m2 = digitLowerBound(arr, m, b, dm, place)
  rotateBlock(arr, m1, m, m2)
  val newM = m1 + (m2 - m)
  mergeByDigit(arr, newM, m2, b, dm, db, place)
  mergeByDigit(arr, a, m1, newM, da, dm, place)
}

// Sorts [a, b) by digit-`place` alone via ordinary merge-sort recursion on the
// index range, merging with mergeByDigit instead of a linear merge.
fun digitMergeSort(arr: Array<Int>, a: Int, b: Int, place: Int) {
  if (b - a < 2) {
    return
  }
  val mid = (a + b) / 2
  digitMergeSort(arr, a, mid, place)
  digitMergeSort(arr, mid, b, place)
  mergeByDigit(arr, a, mid, b, 0, RADIX_BASE, place)
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n < 2) {
    return
  }
  var maxValue = arr[0]
  for (i in 1 until n) {
    if (arr[i] > maxValue) {
      maxValue = arr[i]
    }
  }
  var maxPlace = 0
  var probe = RADIX_BASE
  while (probe <= maxValue) {
    maxPlace++
    probe *= RADIX_BASE
  }
  for (place in 0..maxPlace) {
    digitMergeSort(arr, 0, n, place)
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