var idx = 0

fun traverse(arr: IntArray, temp: IntArray, lower: IntArray, upper: IntArray, r: Int) {
  if (lower[r] != 0) {
    traverse(arr, temp, lower, upper, lower[r])
  }
  temp[idx++] = arr[r]
  if (upper[r] != 0) {
    traverse(arr, temp, lower, upper, upper[r])
  }
}

fun sort(arr: IntArray) {
  val n = arr.size
  if (n <= 1) {
    return
  }
  val lower = IntArray(n)
  val upper = IntArray(n)

  for (i in 1 until n) {
    var c = 0
    while (true) {
      val next = if (arr[i] < arr[c]) lower else upper
      if (next[c] == 0) {
        next[c] = i
        break
      } else {
        c = next[c]
      }
    }
  }

  val temp = IntArray(n)
  idx = 0
  traverse(arr, temp, lower, upper, 0)
  temp.copyInto(arr)
}

fun main() {
  val array = intArrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
