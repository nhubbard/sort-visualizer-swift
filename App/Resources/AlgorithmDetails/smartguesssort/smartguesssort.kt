fun sort(arr: Array<Int>) {
  val n = arr.size
  val loops = IntArray(n)

  fun pairOk(i: Int): Boolean {
    val a = arr[loops[i]]
    val b = arr[loops[i + 1]]
    if (a < b) {
      return true
    }
    if (a == b && loops[i] < loops[i + 1]) {
      return true
    }
    return false
  }

  fun firstFailure(): Int {
    var i = n - 2
    while (i >= 0 && pairOk(i)) {
      i -= 1
    }
    return i
  }

  while (true) {
    val i = firstFailure()
    if (i < 0) {
      break
    }
    for (pos in 0 until n) {
      if (pos >= i && loops[pos] < n - 1) {
        loops[pos] += 1
        break
      } else {
        loops[pos] = 0
      }
    }
  }

  val mapped = IntArray(n)
  for (i in 0 until n) {
    mapped[i] = arr[loops[i]]
  }
  for (i in 0 until n) {
    arr[i] = mapped[i]
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
