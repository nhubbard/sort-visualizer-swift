fun mostSignificantBit(value: Int): Int {
  if (value == 0) return -1
  var bit = 0
  while ((value shr (bit + 1)) != 0) bit++
  return bit
}

fun partition(arr: Array<Int>, p: Int, r: Int, bit: Int): Int {
  var i = p - 1
  var j = r + 1
  while (true) {
    do {
      i++
    } while (i <= r && ((arr[i] shr bit) and 1) == 0)
    do {
      j--
    } while (j >= p && ((arr[j] shr bit) and 1) == 1)
    if (i < j) {
      val temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
    } else {
      return j
    }
  }
}

fun binaryQuickSortRecursive(arr: Array<Int>, p: Int, r: Int, bit: Int) {
  if (p < r && bit >= 0) {
    val q = partition(arr, p, r, bit)
    binaryQuickSortRecursive(arr, p, q, bit - 1)
    binaryQuickSortRecursive(arr, q + 1, r, bit - 1)
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var maxValue = arr[0]
  for (i in 1 until n) {
    if (arr[i] > maxValue) maxValue = arr[i]
  }
  val bit = mostSignificantBit(maxValue)
  binaryQuickSortRecursive(arr, 0, n - 1, bit)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
