import kotlin.math.ln

fun compSwap(arr: Array<Int>, a: Int, b: Int) {
  if (arr[a] > arr[b]) {
    val tmp = arr[a]
    arr[a] = arr[b]
    arr[b] = tmp
  }
}

fun split(arr: Array<Int>, aIn: Int, m: Int, bIn: Int) {
  var a = aIn
  var b = bIn
  if (b - a < 2) return
  var c = 0
  val len1 = (b - a) / 2
  val odd = (b - a) % 2 == 1
  if (odd) {
    if (m - a > b - m) {
      c = a
      a++
    } else {
      b--
      c = b
    }
  }
  for (s in 0 until len1) {
    var i = a
    for (j in s until len1) {
      compSwap(arr, i, m + j)
      i++
    }
    for (j in 0 until s) {
      compSwap(arr, i, m + j)
      i++
    }
  }
  if (odd) {
    if (c < m) {
      for (j in 0 until len1) compSwap(arr, c, m + j)
    } else {
      for (j in 0 until len1) compSwap(arr, a + j, c)
    }
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var d = 2
  val end = 1 shl (ln((n - 1).toDouble()) / ln(2.0) + 1).toInt()
  while (d <= end) {
    var i = 0
    var dec = 0
    while (i < n) {
      var j = i
      dec += n
      while (dec >= d) {
        dec -= d
        j++
      }
      var k = j
      dec += n
      while (dec >= d) {
        dec -= d
        k++
      }
      split(arr, i, j, k)
      i = k
    }
    d *= 2
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
