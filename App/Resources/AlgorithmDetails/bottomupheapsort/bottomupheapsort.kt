fun sort(arr: Array<Int>) {
  val n = arr.size

  fun siftDown(i: Int, b: Int) {
    var j = i
    while (2 * j + 1 < b) {
      j = if (2 * j + 2 < b) {
        if (arr[2 * j + 2] > arr[2 * j + 1]) 2 * j + 2 else 2 * j + 1
      } else {
        2 * j + 1
      }
    }
    while (arr[i] > arr[j]) {
      j = (j - 1) / 2
    }
    while (j > i) {
      arr[i] = arr[j].also { arr[j] = arr[i] }
      j = (j - 1) / 2
    }
  }

  for (i in (n - 1) / 2 downTo 0) {
    siftDown(i, n)
  }

  for (i in (n - 1) downTo 1) {
    arr[0] = arr[i].also { arr[i] = arr[0] }
    siftDown(0, i)
  }
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
