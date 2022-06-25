fun sort(arr: Array<Int>) {
  val n = arr.size
  var i = n / 2
  while (i > 0) {
    for (j in i until n) {
      var k = j - i
      while (k >= 0) {
        if (arr[k + i] >= arr[k]) {
          break
        } else {
          arr[k] = arr[k + i].also { arr[k + i] = arr[k] }
        }
        k -= i
      }
    }
    i /= 2
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}