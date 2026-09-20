fun sort(arr: Array<Int>) {
  val n = arr.size
  for (i in 1 until n) {
    var j = i
    while (j > 0 && arr[j - 1] > arr[j]) {
      val temp = arr[j]
      arr[j] = arr[j - 1]
      arr[j - 1] = temp
      j--
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