fun compSwap(arr: Array<Int>, a: Int, b: Int) {
  if (arr[a] > arr[b]) {
    val t = arr[a]
    arr[a] = arr[b]
    arr[b] = t
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  var p = 1
  while (p < n) {
    p *= 2
  }

  var m = 4
  while (m <= p) {
    for (k in 0 until m / 2) {
      val cnt = if (k <= m / 4) k else m / 2 - k
      var j = 0
      while (j < n) {
        if (j + cnt + 1 < n) {
          var i = j + cnt
          while (i + 1 < minOf(n, j + m - cnt)) {
            compSwap(arr, i, i + 1)
            i += 2
          }
        }
        j += m
      }
    }
    m *= 2
  }
  m /= 2
  for (k in 0..m / 2) {
    var i = k
    while (i + 1 < minOf(n, m - k)) {
      compSwap(arr, i, i + 1)
      i += 2
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