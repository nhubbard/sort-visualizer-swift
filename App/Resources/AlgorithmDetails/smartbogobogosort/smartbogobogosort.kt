fun sort(arr: Array<Int>, length: Int = arr.size) {
  if (length == 1) {
    return
  }
  sort(arr, length - 1)
  while (arr[length - 2] > arr[length - 1]) {
    val sub = arr.copyOfRange(0, length).toMutableList()
    sub.shuffle()
    for (i in 0 until length) arr[i] = sub[i]
    sort(arr, length - 1)
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
