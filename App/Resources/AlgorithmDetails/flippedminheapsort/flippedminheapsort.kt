fun sort(arr: Array<Int>) {
  val n = arr.size

  fun idx(p: Int): Int = n - p

  fun siftDown(root: Int, dist: Int) {
    var root = root
    while (root <= dist / 2) {
      var leaf = 2 * root
      if (leaf < dist && arr[idx(leaf)] > arr[idx(leaf + 1)]) {
        leaf += 1
      }
      if (arr[idx(root)] > arr[idx(leaf)]) {
        val a = idx(root)
        val b = idx(leaf)
        arr[a] = arr[b].also { arr[b] = arr[a] }
        root = leaf
      } else {
        break
      }
    }
  }

  var i = n / 2
  while (i >= 1) {
    siftDown(i, n)
    i -= 1
  }

  i = n
  while (i > 1) {
    val a = idx(1)
    val b = idx(i)
    arr[a] = arr[b].also { arr[b] = arr[a] }
    siftDown(1, i - 1)
    i -= 1
  }
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
