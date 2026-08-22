fun sort(arr: Array<Int>) {
  val n = arr.size
  val loops = IntArray(n)
  while (true) {
    var isSorted = true
    for (i in 0 until n - 1) {
      val a = arr[loops[i]]
      val b = arr[loops[i + 1]]
      if (a < b || (a == b && loops[i] < loops[i + 1])) {
        continue
      }
      isSorted = false
      break
    }
    if (isSorted) {
      break
    }
    for (pos in 0 until n) {
      loops[pos] = (0 until n).random()
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
