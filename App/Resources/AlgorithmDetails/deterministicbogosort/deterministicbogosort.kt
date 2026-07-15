fun sort(arr: Array<Int>) {
  val n = arr.size

  fun isSorted(): Boolean {
    for (i in 0 until n - 1) {
      if (arr[i] > arr[i + 1]) {
        return false
      }
    }
    return true
  }

  fun permutationSort(depth: Int): Boolean {
    if (depth >= n - 1) {
      return isSorted()
    }
    for (i in n - 1 downTo depth + 1) {
      if (permutationSort(depth + 1)) {
        return true
      }
      if ((n - depth) % 2 == 0) {
        arr[depth] = arr[i].also { arr[i] = arr[depth] }
      } else {
        arr[depth] = arr[n - 1].also { arr[n - 1] = arr[depth] }
      }
    }
    return permutationSort(depth + 1)
  }

  permutationSort(0)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
