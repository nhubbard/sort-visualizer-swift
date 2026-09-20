fun sort(a: Array<Int>) {
  val n = a.size
  if (n < 2) return
  var swapped = true
  while (swapped) {
    swapped = false
    for (i in 0 until n - 1) {
      if (a[i] > a[i + 1]) {
        val held = a[i]
        a[i] = a[i + 1]
        a[i + 1] = held
        swapped = true
      }
    }
  }
}

fun main() {
  val array = arrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
