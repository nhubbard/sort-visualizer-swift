fun sort(arr: Array<Int>) {
  val n = arr.size - 1
  for (c in 0..(n - 1)) {
    for (d in 0..(n - c - 1)) {
      if (arr[d] > arr[d + 1]) {
        arr[d] = arr[d + 1].also { arr[d + 1] = arr[d] }
      }
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}