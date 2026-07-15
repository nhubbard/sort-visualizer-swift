fun sort(arr: Array<Int>) {
  val n = arr.size
  val idx = IntArray(n) { it }

  fun isSorted(a: Array<Int>): Boolean {
    for (i in 1 until a.size) {
      if (a[i] < a[i - 1]) {
        return false
      }
    }
    return true
  }

  fun permute(length: Int): Boolean {
    if (length < 2) {
      return isSorted(arr)
    }
    for (i in length - 2 downTo 0) {
      if (permute(length - 1)) {
        return true
      }
      val t1 = arr[idx[i]]
      arr[idx[i]] = arr[idx[length - 1]]
      arr[idx[length - 1]] = t1
      val t2 = idx[i]
      idx[i] = idx[length - 1]
      idx[length - 1] = t2
    }
    if (permute(length - 1)) {
      return true
    }
    var t = idx[length - 1]
    for (i in length - 1 downTo 1) {
      idx[i] = idx[i - 1]
    }
    idx[0] = t
    t = arr[idx[0]]
    for (i in 1 until length) {
      arr[idx[i - 1]] = arr[idx[i]]
    }
    arr[idx[length - 1]] = t
    return false
  }

  permute(n)
}

fun main() {
  var array = arrayOf<Int>(0, 39, 21, 62, 91, 14, 23)
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
