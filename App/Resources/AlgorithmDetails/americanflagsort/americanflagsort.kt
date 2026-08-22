fun digitAt(value: Int, divisor: Int, radix: Int): Int = (value / divisor) % radix

fun flagSort(arr: Array<Int>, low: Int, high: Int, divisor: Int, radix: Int) {
  if (high - low <= 1) {
    return
  }

  val count = IntArray(radix)
  val offset = IntArray(radix)

  for (i in low until high) {
    count[digitAt(arr[i], divisor, radix)]++
  }

  offset[0] = low
  for (d in 1 until radix) {
    offset[d] = offset[d - 1] + count[d - 1]
  }
  val bucketStart = offset.copyOf()

  for (d in 0 until radix) {
    while (count[d] > 0) {
      val origin = offset[d]
      var from = origin
      var value = arr[from]

      do {
        val digit = digitAt(value, divisor, radix)
        val dest = offset[digit]++
        count[digit]--
        val displaced = arr[dest]
        arr[dest] = value
        value = displaced
        from = dest
      } while (from != origin)
    }
  }

  if (divisor > 1) {
    for (d in 0 until radix) {
      val begin = bucketStart[d]
      val end = offset[d]
      if (end - begin > 1) {
        flagSort(arr, begin, end, divisor / radix, radix)
      }
    }
  }
}

fun sort(arr: Array<Int>) {
  if (arr.size <= 1) {
    return
  }

  val radix = 10
  var maxValue = arr[0]
  for (value in arr) {
    if (value > maxValue) {
      maxValue = value
    }
  }

  var divisor = 1
  while (maxValue / divisor >= radix) {
    divisor *= radix
  }

  flagSort(arr, 0, arr.size, divisor, radix)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}