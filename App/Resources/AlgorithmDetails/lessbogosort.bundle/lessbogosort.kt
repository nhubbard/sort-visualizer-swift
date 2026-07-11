fun isMinimum(arr: Array<Int>, start: Int, end: Int): Boolean {
  for (k in start + 1 until end)
    if (arr[start] > arr[k])
      return false
  return true
}

fun shuffleRange(arr: Array<Int>, start: Int, end: Int) {
  for (i in start until end - 1) {
    val j = (i until end).random()
    val t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  for (i in 0 until n)
    while (!isMinimum(arr, i, n))
      shuffleRange(arr, i, n)
}

fun main() {
  val array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
