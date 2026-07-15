fun sort(arr: Array<Int>) {
  val n = arr.size
  val ext = arr.copyOf()
  var minValue = ext[0]
  var maxValue = ext[0]
  for (k in 0 until n) {
    if (ext[k] < minValue) minValue = ext[k]
    if (ext[k] > maxValue) maxValue = ext[k]
  }
  maxValue += 1

  var cur = minValue
  var i = 0
  while (i < n) {
    for (j in 0 until n) {
      if (ext[j] <= cur) {
        arr[i] = ext[j]
        ext[j] = maxValue
        i += 1
      }
    }
    cur += 1
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
