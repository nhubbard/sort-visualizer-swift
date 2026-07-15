fun sort(arr: Array<Int>) {
  val n = arr.size

  fun minFrom(i: Int): Int {
    var m = arr[i]
    for (k in i + 1 until n) {
      if (arr[k] < m) {
        m = arr[k]
      }
    }
    return m
  }

  for (i in 0 until n) {
    while (arr[i] != minFrom(i)) {
      val j = (i until n).random()
      arr[i] = arr[j].also { arr[j] = arr[i] }
    }
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
