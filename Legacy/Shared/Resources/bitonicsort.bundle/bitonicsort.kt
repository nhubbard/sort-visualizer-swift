fun sort(arr: Array<Int>) {
  val n = arr.size
  var k = 2
  while (k <= n) {
    var j = k / 2
    while (j > 0) {
      var i = 0
      while (i < n) {
        val l = i xor j
        if (l > i) {
          if (((i and k) == 0) && (arr[i] > arr[l]) ||
          (((i and k) != 0) && (arr[i] < arr[l]))) {
            arr[i] = arr[l].also { arr[l] = arr[i] }
          }
        }
        i++
      }
      j /= 2
    }
    k *= 2
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}