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
  var items = arrayOf<Int>(35, 95, 74, 71, 72, 30, 96, 53, 9, 0)
  sort(items)
  println("[%s]".format(items.joinToString(", ")))
}
