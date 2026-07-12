fun sort(arr: Array<Int>) {
  val n = arr.size
  var index = 0
  while (index < n) {
    if (index == 0) {
      index++
    }
    if (arr[index] >= arr[index - 1]) {
      index++
    } else {
      arr[index] = arr[index - 1].also { arr[index - 1] = arr[index] }
      index--
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}