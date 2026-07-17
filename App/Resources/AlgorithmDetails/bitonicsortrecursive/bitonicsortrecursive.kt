fun greatestPowerOfTwoLessThan(n: Int): Int {
  var k = 1
  while (k < n) {
    k = k shl 1
  }
  return k shr 1
}

fun compare(array: Array<Int>, i: Int, j: Int, dir: Boolean) {
  val isGreater = array[i] > array[j]
  if (dir == isGreater) {
    array[i] = array[j].also { array[j] = array[i] }
  }
}

fun bitonicMerge(array: Array<Int>, lo: Int, n: Int, dir: Boolean) {
  if (n > 1) {
    val m = greatestPowerOfTwoLessThan(n)
    for (i in lo until lo + n - m) {
      compare(array, i, i + m, dir)
    }
    bitonicMerge(array, lo, m, dir)
    bitonicMerge(array, lo + m, n - m, dir)
  }
}

fun bitonicSort(array: Array<Int>, lo: Int, n: Int, dir: Boolean) {
  if (n > 1) {
    val m = n / 2
    bitonicSort(array, lo, m, !dir)
    bitonicSort(array, lo + m, n - m, dir)
    bitonicMerge(array, lo, n, dir)
  }
}

fun sort(array: Array<Int>) {
  bitonicSort(array, 0, array.size, true)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
