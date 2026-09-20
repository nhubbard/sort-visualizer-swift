fun sort(arr: Array<Int>) {
  val n = arr.size
  val gaps = intArrayOf(8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1)
  for (gap in gaps) {
    if (gap >= n) continue
    for (i in gap until n) {
      var j = i
      while (j >= gap && arr[j] < arr[j - gap]) {
        val temp = arr[j]
        arr[j] = arr[j - gap]
        arr[j - gap] = temp
        j -= gap
      }
    }
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
