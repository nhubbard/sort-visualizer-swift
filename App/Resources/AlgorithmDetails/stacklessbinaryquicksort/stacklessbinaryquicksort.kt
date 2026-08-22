fun mostSignificantBit(value: Int): Int {
  if (value == 0) return -1
  var bit = 0
  while ((value shr (bit + 1)) != 0) bit++
  return bit
}

fun getBit(value: Int, bit: Int): Boolean = (value shr bit) and 1 == 1

fun partition(arr: Array<Int>, lo: Int, hi: Int, bit: Int): Int {
  var i = lo - 1
  var j = hi
  while (true) {
    i++
    while (i < j && !getBit(arr[i], bit)) i++
    j--
    while (j > i && getBit(arr[j], bit)) j--
    if (i < j) {
      val temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
    } else {
      return i
    }
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return

  var maxValue = arr[0]
  for (value in arr) {
    if (value > maxValue) maxValue = value
  }

  var q = mostSignificantBit(maxValue)
  if (q < 0) return

  var m = 0
  var i = 0
  var b = n

  while (i < n) {
    val p = if (b - i < 1) i else partition(arr, i, b, q)

    if (q == 0) {
      m += 2
      while (!getBit(m, q + 1)) q++
      i = b
      while (b < n && (arr[b] shr (q + 1)) == (m shr (q + 1))) b++
    } else {
      b = p
      q--
    }
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