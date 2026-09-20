fun sort(a: Array<Int>) {
  val n = a.size
  if (n < 2) return
  var ordered = true
  for (i in 1 until n) if (a[i] < a[i - 1]) {
    ordered = false
    break
  }
  if (ordered) return

  fun reverse(lowStart: Int, highStart: Int) {
    var low = lowStart
    var high = highStart
    while (low < high) {
      val held = a[low]
      a[low] = a[high]
      a[high] = held
      low++
      high--
    }
  }
  while (true) {
    var pivot = n - 2
    while (pivot >= 0 && a[pivot] >= a[pivot + 1]) pivot--
    if (pivot < 0) break
    var successor = n - 1
    while (a[successor] <= a[pivot]) successor--
    val held = a[pivot]
    a[pivot] = a[successor]
    a[successor] = held
    reverse(pivot + 1, n - 1)
  }
  reverse(0, n - 1)
}

fun main() {
  val array = arrayOf(0, 39, 21, 62, 91, 77, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
