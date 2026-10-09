fun sortRange(arr: Array<Int>, start: Int, end: Int) {
  val length = end - start
  if (length < 2) return

  val bounds = IntArray(6) { part -> start + length * part / 5 }
  for (part in 0 until 5) {
    sortRange(arr, bounds[part], bounds[part + 1])
  }
  val positions = bounds.copyOf(5)
  val merged = IntArray(length)
  for (offset in 0 until length) {
    var best = -1
    for (part in 0 until 5) {
      if (positions[part] < bounds[part + 1] &&
        (best < 0 || arr[positions[part]] < arr[positions[best]])
      ) {
        best = part
      }
    }
    merged[offset] = arr[positions[best]++]
  }
  for (offset in 0 until length) {
    arr[start + offset] = merged[offset]
  }
}

fun sort(arr: Array<Int>) {
  sortRange(arr, 0, arr.size)
}

fun main() {
  val array = arrayOf(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
