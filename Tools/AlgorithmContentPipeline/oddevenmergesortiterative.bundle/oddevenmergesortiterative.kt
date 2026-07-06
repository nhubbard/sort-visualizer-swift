fun sort(arr: Array<Int>) {
  val n = arr.size

  var p = 1
  while (p < n) {
    var k = p
    while (k > 0) {
      var j = k % p
      while (j + k < n) {
        for (i in 0 until k) {
          if ((i + j) / (p + p) == (i + j + k) / (p + p)) {
            if (i + j + k < n) {
              if (arr[i + j] > arr[i + j + k]) {
                val temp = arr[i + j]
                arr[i + j] = arr[i + j + k]
                arr[i + j + k] = temp
              }
            }
          }
        }
        j += k + k
      }
      k /= 2
    }
    p += p
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}