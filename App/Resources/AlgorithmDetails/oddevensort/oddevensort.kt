fun sort(arr: Array<Int>) {
  val n = arr.size
  var sorted = false
  while (!sorted) {
    sorted = true
    for (i in 1 until (n - 1) step 2) {
      if (arr[i] > arr[i + 1]) {
        arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
        sorted = false
      }
    }
    for (i in 0 until (n - 1) step 2) {
      if (arr[i] > arr[i + 1]) {
        arr[i] = arr[i + 1].also { arr[i + 1] = arr[i] }
        sorted = false
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