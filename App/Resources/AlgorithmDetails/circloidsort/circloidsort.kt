fun circle(arr: Array<Int>, left: Int, right: Int): Boolean {
  var a = left
  var b = right
  var swapped = false
  while (a < b) {
    if (arr[a] > arr[b]) {
      val t = arr[a]
      arr[a] = arr[b]
      arr[b] = t
      swapped = true
    }
    a++
    b--
    if (a == b) {
      b++
    }
  }
  return swapped
}

fun circlePass(arr: Array<Int>, left: Int, right: Int): Boolean {
  if (left >= right) {
    return false
  }
  val mid = (left + right) / 2
  val l = circlePass(arr, left, mid)
  val r = circlePass(arr, mid + 1, right)
  return circle(arr, left, right) || l || r
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) {
    return
  }
  while (circlePass(arr, 0, n - 1)) {
    // repeat until a full sweep makes no swaps
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
