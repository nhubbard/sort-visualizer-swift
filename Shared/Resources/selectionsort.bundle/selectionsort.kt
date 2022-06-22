fun sort(arr: Array<Int>) {
  val n = arr.size
  for (i in 0..(n - 2)) {
    var minIdx = i
    for (j in (i + 1)..(n - 1)) {
      if (arr[j] < arr[minIdx]) {
        minIdx = j
      }
    }
    arr[minIdx] = arr[i].also { arr[i] = arr[minIdx] }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}