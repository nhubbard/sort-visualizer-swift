fun sort(arr: Array<Int>) {
  val n = arr.size

  fun maxToFront(a: Int, b: Int) {
    var best = a
    var i = a + 1
    while (i < b) {
      if (arr[i] > arr[best]) {
        best = i
      }
      i++
    }
    arr[a] = arr[best].also { arr[best] = arr[a] }
  }

  val s = Math.sqrt((n - 1).toDouble()).toInt() + 1

  var i = 0
  while (i < n) {
    maxToFront(i, minOf(i + s, n))
    i += s
  }

  var j = n
  while (j > 0) {
    var best = 0
    var k = best + s
    while (k < j) {
      if (arr[k] >= arr[best]) {
        best = k
      }
      k += s
    }
    j--
    arr[j] = arr[best].also { arr[best] = arr[j] }
    maxToFront(best, minOf(best + s, j))
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
