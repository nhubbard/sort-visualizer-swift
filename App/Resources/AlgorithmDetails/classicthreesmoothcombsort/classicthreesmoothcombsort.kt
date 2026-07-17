fun is3Smooth(n0: Int): Boolean {
  var n = n0
  while (n % 6 == 0) {
    n /= 6
  }
  while (n % 3 == 0) {
    n /= 3
  }
  while (n % 2 == 0) {
    n /= 2
  }
  return n == 1
}

fun sort(arr: Array<Int>) {
  val length = arr.size
  for (g in length - 1 downTo 1) {
    if (is3Smooth(g)) {
      for (i in g until length) {
        if (arr[i - g] > arr[i]) {
          val t = arr[i - g]
          arr[i - g] = arr[i]
          arr[i] = t
        }
      }
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
