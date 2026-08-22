val leonardo = intArrayOf(
  1, 1, 3, 5, 9, 15, 25, 41, 67, 109,
  177, 287, 465, 753, 1219, 1973, 3193, 5167, 8361, 13529, 21891,
)

fun trailingZeroCount(value: Int): Int {
  var mask = value and 1.inv()
  var trail = 0
  while (mask != 0 && mask and 1 == 0) {
    mask = mask shr 1
    trail += 1
  }
  return trail
}

fun sift(array: IntArray, pshiftIn: Int, headIn: Int) {
  var pshift = pshiftIn
  var head = headIn
  val nodeValue = array[head]
  while (pshift > 1) {
    val rt = head - 1
    val lf = head - 1 - leonardo[pshift - 2]
    if (nodeValue >= array[lf] && nodeValue >= array[rt]) break
    if (array[lf] >= array[rt]) {
      array[head] = array[lf]
      head = lf
      pshift -= 1
    } else {
      array[head] = array[rt]
      head = rt
      pshift -= 2
    }
  }
  array[head] = nodeValue
}

fun trinkle(array: IntArray, pIn: Int, pshiftIn: Int, headIn: Int, isTrustyIn: Boolean) {
  var p = pIn
  var pshift = pshiftIn
  var head = headIn
  var isTrusty = isTrustyIn
  val nodeValue = array[head]
  while (p != 1) {
    val stepson = head - leonardo[pshift]
    if (array[stepson] <= nodeValue) break
    if (!isTrusty && pshift > 1) {
      val rt = head - 1
      val lf = head - 1 - leonardo[pshift - 2]
      if (array[rt] >= array[stepson] || array[lf] >= array[stepson]) break
    }
    array[head] = array[stepson]
    head = stepson
    val trail = trailingZeroCount(p)
    p = p shr trail
    pshift += trail
    isTrusty = false
  }
  if (!isTrusty) {
    array[head] = nodeValue
    sift(array, pshift, head)
  }
}

fun sort(arr: IntArray) {
  val n = arr.size
  if (n <= 1) return

  var head = 0
  var p = 1
  var pshift = 1
  val hi = n - 1

  while (head < hi) {
    if (p and 3 == 3) {
      sift(arr, pshift, head)
      p = p shr 2
      pshift += 2
    } else {
      if (leonardo[pshift - 1] >= hi - head) {
        trinkle(arr, p, pshift, head, false)
      } else {
        sift(arr, pshift, head)
      }
      if (pshift == 1) {
        p = p shl 1
        pshift -= 1
      } else {
        p = p shl (pshift - 1)
        pshift = 1
      }
    }
    p = p or 1
    head += 1
  }

  trinkle(arr, p, pshift, head, false)
  while (pshift != 1 || p != 1) {
    if (pshift <= 1) {
      val trail = trailingZeroCount(p)
      p = p shr trail
      pshift += trail
    } else {
      p = p shl 2
      p = p xor 7
      pshift -= 2
      trinkle(arr, p shr 1, pshift + 1, head - leonardo[pshift] - 1, true)
      trinkle(arr, p, pshift, head - 1, true)
    }
    head -= 1
  }
}

fun main() {
  var array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println(array.joinToString(", ", "[", "]"))
}
