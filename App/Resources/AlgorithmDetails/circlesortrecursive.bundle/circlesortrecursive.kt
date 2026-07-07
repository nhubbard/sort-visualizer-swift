fun nextPowerOfTwo(n: Int): Int {
  var k = 1
  while (k < n) {
    k = k shl 1
  }
  return k
}

fun circleSortRoutine(array: Array<Int>, lo: Int, hi: Int, end: Int): Int {
  if (lo == hi) {
    return 0
  }
  val low = lo
  val high = hi
  val mid = (hi - lo) / 2
  var lo = lo
  var hi = hi
  var swaps = 0
  while (lo < hi) {
    if (hi < end && array[lo] > array[hi]) {
      array[lo] = array[hi].also { array[hi] = array[lo] }
      swaps++
    }
    lo++
    hi--
  }
  swaps += circleSortRoutine(array, low, low + mid, end)
  if (low + mid + 1 < end) {
    swaps += circleSortRoutine(array, low + mid + 1, high, end)
  }
  return swaps
}

fun sort(array: Array<Int>) {
  val end = array.size
  if (end == 0) {
    return
  }
  val paddedLength = nextPowerOfTwo(end)
  var swaps: Int
  do {
    swaps = circleSortRoutine(array, 0, paddedLength - 1, end)
  } while (swaps != 0)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
