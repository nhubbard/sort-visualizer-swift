fun sort(arr: Array<Int>) {
  val n = arr.size
  var loops = IntArray(n)

  fun isValid(): Boolean {
    for (i in 0 until n - 1) {
      val a = arr[loops[i]]
      val b = arr[loops[i + 1]]
      if (a < b || (a == b && loops[i] < loops[i + 1])) {
        continue
      }
      return false
    }
    return true
  }

  while (!isValid()) {
    for (pos in 0 until n) {
      if (loops[pos] < n - 1) {
        loops[pos]++
        break
      } else {
        loops[pos] = 0
      }
    }
  }

  val mapped = IntArray(n) { arr[loops[it]] }
  for (i in 0 until n) {
    arr[i] = mapped[i]
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 14)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
