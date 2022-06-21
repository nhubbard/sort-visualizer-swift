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
  // Specific to bitonic sort: size must be power of 2.
  var items = arrayOf<Int>(35, 74, 71, 72, 30, 53, 9, 0)
  sort(items)
  println("[%s]".format(items.joinToString(", ")))
}
