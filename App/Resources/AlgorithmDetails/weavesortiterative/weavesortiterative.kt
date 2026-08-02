fun sort(arr: Array<Int>) {
  val end = arr.size

  fun compSwap(a: Int, b: Int) {
    if (b < end && arr[a] > arr[b]) {
      val temp = arr[a]
      arr[a] = arr[b]
      arr[b] = temp
    }
  }

  var padded = 1
  while (padded < end) {
    padded *= 2
  }

  var i = 1
  while (i < padded) {
    var j = 1
    while (j <= i) {
      var k = 0
      while (k < padded) {
        val d = padded / i / 2
        var m = 0
        var l = padded / j - d
        while (l >= padded / j / 2) {
          var p = 0
          while (p < d) {
            compSwap(k + m, k + l + p)
            p++
            m++
          }
          l -= d
        }
        k += padded / j
      }
      j *= 2
    }
    i *= 2
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