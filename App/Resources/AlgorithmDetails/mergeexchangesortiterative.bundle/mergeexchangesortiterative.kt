fun mergeExchangeSort(arr: Array<Int>) {
  val n = arr.size
  if (n <= 1) return
  val t = (Math.log((n - 1).toDouble()) / Math.log(2.0)).toInt() + 1
  val p0 = 1 shl (t - 1)
  var p = p0
  while (p > 0) {
    var q = p0
    var r = 0
    var d = p
    while (true) {
      for (i in 0 until n - d) {
        if ((i and p) == r && arr[i] > arr[i + d]) {
          arr[i] = arr[i + d].also { arr[i + d] = arr[i] }
        }
      }
      if (q == p) break
      d = q - p
      q = q shr 1
      r = p
    }
    p = p shr 1
  }
}

fun sort(arr: Array<Int>) {
  mergeExchangeSort(arr)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
