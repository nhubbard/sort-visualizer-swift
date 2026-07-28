fun quadStooge(arr: Array<Int>, pos: Int, length: Int) {
  if (length >= 2 && arr[pos] > arr[pos + length - 1]) {
    arr[pos] = arr[pos + length - 1].also { arr[pos + length - 1] = arr[pos] }
  }
  if (length <= 2) {
    return
  }

  val len1 = length / 2
  val len2 = (length + 1) / 2
  val len3 = (len1 + 1) / 2 + (len2 + 1) / 2

  quadStooge(arr, pos, len1)
  quadStooge(arr, pos + len1, len2)
  quadStooge(arr, pos + len1 / 2, len3)
  quadStooge(arr, pos + len1, len2)
  quadStooge(arr, pos, len1)
  if (length > 3) {
    quadStooge(arr, pos + len1 / 2, len3)
  }
}

fun sort(arr: Array<Int>) {
  quadStooge(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
