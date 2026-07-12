fun sort(arr: Array<Int>) {
  val n = arr.size
  for (start in 1 until n) {
    var i = start
    var k = start - 1
    while (k >= 0) {
      if (arr[i] < arr[k]) {
        arr[i] = arr[k].also { arr[k] = arr[i] }
      }
      k--
      i--
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}