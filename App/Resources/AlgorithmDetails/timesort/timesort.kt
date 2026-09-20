fun sort(a: Array<Int>) {
  val n = a.size
  if (n < 2) return
  val scratch = a.copyOf()
  val buffer = scratch.copyOf()

  fun mergeSort(lo: Int, hi: Int) {
    if (hi - lo < 2) return
    val mid = lo + (hi - lo) / 2
    mergeSort(lo, mid)
    mergeSort(mid, hi)
    var left = lo
    var right = mid
    var dest = lo
    while (left < mid && right < hi) {
      if (scratch[left] <= scratch[right]) buffer[dest++] = scratch[left++]
      else buffer[dest++] = scratch[right++]
    }
    while (left < mid) buffer[dest++] = scratch[left++]
    while (right < hi) buffer[dest++] = scratch[right++]
    for (i in lo until hi) scratch[i] = buffer[i]
  }
  mergeSort(0, n)
  for (i in 0 until n) a[i] = scratch[i]
  for (i in 1 until n) {
    var j = i
    while (j > 0 && a[j - 1] > a[j]) {
      val held = a[j - 1]
      a[j - 1] = a[j]
      a[j] = held
      j--
    }
  }
}

fun main() {
  val array = arrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
