fun destination(arr: Array<Int>, flagged: BooleanArray, a: Int, b1: Int, b: Int): Int {
  val heldValue = arr[a]
  var d = a
  var e = 0
  for (i in (a + 1) until b) {
    if (arr[i] < heldValue) {
      d++
    } else if (i < b1 && !flagged[i] && arr[i] == heldValue) {
      e++
    }
  }
  while (flagged[d] || e > 0) {
    if (!flagged[d]) e--
    d++
  }
  return d
}

fun stableCycleSort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return
  val flagged = BooleanArray(n)
  for (i in 0 until (n - 1)) {
    if (flagged[i]) continue
    var j = i
    do {
      val k = destination(arr, flagged, i, j, n)
      arr[i] = arr[k].also { arr[k] = arr[i] }
      flagged[k] = true
      j = k
    } while (j != i)
  }
}

fun sort(arr: Array<Int>) {
  stableCycleSort(arr)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
